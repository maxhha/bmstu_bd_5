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

COPY readers
    FROM '/var/db-data/readers.csv'
    WITH DELIMITER ';'
    NULL AS 'null'
    CSV;

COPY libraries(id, address, phone)
    FROM '/var/db-data/libraries.csv'
    WITH DELIMITER ';'
    NULL AS 'null'
    CSV;

COPY con_books(id, printed_at, publishing_house, book_id, library_id, reader_id)
    FROM '/var/db-data/con_books.csv'
    WITH DELIMITER ';'
    NULL AS 'null'
    CSV;

COPY reviews(id, created_at, rate, text, reader_id, book_id)
    FROM '/var/db-data/reviews.csv'
    WITH DELIMITER ';'
    NULL AS 'null'
    CSV;

COPY comments(id, created_at, text, review_id, reader_id, prev_comment_id)
    FROM '/var/db-data/comments.csv'
    WITH DELIMITER ';'
    NULL AS 'null'
    CSV;

