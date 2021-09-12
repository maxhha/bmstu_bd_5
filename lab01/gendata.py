from collections import namedtuple
from random import choice
from faker import Faker
from datetime import date

Faker.seed(2021_09_13_00_12)
faker = Faker()

N_AUTHORS = 1000
N_BOOKS = 1000
N_READERS = 1000
N_LIBRARIES = 1000
N_CON_BOOKS = 1000
N_REVIEWS = 1000
N_COMMENTS = 1000
BASE_DIR = "./db-data/"

Author = namedtuple("Author", ["id", "name", "birth_date", "death_date"])
Book = namedtuple("Book", ["id", "published_at", "title", "description"])
AuthorBookRel = namedtuple("AuthorBookRel", ["id", "author_id", "book_id"])
Reader = namedtuple("Reader", ["id", "address", "phone", "name", "email"])
Library = namedtuple("Library", ["id", "address", "phone"])
ConBook = namedtuple("ConBook", [
                     "id", "printed_at", "publishing_house", "book_id", "library_id", "reader_id"])
Review = namedtuple(
    "Review", ["id", "created_at", "rate", "text", "reader_id", "book_id"])
Comment = namedtuple(
    "Comment", ["id", "created_at", "text", "review", "reader_id", "prev_comment_id"])

authors = []
books = []
books_authors_rels = []
readers = []
libraries = []
con_books = []
reviews = []
comments = []

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

        max_date = min([date.today(), *((i.death_date for i in _authors
                                         if i.death_date is not None))])

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
    AuthorBookRel(
        faker.unique.uuid4(),
        auth.id,
        book_id)
    for book_id, _authors in books_authors_rels
    for auth in _authors
]

faker.unique.clear()

for _ in range(N_READERS):
    uuid = faker.unique.uuid4()
    address = repr(faker.address())
    phone = faker.unique.phone_number()
    name = faker.unique.name()
    email = faker.unique.email()

    readers.append(Reader(uuid, address, phone, name, email))

faker.unique.clear()

for _ in range(N_LIBRARIES):
    uuid = faker.unique.uuid4()
    address = repr(faker.address())
    phone = faker.unique.phone_number()

    libraries.append(Library(uuid, address, phone))


faker.unique.clear()

for _ in range(N_CON_BOOKS):
    book = faker.random.choice(books)
    library = faker.random.choice(libraries)
    reader_id = None

    if faker.random.random() > 0.5:
        reader_id = faker.random.choice(readers).id

    uuid = faker.unique.uuid4()
    printed_at = faker.date_between(book.published_at)
    publishing_house = faker.sentence(nb_words=faker.random.randint(1, 10))
    con_books.append(ConBook(uuid, printed_at, publishing_house,
                             book.id, library.id, reader_id))

faker.unique.clear()

for _ in range(N_REVIEWS):
    book = faker.random.choice(books)
    reader = faker.random.choice(readers)

    uuid = faker.unique.uuid4()
    created_at = faker.date_between(book.published_at)
    rate = faker.random.randint(0, 10)
    text = "\\n".join(faker.paragraphs())

    reviews.append(Review(uuid, created_at, rate, text, reader.id, book.id))

faker.unique.clear()

for _ in range(N_COMMENTS):
    prev_comment = None

    if len(comments) > 0 and faker.random.random() > 0.5:
        prev_comment = faker.random.choice(comments)

    review = faker.random.choice(
        reviews) if prev_comment is None else prev_comment.review
    reader = faker.random.choice(readers)

    min_date = review.created_at
    if prev_comment is not None:
        min_date = prev_comment.created_at

    uuid = faker.unique.uuid4()
    created_at = faker.date_between(min_date)
    text = "\\n".join(faker.paragraphs())

    comments.append(Comment(uuid, created_at, text, review, reader,
                            None if prev_comment is None else prev_comment.id))


faker.unique.clear()


def csv(*args):
    return ";".join(
        str(arg) if arg is not None else "null"
        for arg in args
    ) + "\n"


def csv_date(date):
    return date.strftime('%Y-%m-%d') if date is not None else None


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

with open(BASE_DIR+"readers.csv", "w") as f:
    for reader in readers:
        f.write(csv(
            reader.id,
            reader.address,
            reader.phone,
            reader.name,
            reader.email
        ))

with open(BASE_DIR+"libraries.csv", "w") as f:
    for library in libraries:
        f.write(csv(
            library.id,
            library.address,
            library.phone
        ))


with open(BASE_DIR+"con_books.csv", "w") as f:
    for con_book in con_books:
        f.write(csv(
            con_book.id,
            csv_date(con_book.printed_at),
            con_book.publishing_house,
            con_book.book_id,
            con_book.library_id,
            con_book.reader_id
        ))

with open(BASE_DIR+"reviews.csv", "w") as f:
    for review in reviews:
        f.write(csv(review.id, csv_date(review.created_at), review.rate,
                    review.text, review.reader_id, review.book_id))


with open(BASE_DIR+"comments.csv", "w") as f:
    for comment in comments:
        f.write(csv(comment.id, csv_date(comment.created_at), comment.text, comment.review.id,
                    comment.reader_id, comment.prev_comment_id))
