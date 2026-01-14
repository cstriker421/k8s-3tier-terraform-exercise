import express from "express";
import pg from "pg";

const {
  DB_HOST = "postgres",
  DB_PORT = "5432",
  DB_NAME = "appdb",
  DB_USER = "appuser",
  DB_PASSWORD = "",
  APP_MESSAGE = "Hello from backend (default)!"
} = process.env;

const app = express();
app.use(express.json());

const pool = new pg.Pool({
  host: DB_HOST,
  port: Number(DB_PORT),
  database: DB_NAME,
  user: DB_USER,
  password: DB_PASSWORD
});

async function initDb() {
  // Creates a table and keeps a counter row
  await pool.query(`
    CREATE TABLE IF NOT EXISTS hits (
      id INT PRIMARY KEY,
      count INT NOT NULL
    );
  `);
  await pool.query(`
    INSERT INTO hits (id, count)
    VALUES (1, 0)
    ON CONFLICT (id) DO NOTHING;
  `);
}

app.get("/api/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  }
});

app.get("/api/message", async (req, res) => {
  try {
    await initDb();
    const upd = await pool.query("UPDATE hits SET count = count + 1 WHERE id=1 RETURNING count");
    res.json({
      message: APP_MESSAGE,
      db: { host: DB_HOST, name: DB_NAME, user: DB_USER },
      hits: upd.rows[0].count
    });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

const port = 3000;
app.listen(port, () => console.log(`Backend listening on ${port}`));
