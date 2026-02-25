const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');
const cheerio = require('cheerio');
const similarity = require('string-similarity');

const OUT_PATH = path.join(__dirname, 'data', 'deals.json');

async function fetchSteamDeals() {
  try {
    const url = 'https://store.steampowered.com/api/featuredcategories';
    const r = await fetch(url);
    if (!r.ok) return [];
    const json = await r.json();
    const specials = (json.specials && json.specials.items) || [];
    return specials.map(s => ({
      id: s.id || null,
      title: s.name || 'Unknown',
      discount_percent: s.discount_percent || 0,
      price_final: s.price ? s.price.final : s.final || null,
      price_original: s.price ? s.price.initial : s.initial || null,
      source: 'steam'
    }));
  } catch (err) {
    console.warn('Steam fetch error', err && err.message);
    return [];
  }
}

async function fetchEpicDeals() {
  try {
    const searchUrl = 'https://www.epicgames.com/store/tr/browse?q=&sortBy=releaseDate&sortDir=DESC&count=40';
    const r = await fetch(searchUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } });
    const text = await r.text();
    const $ = cheerio.load(text);
    const items = [];
    $('.Card-root').each((i, el) => {
      const title = $(el).find('.Card-title').text().trim();
      if (!title) return;
      const a = $(el).find('a').first();
      let href = a.attr('href') || null;
      if (href && href.startsWith('/')) href = 'https://www.epicgames.com' + href;
      items.push({ title, source: 'epic', url: href });
    });
    // For each item, try to fetch product page to get price information
    const detailed = [];
    for (const it of items) {
      let price = null;
      let currency = null;
      try {
        if (it.url) {
          const r2 = await fetch(it.url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
          if (r2.ok) {
            const page = await r2.text();
            const $$ = cheerio.load(page);
            // Try to parse JSON-LD structured data
            const ld = $$('script[type="application/ld+json"]').map((i, s) => $$(s).html()).get().find(Boolean);
            if (ld) {
              try {
                const j = JSON.parse(ld);
                if (j && j.offers && j.offers.price) {
                  price = j.offers.price;
                  currency = j.offers.priceCurrency || null;
                }
              } catch (e) {
                // ignore JSON parse errors
              }
            }
            // Fallback: search for currency-like patterns in the page text
            if (!price) {
              const match = page.match(/(\d+[,.]?\d*)\s*(TL|TRY|₺|USD|US\$|\$|EUR|€|GBP|£)/i);
              if (match) {
                price = match[1];
                currency = match[2];
              }
            }
          }
        }
      } catch (err) {
        // ignore per-item errors
      }
      detailed.push({ title: it.title, source: 'epic', price, currency, url: it.url });
    }
    return detailed;
  } catch (err) {
    console.warn('Epic fetch error', err && err.message);
    return [];
  }
}

function mergeDeals(steam, epic) {
  const result = [];
  const epicTitles = epic.map(e => e.title);

  for (const s of steam) {
    const best = similarity.findBestMatch(s.title, epicTitles);
    const bestIndex = best.bestMatchIndex;
    const matchScore = best.bestMatch.rating; // 0..1
    if (matchScore > 0.68) {
      const e = epic[bestIndex];
      result.push({ key: s.title.toLowerCase(), steam: s, epic: e, score: matchScore });
    } else {
      result.push({ key: s.title.toLowerCase(), steam: s, epic: null, score: 0 });
    }
  }

  // Add epic-only items
  for (const e of epic) {
    const found = result.find(r => r.epic && r.epic.title === e.title);
    if (!found) result.push({ key: e.title.toLowerCase(), steam: null, epic: e, score: 0 });
  }

  return result;
}

async function run() {
  console.log('Fetching Steam deals...');
  const steam = await fetchSteamDeals();
  console.log('Fetching Epic deals...');
  const epic = await fetchEpicDeals();

  const combined = mergeDeals(steam, epic);
  const out = { fetchedAt: new Date().toISOString(), steamCount: steam.length, epicCount: epic.length, combined };

  await fs.promises.mkdir(path.join(__dirname, 'data'), { recursive: true });
  await fs.promises.writeFile(OUT_PATH, JSON.stringify(out, null, 2), 'utf8');
  console.log('Wrote', OUT_PATH);
  return out;
}

module.exports = { run };

if (require.main === module) {
  run().catch(err => { console.error(err); process.exit(1); });
}
