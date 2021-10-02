DROP TABLE IF EXISTS table1;
DROP TABLE IF EXISTS table2;

CREATE TABLE table1 (
  id INT,
  var1 VARCHAR,
  valid_from_dttm DATE,
  valid_to_dttm DATE
);

CREATE TABLE table2 (
  id INT,
  var2 VARCHAR,
  valid_from_dttm DATE,
  valid_to_dttm DATE
);

INSERT INTO table1 (id, var1, valid_from_dttm, valid_to_dttm)
VALUES
  (1, 'A', '2018-09-01', '2018-09-15'), 
  (1, 'B', '2018-09-16', '5999-12-31');

INSERT INTO table2 (id, var2, valid_from_dttm, valid_to_dttm)
VALUES 
  (1, 'A', '2018-09-01', '2018-09-18'),
  (1, 'B', '2018-09-19', '5999-12-31');


WITH tablex AS (
  SELECT *, ROW_NUMBER() OVER(PARTITION BY t.id) n
  FROM (
    SELECT id, valid_from_dttm
    FROM table1
    UNION
    SELECT id, valid_from_dttm
    FROM table2
    ORDER BY id, valid_from_dttm
  ) t
),
tabley AS (
  SELECT *, ROW_NUMBER() OVER(PARTITION BY t.id) n
  FROM (
  	SELECT id, valid_to_dttm
    FROM table1
    UNION
    SELECT id, valid_to_dttm
    FROM table2
    ORDER BY id, valid_to_dttm
  ) t
),
tablex1 AS (
  SELECT t.id, t.var1, t.valid_from_dttm
  FROM (
    SELECT 
      tx.id, t1.var1, tx.valid_from_dttm,
      ROW_NUMBER() OVER(
        PARTITION BY tx.id, tx.valid_from_dttm ORDER BY t1.valid_to_dttm DESC
      ) n
    FROM tablex tx
    LEFT JOIN table1 t1 ON t1.id = tx.id AND t1.valid_from_dttm <= tx.valid_from_dttm
  ) t
  WHERE t.n = 1
),
tablex2 AS (
  SELECT t.id, t.var2, t.valid_from_dttm
  FROM (
    SELECT 
      tx.id, t2.var2, tx.valid_from_dttm, 
      ROW_NUMBER() OVER(
        PARTITION BY tx.id, tx.valid_from_dttm ORDER BY t2.valid_to_dttm DESC
      ) n
    FROM tablex tx
    LEFT JOIN table2 t2 ON t2.id = tx.id AND t2.valid_from_dttm <= tx.valid_from_dttm
  ) t
  WHERE t.n = 1
)
SELECT 
  tx.id, tx1.var1, tx2.var2, tx.valid_from_dttm, ty.valid_to_dttm
FROM tablex tx
JOIN tablex1 tx1 ON tx1.id = tx.id AND tx1.valid_from_dttm = tx.valid_from_dttm
JOIN tablex2 tx2 ON tx2.id = tx.id AND tx2.valid_from_dttm = tx.valid_from_dttm
JOIN tabley ty ON ty.id = tx.id AND ty.n = tx.n;


SELECT t1.id, t1.var1, t2.var2,
 GREATEST(t1.valid_from_dttm, t2.valid_from_dttm),
 LEAST(t1.valid_to_dttm, t2.valid_to_dttm)
FROM table1 t1, table2 t2
WHERE t1.id = t2.id
AND t1.valid_from_dttm <= t2.valid_to_dttm
AND t2.valid_from_dttm <= t1.valid_to_dttm