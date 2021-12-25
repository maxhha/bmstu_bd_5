from typing import Callable, Optional
import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy import Table, Column, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
import os
from uuid import uuid4
from dataclasses import dataclass
from datetime import datetime
from pprint import pprint

engine = sa.create_engine(os.environ.get("POSTGRES_CONNECTION"))
Session = sessionmaker(bind=engine)
session: sa.orm.Session = Session()
Base = sa.orm.declarative_base()

authors_books_association_table = Table(
    'authors_books_rel', Base.metadata,
    Column('id', UUID(
        as_uuid=True), primary_key=True, default=uuid4),
    Column('author_id', ForeignKey(
        'books.id'), nullable=False),
    Column('book_id', ForeignKey(
        'authors.id'), nullable=False)
)


class Library(Base):
    __tablename__ = "libraries"
    id = Column(UUID(as_uuid=True),
                primary_key=True, default=uuid4)
    address = Column(sa.TEXT, nullable=False)
    phone = Column(sa.VARCHAR(32), nullable=False)
    info = Column(sa.JSON)
    books = relationship("ConBook", back_populates="library",
                         cascade="all, delete-orphan")


class Reader(Base):
    __tablename__ = "readers"
    id = Column(UUID(as_uuid=True),
                primary_key=True, default=uuid4)
    address = Column(sa.TEXT, nullable=False)
    phone = Column(sa.VARCHAR(32), nullable=False, unique=True)
    name = Column(sa.TEXT, nullable=False, unique=True)
    email = Column(sa.VARCHAR(256), nullable=False, unique=True)
    books = relationship("ConBook", back_populates="reader",
                         cascade="all, delete-orphan")
    reviews = relationship(
        "Review", back_populates="reader", cascade="all, delete-orphan")


class Author(Base):
    __tablename__ = "authors"
    id = Column(UUID(as_uuid=True),
                primary_key=True, default=uuid4)
    name = Column(sa.TEXT, nullable=False)
    birth_date = Column(sa.DATE, nullable=False)
    death_date = Column(sa.DATE)


class Book(Base):
    __tablename__ = "books"
    id = Column(UUID(as_uuid=True),
                primary_key=True, default=uuid4)
    published_at = Column(sa.DATE, nullable=False)
    title = Column(sa.TEXT, nullable=False)
    description = Column(sa.TEXT)
    con_books = relationship(
        "ConBook", back_populates="book", cascade="all, delete-orphan")
    reviews = relationship("Review", back_populates="book",
                           cascade="all, delete-orphan")


class ConBook(Base):
    __tablename__ = "con_books"
    id = Column(UUID(as_uuid=True),
                primary_key=True, default=uuid4)
    printed_at = Column(sa.DATE, nullable=False)
    publishing_house = Column(sa.TEXT, nullable=False)

    book_id = Column(UUID(
        as_uuid=True), ForeignKey('books.id'), nullable=False)
    book = relationship("Book", back_populates="con_books")

    library_id = Column(UUID(
        as_uuid=True), ForeignKey('libraries.id'), nullable=False)
    library = relationship(
        "Library", back_populates="books")

    reader_id = Column(UUID(
        as_uuid=True), ForeignKey('readers.id'))
    reader = relationship("Reader", back_populates="books")


class Review(Base):
    __tablename__ = "reviews"
    id = Column(UUID(as_uuid=True),
                primary_key=True, default=uuid4)
    created_at = Column(sa.DATE, nullable=False, default=datetime.utcnow)
    rate = Column(sa.INT, sa.CheckConstraint(
        "rate >= 0 and rate <= 10"), nullable=False)
    text = Column(sa.TEXT, nullable=False)

    reader_id = Column(UUID(as_uuid=True), ForeignKey('readers.id'))
    reader = relationship("Reader", back_populates="reviews")

    book_id = Column(UUID(
        as_uuid=True), ForeignKey('books.id'), nullable=False)
    book = relationship("Book", back_populates="reviews")


# CREATE TABLE comments (
#   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
#   created_at DATE NOT NULL DEFAULT now(),
#   text TEXT NOT NULL,
#   review_id UUID NOT NULL,
#   reader_id UUID NOT NULL,
#   prev_comment_id UUID,
#   CONSTRAINT fk_reader FOREIGN KEY(reader_id) REFERENCES readers(id),
#   CONSTRAINT fk_review FOREIGN KEY(review_id) REFERENCES reviews(id),
#   CONSTRAINT fk_prev_comment FOREIGN KEY(prev_comment_id) REFERENCES comments(id)
# );


@dataclass
class MenuOption:
    name: str
    action: Optional[Callable[[], None]]
    query: Callable[[], None]


LINQ_TO_OBJECTS = [
    MenuOption(
        "SELECT text, created_at from reviews WHERE rate = 10 ORDER BY created_at LIMIT 10;",
        None,
        lambda: sa.select(Review.text, Review.created_at).where(
            Review.rate == 10).order_by(Review.created_at).limit(10)
    ),
    MenuOption(
        "remove cascade",
        lambda: sa.delete(Review).where(
            Review.id == "00a45f6c-bfd2-40c6-bf86-123746006c87"),
        lambda: sa.select(Review).where(
            Review.id == "00a45f6c-bfd2-40c6-bf86-123746006c87")
    )
]

LIB_ID = "005bd03a-ee86-4ceb-802d-ae1997849514"

LINQ_TO_JSON = [
    MenuOption(
        "set json",
        lambda: sa.update(Library).where(Library.id == LIB_ID).values(
            {Library.info: {"hello": "world"}}),
        lambda: sa.select(Library.info).where(Library.id == LIB_ID)
    ),
]

LINQ_TO_SQL = [
    MenuOption(
        "SELECT text, created_at from reviews WHERE rate = 10 ORDER BY created_at LIMIT 10;",
        None,
        lambda: sa.sql.text(
            "SELECT text, created_at from reviews WHERE rate = 10 ORDER BY created_at LIMIT 10;"[:-1])
    ),
]

if __name__ == "__main__":
    index = 1
    print("Select action:")

    print("LINQ_TO_OBJECTS")
    for opt in LINQ_TO_OBJECTS:
        print(f"{index}. {opt.name}")
        index += 1

    print("LINQ_TO_JSON")
    for opt in LINQ_TO_JSON:
        print(f"{index}. {opt.name}")
        index += 1

    print("LINQ_TO_SQL")
    for opt in LINQ_TO_SQL:
        print(f"{index}. {opt.name}")
        index += 1

    index = int(input(">"))
    print()
    for opt in LINQ_TO_OBJECTS + LINQ_TO_JSON + LINQ_TO_SQL:
        index -= 1

        if index > 0:
            continue

        print(opt.name)
        print()

        if opt.action:
            session.execute(opt.action())
            session.commit()

        if opt.query:
            pprint(session.execute(opt.query()).all())

        break
