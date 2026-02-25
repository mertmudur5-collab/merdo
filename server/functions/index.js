const fetchModule = require('../fetch_and_save');
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');

const secretClient = new SecretManagerServiceClient();

async function ensureSecretLoaded() {
  // If SCRAPE_SECRET already in env, nothing to do.
  if (process.env.SCRAPE_SECRET) return;

  // If SCRAPE_SECRET_NAME provided (e.g. projects/../secrets/NAME/versions/latest), fetch it
  const name = process.env.SCRAPE_SECRET_NAME;
  if (!name) return;
  try {
    const [accessResponse] = await secretClient.accessSecretVersion({ name });
    const payload = accessResponse.payload && accessResponse.payload.data && accessResponse.payload.data.toString('utf8');
    if (payload) {
      process.env.SCRAPE_SECRET = payload;
      console.log('Loaded SCRAPE_SECRET from Secret Manager');
    }
  } catch (err) {
    console.error('Failed to load secret from Secret Manager:', err && err.message);
  }
}

// HTTP-triggered cloud function (useful for manual or authenticated triggers)
exports.scrapeHttp = async (req, res) => {
  await ensureSecretLoaded();

  // Optional secret-based auth: set SCRAPE_SECRET env var or SCRAPE_SECRET_NAME when deploying.
  const secret = process.env.SCRAPE_SECRET;
  if (secret) {
    const authHeader = req.get('authorization') || req.get('x-functions-secret') || '';
    const token = authHeader.replace(/^Bearer\s+/i, '');
    if (!token || token !== secret) {
      return res.status(401).json({ ok: false, error: 'Unauthorized' });
    }
  }

  try {
    const out = await fetchModule.run();
    return res.status(200).json({ ok: true, resultCount: out.combined.length, fetchedAt: out.fetchedAt });
  } catch (err) {
    console.error('scrapeHttp error', err && err.message);
    return res.status(500).json({ ok: false, error: err && err.message });
  }
};

// Pub/Sub-triggered cloud function — suitable for Cloud Scheduler -> Pub/Sub
exports.scrapePubSub = async (message, context) => {
  await ensureSecretLoaded();
  try {
    await fetchModule.run();
    console.log('scrapePubSub finished');
  } catch (err) {
    console.error('scrapePubSub error', err && err.message);
    throw err;
  }
};
