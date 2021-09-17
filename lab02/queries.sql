-- Инструкция SELECT, использующая предикат сравнения.
SELECT text, created_at from reviews WHERE rate = 10 ORDER BY created_at LIMIT 10;

-- Инструкция SELECT, использующая предикат BETWEEN.
SELECT text, created_at FROM reviews WHERE rate BETWEEN 0 AND 3 ORDER BY created_at LIMIT 10;

-- Инструкция SELECT, использующая предикат LIKE.
SELECT name, birth_date FROM authors WHERE name LIKE 'John%' ORDER BY birth_date LIMIT 10;

-- Инструкция SELECT, использующая предикат IN с вложенным подзапросом.
SELECT title
FROM books 
WHERE id IN
	(SELECT book_id FROM reviews WHERE rate = 10)
ORDER BY published_at
LIMIT 10;

-- Инструкция SELECT, использующая предикат EXISTS с вложенным подзапросом.
SELECT title
FROM books 
WHERE EXISTS
	(SELECT book_id FROM reviews WHERE rate = 10)
ORDER BY published_at
LIMIT 10;

-- Инструкция SELECT, использующая предикат сравнения с квантором.
SELECT a.name, a.birth_date
FROM authors a
WHERE birth_date + INTERVAL '10 year' > ANY(
  SELECT b.published_at FROM authors_books_rel rel
  INNER JOIN books b ON rel.book_id = b.id
  WHERE a.id = rel.author_id
)
ORDER BY a.birth_date;

-- Инструкция SELECT, использующая агрегатные функции в выражениях столбцов.
SELECT AVG(extract('year' from age(death_date, birth_date)))
FROM authors;

-- Инструкция SELECT, использующая скалярные подзапросы в выражениях столбцов.
SELECT *
FROM (
  SELECT title, (SELECT AVG(rate) FROM reviews r where b.id = r.book_id)::INTEGER AS avg_rate
    FROM books b
    ORDER BY published_at
) g WHERE g.avg_rate IS NOT NULL;

-- Инструкция SELECT, использующая простое выражение CASE.
SELECT name, birth_date,
CASE
  WHEN death_date IS NULL 
    THEN 'alive'
    ELSE 'dead'
  END status
FROM authors
LIMIT 10;

-- Инструкция SELECT, использующая поисковое выражение CASE.
SELECT name, birth_date,
CASE
  WHEN death_date IS NOT NULL 
    THEN 'dead'
  WHEN extract('year' from age(NOW(), birth_date)) > 60
    THEN 'old'
  WHEN extract('year' from age(NOW(), birth_date)) > 30
    THEN 'midage'
  ELSE 'young'
  END status
FROM authors
LIMIT 10;

-- Создание новой временной локальной таблицы из результирующего набора данных инструкции SELECT.
CREATE TEMP TABLE recent_comments AS
SELECT text FROM comments WHERE created_at >= '2021-01-01';

-- Инструкция SELECT, использующая вложенные коррелированные подзапросы 
-- в качестве производных таблиц в предложении FROM.
SELECT r.book_id, r.id, x.text as comment
FROM reviews r, LATERAL 
(SELECT text FROM comments c WHERE c.review_id = r.id AND c.prev_comment_id IS NULL) x
ORDER BY r.book_id, r.id;

-- Инструкция SELECT, использующая вложенные подзапросы с уровнем вложенности 3.
SELECT name
FROM authors a
WHERE a.id IN (
  SELECT ab.author_id
  FROM authors_books_rel ab
  WHERE ab.book_id IN (
    SELECT b.id
    FROM books b
    WHERE b.id IN (
      SELECT r.book_id
      FROM reviews r
      WHERE r.rate = 10
    )
  )
);

-- Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY, но без предложения HAVING.
SELECT rate, COUNT(id)
FROM reviews
GROUP BY rate
ORDER BY rate;

-- Инструкция SELECT, консолидирующая данные с помощью предложения GROUP BY и предложения HAVING.
SELECT b.id, b.title, rate, COUNT(r.id)
FROM reviews r
INNER JOIN books b ON b.id = book_id
GROUP BY b.id, b.title, rate
HAVING COUNT(r.id) > 1
ORDER BY b.title, rate;

-- Однострочная инструкция INSERT, выполняющая вставку в таблицу одной строки значений.
INSERT INTO libraries (address, phone)
VALUES ('some address', '79999999999');

-- Многострочная инструкция INSERT, выполняющая вставку в таблицу результирующего набора данных вложенного подзапроса.
INSERT INTO reviews (rate, text, reader_id, book_id)
SELECT 10, c.text, c.reader_id, r.book_id
FROM comments c
INNER JOIN reviews r ON r.id = c.review_id
WHERE c.text LIKE '%like%';

-- Простая инструкция UPDATE.
UPDATE libraries SET phone = '+71111111111' WHERE address = 'some address';

-- Инструкция UPDATE со скалярным подзапросом в предложении SET.
UPDATE authors a
SET death_date = (
  SELECT MAX(b.published_at)
  FROM books b
  WHERE b.id IN (
  	SELECT ab.book_id
    FROM authors_books_rel ab
    WHERE ab.author_id = a.id
  )
)
WHERE a.death_date IS NULL
AND a.birth_date < NOW() - INTERVAL '5 year';

-- Простая инструкция DELETE.
DELETE FROM con_books WHERE printed_at < NOW() - INTERVAL '100 year';

-- Инструкция DELETE с вложенным коррелированным подзапросом в предложении WHERE.
DELETE FROM libraries 
WHERE id NOT IN (SELECT library_id FROM con_books);

-- Инструкция SELECT, использующая простое обобщенное табличное выражение.
WITH book_owners (id, n_books) AS (
  SELECT r.id, COUNT(b.id)
  FROM readers r
  LEFT JOIN con_books b ON b.reader_id = r.id
  GROUP BY r.id
),
reviewers (id, n_reviews) AS (
  SELECT r.id, COUNT(rv.id)
  FROM readers r
  LEFT JOIN reviews rv ON rv.reader_id = r.id
  GROUP BY r.id
)
SELECT bo.n_books, AVG(rw.n_reviews)
FROM book_owners bo
INNER JOIN reviewers rw ON rw.id = bo.id
GROUP BY bo.n_books
ORDER BY bo.n_books;

-- Инструкция SELECT, использующая рекурсивное обобщенное табличное выражение.
WITH RECURSIVE hate_threads(id, text, created_at, review_id) AS (
  SELECT id, text, created_at, review_id FROM comments WHERE text LIKE '%hate%'
  UNION ALL
  SELECT c.id, c.text, c.created_at, c.review_id FROM comments c
  JOIN hate_threads h ON c.prev_comment_id = h.id
)
SELECT b.title, h.created_at, h.text
FROM hate_threads h
INNER JOIN reviews r ON r.id = h.review_id
INNER JOIN books b ON b.id = r.book_id
ORDER BY b.title, h.created_at;

-- Оконные функции. Использование конструкций MIN/MAX/AVG OVER().
SELECT book_id, id, AVG(rate) OVER(PARTITION BY book_id) as avg_rate
FROM reviews;

-- Оконные фнкции для устранения дублей.
DELETE FROM con_books
WHERE id IN (
  SELECT id
  FROM (
    SELECT id, ROW_NUMBER() OVER(
      PARTITION BY book_id, reader_id
    ) n
    FROM con_books
  ) x
  WHERE x.n > 1
);