const express = require("express");
const cors = require("cors");
const port = process.env.PORT || 3001;
const pgp = require("pg-promise")();
const db = pgp(process.env.POSTGRES_CONNECTION);
const app = express();

const router = express.Router();

router.get("/count_reviews", async (req, res) => {
  const query = `
    -- Cкалярный запрос
    SELECT count(*) FROM reviews;
  `;

  if (req.query.query) return res.json({ query });

  res.json(await db.any(query));
});

router.get("/get_books", async (req, res) => {
  const query = `
    -- Выполнить запрос с несколькими соединениями (JOIN);
    SELECT b.title, a.name
    FROM books b
    JOIN authors_books_rel ab ON ab.book_id = b.id
    JOIN authors a ON ab.author_id = a.id
    OFFSET $1
    LIMIT 25;
  `;

  if (req.query.query) return res.json({ query });

  try {
    res.json(await db.any(query, JSON.parse(req.query.params)));
  } catch (error) {
    res.json({ error: error.message || error });
  }
});

router.get("/get_avg_n_reviews_per_book_owner", async (req, res) => {
  const query = `
    -- Выполнить запрос с ОТВ(CTE) и оконными функциями;
    WITH book_owners (id, name, n_books) AS (
      SELECT r.id, MAX(r.name), COUNT(b.id)
      FROM readers r
      LEFT JOIN con_books b ON b.reader_id = r.id
      GROUP BY r.id
    ),
    reviewers (id, n_reviews) AS (
      SELECT r.id, COUNT(rv.id)
      FROM readers r
      LEFT JOIN reviews rv ON rv.reader_id = r.id
      GROUP BY r.id
    )
    SELECT 
      bo.name, 
      bo.n_books, 
      ROUND(
        AVG(rw.n_reviews) 
          OVER(PARTITION BY bo.n_books)::NUMERIC,
        2
      ) as avg_n_reviews
    FROM book_owners bo
    INNER JOIN reviewers rw ON rw.id = bo.id
    ORDER BY bo.n_books DESC
    OFFSET $1
    LIMIT 25;
  `;

  if (req.query.query) return res.json({ query });

  try {
    res.json(await db.any(query, JSON.parse(req.query.params)));
  } catch (error) {
    res.json({ error: error.message || error });
  }
});

router.get("/get_datconnlimit", async (req, res) => {
  const query = `
    -- Выполнить запрос к метаданным
    SELECT pg.oid, pg.datconnlimit
    FROM pg_database pg
    WHERE pg.datname = $1;
  `;

  if (req.query.query) return res.json({ query });

  try {
    res.json(await db.any(query, JSON.parse(req.query.params)));
  } catch (error) {
    res.json({ error: error.message || error });
  }
});

router.get("/get_age", async (req, res) => {
  const query = `
    -- Вызвать скалярную функцию
    SELECT name, get_age(birth_date, death_date)
    FROM authors
    OFFSET $1
    LIMIT 25;
  `;

  if (req.query.query) return res.json({ query });

  try {
    res.json(await db.any(query, JSON.parse(req.query.params)));
  } catch (error) {
    res.json({ error: error.message || error });
  }
});

router.get("/get_authors_rates", async (req, res) => {
  const query = `
    -- Вызвать многооператорную или табличную функцию
    SELECT *
    FROM get_authors_rates($2)
    OFFSET $1
    LIMIT 25;
  `;

  if (req.query.query) return res.json({ query });

  try {
    res.json(await db.any(query, JSON.parse(req.query.params)));
  } catch (error) {
    res.json({ error: error.message || error });
  }
});

router.get("/update_author_death_date", async (req, res) => {
  const query = `
    -- Вызвать хранимую процедуру
    CALL update_death_date($1, $2);
  `;

  if (req.query.query) return res.json({ query });

  try {
    res.json(await db.any(query, JSON.parse(req.query.params)));
  } catch (error) {
    res.json({ error: error.message || error });
  }
});

router.get("/current_database", async (req, res) => {
  const query = `
    -- Вызвать системную функцию или процедуру.
    SELECT * FROM current_database();
  `;

  if (req.query.query) return res.json({ query });

  try {
    res.json(await db.any(query, JSON.parse(req.query.params)));
  } catch (error) {
    res.json({ error: error.message || error });
  }
});

router.get("/create_table", async (req, res) => {
  const query = `
    -- Создать таблицу в базе данных, соответствующую тематике БД.
    DROP TABLE IF EXISTS author_groups;
    CREATE TABLE author_groups (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      created_at DATE NOT NULL DEFAULT NOW(),
      owner_id UUID NOT NULL,
      name TEXT,
      CONSTRAINT fk_author FOREIGN KEY(owner_id) REFERENCES authors(id)
    );
  `;

  if (req.query.query) return res.json({ query });

  try {
    res.json(await db.any(query, JSON.parse(req.query.params)));
  } catch (error) {
    res.json({ error: error.message || error });
  }
});

router.get("/insert_table", async (req, res) => {
  const query = `
    -- Выполнить вставку данных в созданную таблицу с использованием 
    -- инструкции INSERT или COPY
    INSERT INTO author_groups (owner_id, name)
    VALUES ($1, $2);
  `;

  if (req.query.query) return res.json({ query });

  try {
    res.json(await db.any(query, JSON.parse(req.query.params)));
  } catch (error) {
    res.json({ error: error.message || error });
  }
});

router.get("/select_table", async (req, res) => {
  const query = `
    SELECT * FROM author_groups;
  `;

  if (req.query.query) return res.json({ query });

  try {
    res.json(await db.any(query, JSON.parse(req.query.params)));
  } catch (error) {
    res.json({ error: error.message || error });
  }
});

app.use(cors({ origin: "*" }));
app.use("/api/v1", router);

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`);
});
