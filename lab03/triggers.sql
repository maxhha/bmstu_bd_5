-- Скалярная функция.
CREATE OR REPLACE FUNCTION get_age(birth_date DATE, death_date DATE)
RETURNS INT AS $$
BEGIN
    RETURN EXTRACT(year FROM age(COALESCE(death_date, NOW()), birth_date));
END;
$$ LANGUAGE PLPGSQL;
SELECT name, get_age(birth_date, death_date) FROM authors;

-- --  ---  -- -- ---- -- --
---   -- -- ----- ---  -- --
-- --  ---  -- -- ---- ------

-- Подставляемая табличная функция.
CREATE OR REPLACE FUNCTION get_authors_rates(from_published_at DATE)
RETURNS TABLE (
  id UUID,
  name TEXT,
  birth_date DATE,
  death_date DATE,
  rate INT
)
AS $$
BEGIN
  RETURN QUERY
    SELECT a.id, a.name, a.birth_date, a.death_date, AVG(rv.rate)::INT
    FROM authors a
    JOIN authors_books_rel ab ON ab.author_id = a.id
    JOIN books b ON b.id = ab.book_id
    JOIN reviews rv ON rv.book_id = b.id
    WHERE b.published_at >= from_published_at
    GROUP BY a.id, a.name, a.birth_date, a.death_date;
END;
$$ LANGUAGE PLPGSQL;
SELECT * FROM get_authors_rates('2020-01-01');

-- --  ---  -- -- ---- -- --
---   -- -- ----- ---  -- --
-- --  ---  -- -- ---- ------

-- Многооператорная табличная функция.
CREATE OR REPLACE FUNCTION get_author_ages(min_birth_date DATE)
RETURNS TABLE (
  author_id UUID,
  age INT
) AS $$
BEGIN
  CREATE TEMP TABLE authors_ages (
    author_id UUID,
    age INT
  );
  INSERT INTO authors_ages (author_id, age)
  SELECT id, get_age(birth_date, death_date)
  FROM authors
  WHERE birth_date > min_birth_date;
  RETURN QUERY SELECT * FROM authors_ages;
END
$$ LANGUAGE PLPGSQL;
SELECT * FROM get_author_ages('2000-01-01');

-- --  ---  -- -- ---- -- --
---   -- -- ----- ---  -- --
-- --  ---  -- -- ---- ------

-- Рекурсивная функция.
CREATE OR REPLACE FUNCTION get_threads_like(substr VARCHAR)
RETURNS TABLE (
  id UUID,
  text TEXT,
  reader_id UUID
) AS $$
BEGIN
  RETURN QUERY
  WITH RECURSIVE threads(id, text, reader_id) AS (
    SELECT cc.id, cc.text, cc.reader_id FROM comments cc WHERE cc.text LIKE substr
    UNION ALL
    SELECT c.id, c.text, c.reader_id FROM comments c
    JOIN threads h ON c.prev_comment_id = h.id
  )
  SELECT th.id, th.text, th.reader_id FROM threads th;
END;
$$ LANGUAGE PLPGSQL;
SELECT * FROM get_threads_like('%hate%')

-- --  ---  -- -- ---- -- --
---   -- -- ----- ---  -- --
-- --  ---  -- -- ---- ------

-- Хранимая процедура с параметрами.
CREATE OR REPLACE PROCEDURE update_rate(review_id UUID, new_rate INT)
AS $$
BEGIN
  UPDATE reviews
  SET rate = new_rate
  WHERE id = review_id;
  COMMIT;
END;
$$ LANGUAGE PLPGSQL;
CALL update_rate('002e3a9e-59c6-498c-b772-05ba4051f763', 10);

CREATE OR REPLACE PROCEDURE update_death_date(author_id UUID, new_death_date DATE)
AS $$
BEGIN
  UPDATE authors
  SET death_date = new_death_date
  WHERE id = author_id;
  COMMIT;
END;
$$ LANGUAGE PLPGSQL;
CALL update_rate('002e3a9e-59c6-498c-b772-05ba4051f763', 10);

-- --  ---  -- -- ---- -- --
---   -- -- ----- ---  -- --
-- --  ---  -- -- ---- ------

