#!/usr/bin/env bash
# Simple deploy helper for Google Cloud Functions + Scheduler
set -euo pipefail

PROJECT=${1:-}
REGION=${2:-us-central1}
TOPIC=${3:-gamedeals-scrape}
SCHEDULE=${4:-"0 */6 * * *"}

if [ -n "$PROJECT" ]; then
  gcloud config set project "$PROJECT"
fi

echo "Using project: $(gcloud config get-value project)" >&2
echo "Region: $REGION" >&2

cd "$(dirname "$0")/.." || exit 1

echo "Generating SCRAPE_SECRET..."
SCRAPE_SECRET=$(openssl rand -hex 16)
echo "Secret generated"

if command -v gcloud >/dev/null 2>&1; then
  echo "Creating Secret Manager secret 'gamedeals-scrape-secret' (if not exists)"
  gcloud secrets create gamedeals-scrape-secret --data-file=<(echo -n "$SCRAPE_SECRET") --replication-policy=automatic || \
    (echo "Secret exists or creation failed; updating latest version" && echo -n "$SCRAPE_SECRET" | gcloud secrets versions add gamedeals-scrape-secret --data-file=-)

  SECRET_RESOURCE="projects/$(gcloud config get-value project)/secrets/gamedeals-scrape-secret/versions/latest"
  echo "Deploying HTTP function (scrapeHttp) with SCRAPE_SECRET_NAME env var pointing to Secret Manager"
  gcloud functions deploy scrapeHttp \
    --source=./functions --runtime=nodejs18 --region=$REGION \
    --trigger-http --entry-point=scrapeHttp \
    --set-env-vars=SCRAPE_SECRET_NAME="$SECRET_RESOURCE" --quiet
else
  echo "gcloud not found — falling back to plain env var deploy"
  gcloud functions deploy scrapeHttp \
    --source=./functions --runtime=nodejs18 --region=$REGION \
    --trigger-http --entry-point=scrapeHttp \
    --set-env-vars=SCRAPE_SECRET="$SCRAPE_SECRET" --quiet
fi

echo "Deploying Pub/Sub function (scrapePubSub)..."
gcloud functions deploy scrapePubSub \
  --source=./functions --runtime=nodejs18 --region=$REGION \
  --trigger-topic=$TOPIC --entry-point=scrapePubSub --quiet || true

echo "Creating Pub/Sub topic (if not exists): $TOPIC"
gcloud pubsub topics create $TOPIC --quiet || true

echo "Creating Scheduler job to publish to topic: schedule=$SCHEDULE"
JOB_NAME=gamedeals-scrape-job
gcloud scheduler jobs create pubsub $JOB_NAME \
  --schedule="$SCHEDULE" --topic=$TOPIC \
  --message-body='{"run":"now"}' --time-zone="UTC" --quiet || true

echo
echo "Done. Use the following to call the HTTP function:"
HTTP_URL=$(gcloud functions describe scrapeHttp --region=$REGION --format='value(httpsTrigger.url)')
echo "curl -H \"Authorization: Bearer $SCRAPE_SECRET\" $HTTP_URL"

echo
echo "Store the secret securely (e.g., Secret Manager) instead of printing in CI." 
