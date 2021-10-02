CREATE LANGUAGE PLPYTHON3U;

-- Скалярная функция PL/Python.
CREATE OR REPLACE FUNCTION get_age_py(birth_date DATE, death_date DATE)
RETURNS INT 
AS $$
    from datetime import datetime
    from dateutil import parser
    from dateutil.relativedelta import relativedelta

    start_date = parser.parse(birth_date)
    end_date = datetime.now() if death_date is None else parser.parse(death_date)

    return relativedelta(end_date, start_date).years
$$ LANGUAGE PLPYTHON3U;
SELECT name, get_age_py(birth_date, death_date) FROM authors;

-- Пользовательская агрегатная функция PL/Python.
CREATE OR REPLACE FUNCTION get_avg_age_py()
RETURNS DECIMAL
AS $$
    query = "select get_age_py(birth_date, death_date) as age from authors"
    rv = plpy.execute(query)
    
    return sum(row["age"] for row in rv) / len(rv)
$$ LANGUAGE PLPYTHON3U;
SELECT get_avg_age_py();

-- Определяемая пользователем табличная функция PL/Python.
CREATE OR REPLACE FUNCTION find_comments(regexp_str VARCHAR)
RETURNS TABLE (
    id UUID,
    text TEXT,
    reader_id UUID,
    review_id UUID    
) AS $$
    import re

    regexp = re.compile(regexp_str)
    query = "select id, text, reader_id, review_id FROM comments"

    for r in plpy.cursor(query):
        if regexp.search(r["text"]):
            yield(r)

$$ LANGUAGE PLPYTHON3U;
SELECT * FROM find_comments('(?m)I.+? like ');


-- Хранимая процедура PL/Python.
CREATE OR REPLACE PROCEDURE update_rate_py(review_id UUID, new_rate INT)
AS $$
    plan = plpy.prepare(
        "UPDATE reviews SET rate = $1 WHERE id = $2;",
        ["INT", "UUID"])
    plpy.execute(plan, [new_rate, review_id])
$$ LANGUAGE PLPYTHON3U;
CALL update_rate_py('002e3a9e-59c6-498c-b772-05ba4051f763', 10);

CREATE OR REPLACE FUNCTION sanitize_review_text_py()
RETURNS TRIGGER
AS $$
    import re

    plan = plpy.prepare(
        "UPDATE reviews SET text = $1 WHERE id = $2;",
        ["TEXT", "UUID"])
    
    text = re.sub("hate", "****", TD["new"]["text"])

    plpy.execute(plan, [text, TD["new"]["id"]])
$$ LANGUAGE PLPYTHON3U;

CREATE TRIGGER sanitize_review_text_py AFTER INSERT ON reviews
FOR ROW EXECUTE PROCEDURE sanitize_review_text_py();

INSERT INTO reviews(rate, text, reader_id, book_id)
VALUES (
    0, 
    'i hate this book!!! hate, hate, hate', 
    '72a1d485-d936-41c2-bd73-331f01a8a287',
    '2ca4f7a6-a4ae-42f2-9964-a3f7bf60f4ad'
);

-- Определяемый пользователем тип данных PL/Python.
CREATE TYPE book_price AS (
    book_id UUID,
    price DECIMAL
);

CREATE OR REPLACE FUNCTION set_name_price_py(title VARCHAR, pr DECIMAL)
RETURNS SETOF book_price
AS $$
    query = f"SELECT id FROM books WHERE title LIKE '%{title}%'"
    for r in plpy.cursor(query):
        yield(r["id"], pr)
$$ LANGUAGE PLPYTHON3U;

SELECT * FROM set_name_price_py('Head', 20);

-- Защита

CREATE OR REPLACE FUNCTION select_top_books_by_pattern(regexp_str VARCHAR)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    avg_rate DECIMAL
)
AS $$
    import re
    regexp = re.compile(regexp_str)

    query = """
        SELECT b.id, b.title, b.description, AVG(r.rate) as avg_rate
        FROM books b
        JOIN reviews r ON r.book_id = b.id
        GROUP BY b.id, b.title, b.description
        ORDER BY AVG(r.rate) DESC
    """
    for r in plpy.cursor(query):
        if regexp.search(r["title"]) or regexp.search(r["description"]):
            yield(r)
$$ LANGUAGE PLPYTHON3U;

SELECT title, avg_rate FROM select_top_books_by_pattern('Head');