-- Хранимая процедура с курсором.
CREATE OR REPLACE PROCEDURE fetch_books_with_review_rate(target_rate INT)
AS $$
DECLARE
  reclist RECORD;
  listcur CURSOR FOR
    SELECT *
    FROM books
    WHERE EXISTS (
      SELECT r.book_id
      FROM reviews r
      WHERE r.rate = target_rate
    );
BEGIN
  OPEN listcur;
  LOOP
    FETCH listcur INTO reclist;
    RAISE NOTICE '% have %!', reclist.title, target_rate;
    EXIT WHEN NOT FOUND;  
  END LOOP;
  CLOSE listcur;
END;
$$ LANGUAGE PLPGSQL;
CALL fetch_books_with_review_rate(2);

-- --  ---  -- -- ---- -- --
---   -- -- ----- ---  -- --
-- --  ---  -- -- ---- ------

CREATE OR REPLACE PROCEDURE get_db_metadata(dbname VARCHAR)
AS $$
DECLARE
    dbid INT;
    dbconnlimit INT;
BEGIN
    SELECT pg.oid, pg.datconnlimit FROM pg_database pg WHERE pg.datname = dbname
    INTO dbid, dbconnlimit;
    RAISE NOTICE 'DB: %, ID: %, CONNECTION LIMIT: %', dbname, dbid, dbconnlimit;
END;
$$ LANGUAGE PLPGSQL;
CALL get_db_metadata('db_lab01');

-- --  ---  -- -- ---- -- --
---   -- -- ----- ---  -- --
-- --  ---  -- -- ---- ------



-- --  ---  -- -- ---- -- --
---   -- -- ----- ---  -- --
-- --  ---  -- -- ---- ------

ALTER TABLE comments
ADD COLUMN karma INT NOT NULL DEFAULT 0;

ALTER TABLE reviews
ADD COLUMN karma INT NOT NULL DEFAULT 0;

ALTER TABLE readers
ADD COLUMN karma INT NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION update_reviews_karma()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE reviews r
  SET karma = (
    SELECT COALESCE(SUM(c.karma), 0)
    FROM comments c
    WHERE c.review_id = r.id
  )
  WHERE r.id = NEW.review_id;
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS trig_reviews_karma ON comments;

CREATE TRIGGER trig_reviews_karma
AFTER INSERT OR UPDATE OR DELETE 
ON comments
FOR EACH ROW
EXECUTE PROCEDURE update_reviews_karma();

INSERT INTO comments(text, review_id, reader_id, prev_comment_id, karma)
VALUES ('-', '002e3a9e-59c6-498c-b772-05ba4051f763', '00db799c-dbf4-432b-a393-207749aed728', NULL, 10)

SELECT karma
FROM reviews 
WHERE id = '002e3a9e-59c6-498c-b772-05ba4051f763'

CREATE OR REPLACE FUNCTION update_readers_karma()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE readers r
  SET karma = (
    SELECT SUM(r.karma)
    FROM reviews rv
    WHERE rv.reader_id = r.id
  )
  WHERE r.id = NEW.reader_id;
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS trig_readers_karma ON ;

CREATE TRIGGER trig_readers_karma
AFTER INSERT OR UPDATE OR DELETE 
ON comments
FOR EACH ROW
EXECUTE PROCEDURE update_readers_karma();

INSERT INTO comments(text, review_id, reader_id, prev_comment_id, karma)
VALUES ('-', '002e3a9e-59c6-498c-b772-05ba4051f763', '00db799c-dbf4-432b-a393-207749aed728', NULL, 10)

CREATE OR REPLACE FUNCTION update_readers_karma()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE readers r
  SET karma = (
    SELECT COALESCE(SUM(rv.karma), 0)
    FROM reviews rv
    WHERE rv.reader_id = r.id
  )
  WHERE r.id = NEW.reader_id;
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS trig_readers_karma ON reviews;

CREATE TRIGGER trig_readers_karma
AFTER INSERT OR UPDATE OR DELETE 
ON reviews
FOR EACH ROW
EXECUTE PROCEDURE update_readers_karma();

INSERT INTO comments(text, review_id, reader_id, prev_comment_id, karma)
VALUES ('-', '002e3a9e-59c6-498c-b772-05ba4051f763', '00db799c-dbf4-432b-a393-207749aed728', NULL, 10)

SELECT rd.karma
FROM readers rd
WHERE id IN (
	SELECT reader_id
    FROM reviews r
    WHERE r.id = '002e3a9e-59c6-498c-b772-05ba4051f763'
)