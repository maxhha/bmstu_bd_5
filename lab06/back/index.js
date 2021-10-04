const express = require("express");
const cors = require("cors");
const port = process.env.PORT || 3001;
const pgp = require("pg-promise")();
const db = pgp(process.env.POSTGRES_CONNECTION);
const app = express();

const router = express.Router();

router.get("/count_reviews", async (req, res) => {
  const query = `
    SELECT count(*) FROM reviews;
  `;

  if (req.query.query) return res.json({ query });

  res.json(await db.any(query));
});

router.get("/get_books", async (req, res) => {
  const query = `
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

app.use(cors({ origin: "*" }));
app.use("/api/v1", router);

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`);
});
