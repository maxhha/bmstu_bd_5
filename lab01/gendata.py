from collections import namedtuple
from faker import Faker
from datetime import date

Faker.seed(2021_09_11_17_30)
faker = Faker()

N_AUTHORS = 10
N_BOOKS = 10
BASE_DIR = "./db-data/"

Author = namedtuple("Author", ["id", "name", "birth_date", "death_date"])
Book = namedtuple("Book", ["id", "published_at", "title", "description"])
BookAuthorRel = namedtuple("BookAuthorRel", ["id", "author_id", "book_id"])

authors = []
books = []
books_authors_rels = []

for _ in range(N_AUTHORS):
    uuid = faker.unique.uuid4()
    name = faker.name()
    birth_date = faker.date_between(start_date="-300y")
    death_date = None

    if birth_date < date(1980, 1, 1) or faker.random.random() > 0.8:
        death_date = faker.date_between(start_date=birth_date)

    authors.append(Author(uuid, name, birth_date, death_date))

faker.unique.clear()

for _ in range(N_BOOKS):
    _authors = []
    min_date = None
    max_date = None

    while True:
        _authors = faker.random.sample(authors, faker.random.randint(1, 5))

        max_date = min(
            i.death_date for i in _authors
            if i.death_date is not None)

        min_date = max(
            i.birth_date for i in _authors)

        if min_date < max_date:
            break

    uuid = faker.unique.uuid4()
    published_at = faker.date_between(start_date=min_date, end_date=max_date)
    title = faker.unique.sentence(nb_words=faker.random.randint(1, 10))
    description = "\\n".join(faker.paragraphs())

    books.append(Book(uuid, published_at, title, description))
    books_authors_rels.append([uuid, _authors])

faker.unique.clear()

books_authors_rels = [
    BookAuthorRel(
        faker.unique.uuid4(),
        auth.id,
        book_id)
    for book_id, _authors in books_authors_rels
    for auth in _authors
]

faker.unique.clear()


def csv(*args):
    return ";".join(
        str(arg) if arg is not None else "null"
        for arg in args
    ) + "\n"


def csv_date(date):
    return date.strftime('%Y-%m-%d')


with open(BASE_DIR+"authors.csv", "w") as f:
    for auth in authors:
        f.write(csv(
            auth.id,
            auth.name,
            csv_date(auth.birth_date),
            csv_date(auth.death_date)
        ))

with open(BASE_DIR+"books.csv", "w") as f:
    for book in books:
        f.write(csv(
            book.id,
            csv_date(book.published_at),
            book.title,
            book.description
        ))

with open(BASE_DIR+"authors_books_rel.csv", "w") as f:
    for rel in books_authors_rels:
        f.write(csv(
            rel.id,
            rel.author_id,
            rel.book_id
        ))
