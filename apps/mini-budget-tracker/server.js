// server.js
const express = require("express");
const fs = require("fs");
const path = require("path");
const bodyParser = require("body-parser");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(bodyParser.json());
app.use(cors());

// Serve static files with path prefix for Ingress
app.use('/mini-budget-tracker', express.static(path.join(__dirname, "public")));

// Routes for HTML pages (also with prefix)
app.get('/mini-budget-tracker', (req, res) => res.sendFile(path.join(__dirname, "public/index.html")));
app.get('/mini-budget-tracker/data', (req, res) => res.sendFile(path.join(__dirname, "public/data.html")));

const DATA_FILE = path.join(__dirname, "data.json");

// Utility: Read Data
function readData() {
  if (!fs.existsSync(DATA_FILE)) return [];
  return JSON.parse(fs.readFileSync(DATA_FILE));
}

// Utility: Save Data
function saveData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

// ✅ Get all transactions
app.get("/api/transactions", (req, res) => {
  let data = readData();

  const { category, min, max, sortBy, order } = req.query;

  if (category) data = data.filter(t => t.category.toLowerCase() === category.toLowerCase());
  if (min) data = data.filter(t => t.amount >= parseFloat(min));
  if (max) data = data.filter(t => t.amount <= parseFloat(max));

  if (sortBy) {
    data.sort((a, b) => {
      if (order === "desc") return b[sortBy] > a[sortBy] ? 1 : -1;
      return a[sortBy] > b[sortBy] ? 1 : -1;
    });
  }

  res.json(data);
});

// ✅ Add transaction
app.post("/api/transactions", (req, res) => {
  const { id, date, type, category, amount, notes, recurring } = req.body;
  if (!date || !category || !amount) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  const data = readData();
  const newTransaction = {
    id: id || Date.now(),
    date,
    type,
    category,
    amount: parseFloat(amount),
    notes: notes || "",
    recurring: !!recurring,
    description: notes || category
  };

  data.push(newTransaction);
  saveData(data);
  res.json(newTransaction);
});

// ✅ Delete transaction
app.delete("/api/transactions/:id", (req, res) => {
  const data = readData();
  const newData = data.filter(t => t.id != req.params.id);
  saveData(newData);
  res.json({ success: true });
});

// ✅ Update transaction
app.put("/api/transactions/:id", (req, res) => {
  const { date, type, category, amount, notes, recurring } = req.body;
  let data = readData();
  let transaction = data.find(t => t.id == req.params.id);

  if (!transaction) return res.status(404).json({ error: "Not found" });

  transaction.date = date || transaction.date;
  transaction.type = type || transaction.type;
  transaction.category = category || transaction.category;
  transaction.amount = parseFloat(amount) || transaction.amount;
  transaction.notes = notes || transaction.notes;
  transaction.recurring = recurring !== undefined ? recurring : transaction.recurring;
  transaction.description = notes || category || transaction.description;

  saveData(data);
  res.json(transaction);
});

// ✅ Summary: total income, expenses, balance
app.get("/api/summary", (req, res) => {
  const data = readData();
  const income = data.filter(t => t.amount > 0).reduce((a, b) => a + b.amount, 0);
  const expense = data.filter(t => t.amount < 0).reduce((a, b) => a + b.amount, 0);
  const balance = income + expense;
  res.json({ income, expense, balance });
});

// ✅ Export as CSV
app.get("/api/export", (req, res) => {
  const data = readData();
  const csv = [
    "ID,Description,Amount,Category,Date",
    ...data.map(t => `${t.id},"${t.description}",${t.amount},${t.category},${t.date}`)
  ].join("\n");

  res.header("Content-Type", "text/csv");
  res.attachment("transactions.csv");
  res.send(csv);
});

// ✅ Clear all data
app.delete("/api/clear", (req, res) => {
  saveData([]);
  res.json({ success: true });
});

// Start server
app.listen(PORT, () => console.log(`🚀 Server running on http://localhost:${PORT}`));
