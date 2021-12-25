from playhouse.db_url import connect
import peewee as pw

db = connect("postgresext://postgres:qwerty12345@localhost:5432/rk3")


class BaseModel(pw.Model):
    class Meta:
        database = db


class Employee(BaseModel):
    id = pw.PrimaryKeyField()
    fio = pw.CharField()
    dob = pw.DateField()
    dep = pw.CharField()


class Inout(BaseModel):
    empid = pw.ForeignKeyField(Employee, on_delete="cascade")
    evdate = pw.DateField()
    evday = pw.CharField()
    evtime = pw.TimeField()
    evtype = pw.IntegerField()


def task_1():
    cursor = db.execute_sql("""
SELECT e.fio
FROM employee e
WHERE e.dob = (
    SELECT MIN(e2.dob)
    FROM employee e2;
);
    """)
    for row in cursor.fetchall():
        print(row)

    cursor = Employee.select(Employee.fio).where(
        Employee.dob == Employee.select(pw.fn.Min(Employee.dob))
    )
    for row in cursor:
        print(row)


def task_2():
    cursor = db.execute_sql("""
SELECT MAX(e.fio)
FROM employee e
JOIN inout i ON i.empid = e.id
WHERE i.evtype = 2
GROUP BY e.id
HAVING COUNT(1) > 3;
    """)
    for row in cursor.fetchall():
        print(row)
    cursor = Employee.select(pw.fn.Max(Employee.fio)).join(Inout).where(
        Inout.evtype == 2,
    ).group_by(Inout.id).having(pw.fn.Count(1) > 3))
    for row in cursor:
        print(row)


def task_3():
    cursor = db.execute_sql("""
SELECT e.fio
FROM employee e
JOIN inout i ON i.empid = e.id
WHERE i.date = NOW()
AND i.time = (
    SELECT MAX(i.time)
    FROM inout ii
    WHERE ii.date = NOW()
);
""")
    for row in cursor.fetchall():
        print(row)
    cursor = Employee.select(Employee.fio).join(Inout).where(
        Inout.date == pw.fn.now(),
        Inout.time == Inout.select(pw.fn.Max(Inout.time)).where(Inout.date == pw.fn.now())
    )
    for row in cursor:
        print(row)


def main():
    task_1()
    task_2()
    task_3()


if __name__ == "__main__":
    main()