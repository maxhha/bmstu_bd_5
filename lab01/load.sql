COPY authors(id, name, birth_date, death_date)
	FROM '/var/db-data/authors.csv'
    WITH DELIMITER ';'
    NULL AS 'null'
    CSV;

COPY books(id, published_at, title, description)
	FROM '/var/db-data/books.csv'
    WITH DELIMITER ';'
    NULL AS 'null'
    CSV;

COPY authors_books_rel(id, author_id, book_id)
    FROM '/var/db-data/authors_books_rel.csv'
    WITH DELIMITER ';'
    NULL AS 'null'
    CSV;
