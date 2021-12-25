-- Тема: РК3 Дегтярев Александр ИУ7-53Б
-- Тело: Вариант 3 + файлы

DROP DATABASE IF EXISTS rk3;
CREATE DATABASE rk3;
\c rk3;

CREATE TABLE employee (
    id SERIAL PRIMARY KEY,
    fio VARCHAR NOT NULL,
    dob DATE NOT NULL,
    dep VARCHAR NOT NULL
);

CREATE TABLE inout (
    empid INT NOT NULL,
    evdate DATE NOT NULL,
    evday VARCHAR NOT NULL,
    evtime TIME NOT NULL,
    evtype INT NOT NULL,
    FOREIGN KEY (empid) REFERENCES employee(id) ON DELETE CASCADE
);

INSERT INTO employee (fio, dob, dep) VALUES
('Иванов Иван Иванович', '1990-09-25', 'ИТ'),
('Петров Петр Петрович', '1987-11-12', 'Бухгалтерия'),
('xxx xx xx', '2001-02-06', 'dep1'),
('yyy yy yy', '2001-03-07', 'dep2');

INSERT INTO inout (empid, evdate, evday, evtime, evtype) VALUES
(1, '2018-12-14', 'Суббота', '9:00', 1),
(1, '2018-12-14', 'Суббота', '9:20', 2),
(1, '2018-12-14', 'Суббота', '9:25', 1),
(2, '2018-12-14', 'Суббота', '9:05', 1);

CREATE OR REPLACE FUNCTION get_age_of_yongest_skipper(todaydate DATE)
RETURNS INT $$
BEGIN
    RETURN QUERY
    SELECT MIN(EXTRACT(year FROM age(NOW(), emp.bod)))
    FROM employee emp
    INNER JOIN inout i ON i.empid = emp.id
    WHERE i.evdate = todaydate
    AND i.time < '9:00'::TIME;
END;
$$ LANGUAGE PLPGSQL;
SELECT * FROM get_year_of_yongest_skipper('2018-12-14');

--------- 1.
SELECT e.fio
FROM employee e
WHERE e.dob = (
    SELECT MIN(e2.dob)
    FROM employee e2;
);

--------- 2.
SELECT MAX(e.fio)
FROM employee e
JOIN inout i ON i.empid = e.id AND i.evtype = 1
GROUP BY e.id
HAVING COUNT(1) > 3;

--------- 3.
SELECT e.fio
FROM employee e
JOIN inout i ON i.empid = e.id
WHERE i.date = NOW()
AND i.time = (
    SELECT MAX(i.time)
    FROM inout ii
    WHERE ii.date = NOW()
);
