-- Из таблиц базы данных, созданной в первой лабораторной работе, извлечь данные в JSON
COPY (SELECT ARRAY_TO_JSON(ARRAY_AGG(t)) FROM libraries t) to '/var/db-data/libraries.json';
COPY (SELECT ARRAY_TO_JSON(ARRAY_AGG(t)) FROM readers t) to '/var/db-data/readers.json';
COPY (SELECT ARRAY_TO_JSON(ARRAY_AGG(t)) FROM authors t) to '/var/db-data/authors.json';
COPY (SELECT ARRAY_TO_JSON(ARRAY_AGG(t)) FROM books t) to '/var/db-data/books.json';
COPY (SELECT ARRAY_TO_JSON(ARRAY_AGG(t)) FROM authors_books_rel t) to '/var/db-data/authors_books_rel.json';
COPY (SELECT ARRAY_TO_JSON(ARRAY_AGG(t)) FROM con_books t) to '/var/db-data/con_books.json';
COPY (SELECT ARRAY_TO_JSON(ARRAY_AGG(t)) FROM reviews t) to '/var/db-data/reviews.json';
COPY (SELECT ARRAY_TO_JSON(ARRAY_AGG(t)) FROM comments t) to '/var/db-data/comments.json';

-- Выполнить загрузку и сохранение XML или JSON файла в таблицу.
\set content `cat /var/db-data/reviews.json`

CREATE TEMP TABLE tablex (rate INT, text TEXT);

INSERT INTO tablex (rate, text)
SELECT * FROM json_populate_recordset(NULL::tablex, :'content');

-- Создать таблицу, в которой будет атрибут(-ы) с типом XML или JSON, или
-- добавить атрибут с типом XML или JSON к уже существующей таблице.
-- Заполнить атрибут правдоподобными данными с помощью команд INSERT
-- или UPDATE.

CREATE TEMP TABLE some_json (
    data jsonb
);

INSERT INTO some_json (data)
VALUES
('{"url":"http://example.com/","color":"red","text":"click"}'),
('{"url":"http://example.com/hook","text":"hook"}'),
('{"url":"http://example.com/","text":"click","data":{"source":"yandex"}}');

-- Извлечь JSON фрагмент из JSON документа
SELECT data->'url', data->'color' FROM some_json;

-- Извлечь значения конкретных узлов или атрибутов JSON документа.
SELECT data->'url', data->'data'->'source' FROM some_json;

-- Выполнить проверку существования узла или атрибута.
SELECT data->'data'->'source' is NULL,  data->'data'->'source' FROM some_json;

-- Изменить JSON документ.
UPDATE some_json
SET data = data || '{"url":"http://yandex.com/"}'::jsonb
WHERE data->'data'->>'source' = 'yandex';

-- Разделить JSON документ на несколько строк по узлам.
SELECT * FROM jsonb_array_elements(:'content');
