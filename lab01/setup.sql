DROP TABLE IF EXISTS authors_books_rel;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS con_books;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS readers;
DROP TABLE IF EXISTS libraries;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE libraries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  address TEXT NOT NULL,
  phone VARCHAR(32) NOT NULL
);

CREATE TABLE readers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  address TEXT NOT NULL,
  phone VARCHAR(32) NOT NULL UNIQUE,
  name TEXT NOT NULL UNIQUE,
  email VARCHAR(256) NOT NULL UNIQUE
);

CREATE TABLE authors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  birth_date DATE NOT NULL,
  death_date DATE
);

CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  published_at DATE NOT NULL,
  title TEXT NOT NULL,
  description TEXT
);

CREATE TABLE authors_books_rel (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID NOT NULL UNIQUE,
  book_id UUID NOT NULL UNIQUE,
  CONSTRAINT fk_author FOREIGN KEY(author_id) REFERENCES authors(id),
  CONSTRAINT fk_book FOREIGN KEY(book_id) REFERENCES books(id)
);

CREATE TABLE con_books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  printed_at DATE NOT NULL,
  publishing_house TEXT NOT NULL,
  book_id UUID NOT NULL,
  library_id UUID NOT NULL,
  reader_id UUID,
  CONSTRAINT fk_library FOREIGN KEY(library_id) REFERENCES libraries(id),
  CONSTRAINT fk_reader FOREIGN KEY(reader_id) REFERENCES readers(id),
  CONSTRAINT fk_book FOREIGN KEY(book_id) REFERENCES books(id)
);

CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at DATE NOT NULL DEFAULT now(),
  rate INT NOT NULL CHECK(rate >= 0 AND rate <= 10),
  text TEXT NOT NULL,
  reader_id UUID NOT NULL,
  book_id UUID NOT NULL,
  CONSTRAINT fk_reader FOREIGN KEY(reader_id) REFERENCES readers(id),
  CONSTRAINT fk_book FOREIGN KEY(book_id) REFERENCES books(id)
);

CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  created_at DATE NOT NULL DEFAULT now(),
  text TEXT NOT NULL,
  review_id UUID NOT NULL,
  reader_id UUID NOT NULL,
  prev_comment_id UUID,
  CONSTRAINT fk_reader FOREIGN KEY(reader_id) REFERENCES readers(id),
  CONSTRAINT fk_review FOREIGN KEY(review_id) REFERENCES reviews(id),
  CONSTRAINT fk_prev_comment FOREIGN KEY(prev_comment_id) REFERENCES comments(id)
);

-- ЗАЩИТА 1 Я ЕБАЛ

CREATE OR REPLACE FUNCTION update_reviews_karma()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE reviews r
  SET karma = (
    SELECT SUM(c.karma)
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

DROP TRIGGER IF EXISTS trig_readers_karma ON reviews;

CREATE TRIGGER trig_readers_karma
AFTER INSERT OR UPDATE OR DELETE 
ON reviews
FOR EACH ROW
EXECUTE PROCEDURE update_readers_karma();

INSERT INTO comments(text, review_id, reader_id, prev_comment_id, karma)
VALUES ('-', '002e3a9e-59c6-498c-b772-05ba4051f763', '00db799c-dbf4-432b-a393-207749aed728', NULL, 10)

