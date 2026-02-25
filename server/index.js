const express = require('express');
const path = require('path');
const fs = require('fs');

const fetchModule = require('./fetch_and_save');

const app = express();
const PORT = process.env.PORT || 3000;

const CACHE_PATH = path.join(__dirname, 'data', 'deals.json');

app.get('/deals', async (req, res) => {
  try {
    if (fs.existsSync(CACHE_PATH)) {
      const txt = await fs.promises.readFile(CACHE_PATH, 'utf8');
      return res.type('json').send(txt);
    }
    // Fallback: perform a live fetch
    const out = await fetchModule.run();
    res.json(out);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Trigger a scrape manually
app.post('/scrape', async (req, res) => {
  try {
    const out = await fetchModule.run();
    res.json({ ok: true, resultCount: out.combined.length });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Scrape failed' });
  }
});

app.listen(PORT, () => console.log(`Server listening on ${PORT}`));
