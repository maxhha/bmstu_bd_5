import json
import datetime
from faker import Faker
from os import path as p
import schedule
import time

def csv_date(date):
    return date.strftime('%Y-%m-%d') if date is not None else None

fake = Faker()
gid = 0

def create_books(dataset: str, count: int = 1000):
    global gid

    data = []
    for i in range(count):
        data.append({
            'id': fake.unique.uuid4(),
            'published_at':  csv_date(fake.date_between(start_date="-300y")),
            'title': fake.sentence(nb_words=fake.random.randint(1, 10)),
            'description': "\\n".join(fake.paragraphs()),
        })

    fout = f'books_{gid}_{datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")}.json'
    gid += 1
    with open(p.join(dataset, fout), "w", newline='') as json_file:
        json.dump(data, json_file, default=str)


def main():
    dpath = p.dirname(p.abspath(__file__))
    dataset = dpath

    size = 10_000

    schedule.every(15).seconds.do(create_books, dataset=dataset, count=size)

    while True:
        schedule.run_pending()
        time.sleep(1)


if __name__ == "__main__":
    main()