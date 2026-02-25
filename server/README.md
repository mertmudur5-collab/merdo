# Server (indirim toplayıcı)

Bu basit Express sunucusu `GET /deals` endpoint'i sağlar. Steam için `featuredcategories` örneği kullanır ve Epic için örnek scraping içerir.

Local çalıştırma:

```bash
cd server
npm install
npm start
```

Notlar:
- Epic verisi için scraping yerine güvenilir backend endpointleri veya resmi entegrasyon tercih edin.

Cloud Functions / Scheduler deploy (örnek - Google Cloud)

1) GCP projesinde şu API'leri etkinleştirin: Cloud Functions, Cloud Scheduler, Pub/Sub, Cloud Build.

2) `server/functions` dizininde fonksiyonları deploy edebilirsiniz. Aşağıdaki örnekler Node 18 varsayar.

HTTP trigger ile manuel tetikleme (hızlı test):

Güvenlik önerisi: HTTP fonksiyonunu herkese açık bırakmayın. Ya IAM ile erişimi sınırlayın ya da fonksiyon için bir `SCRAPE_SECRET` ortam değişkeni belirleyip isteklerde `Authorization: Bearer <secret>` header'ı isteyin.

Örnek (secret ile; fonksiyon istekte bu secret'i doğrular):

```bash
cd server/functions
npm install
gcloud functions deploy scrapeHttp \
	--runtime=nodejs18 --region=us-central1 \
	--trigger-http --entry-point=scrapeHttp \
	--set-env-vars=SCRAPE_SECRET="$(openssl rand -hex 16)"

Or Secret Manager ile daha güvenli yöntem (önerilir):

1. Secret oluşturun (veya CI'de versiyon ekleyin):

```bash
gcloud secrets create gamedeals-scrape-secret --replication-policy=automatic
echo -n "$SECRET_VALUE" | gcloud secrets versions add gamedeals-scrape-secret --data-file=-
```

2. Fonksiyona bu secret'in resource adını verin ve fonksiyon çalışma zamanında Secret Manager'dan okunacak:

```bash
SECRET_RESOURCE="projects/$(gcloud config get-value project)/secrets/gamedeals-scrape-secret/versions/latest"
gcloud functions deploy scrapeHttp \
	--runtime=nodejs18 --region=us-central1 \
	--trigger-http --entry-point=scrapeHttp \
	--set-env-vars=SCRAPE_SECRET_NAME="$SECRET_RESOURCE" --no-allow-unauthenticated
```

3. Fonksiyonun service account'una secret erişimi verin (Secret Manager Accessor rolü):

```bash
gcloud secrets add-iam-policy-binding gamedeals-scrape-secret \
	--member=serviceAccount:YOUR_FUNCTION_SA_EMAIL --role=roles/secretmanager.secretAccessor
```
```

Sonra fonksiyonu şu şekilde çağırabilirsiniz:

```bash
curl -H "Authorization: Bearer <your-secret-value>" https://REGION-PROJECT.cloudfunctions.net/scrapeHttp
```

IAM ile sınırlamak isterseniz `--no-allow-unauthenticated` kullanıp, sadece belirli service account'lara invoke yetkisi verin:

```bash
# deploy without public access
gcloud functions deploy scrapeHttp \
	--runtime=nodejs18 --region=us-central1 \
	--trigger-http --entry-point=scrapeHttp --no-allow-unauthenticated

# grant invoke permission to a service account (ör. scheduler SA)
gcloud functions add-iam-policy-binding scrapeHttp \
	--region=us-central1 --member=serviceAccount:YOUR_SCHEDULER_SA_EMAIL --role=roles/cloudfunctions.invoker
```

Pub/Sub trigger (Cloud Scheduler ile periyodik):

```bash
# 1. deploy Pub/Sub-triggered function
gcloud functions deploy scrapePubSub \
	--runtime=nodejs18 --region=us-central1 \
	--trigger-topic=gamedeals-scrape --entry-point=scrapePubSub

# 2. create scheduler job to publish to topic every 6 hours (example)
gcloud scheduler jobs create pubsub gamedeals-scrape-job \
	--schedule="0 */6 * * *" \
	--topic=gamedeals-scrape \
	--message-body='{"run":"now"}' --time-zone="UTC"
```

Güvenlik notu: `--allow-unauthenticated` kullandığınızda HTTP fonksiyonu herkese açık olur; production için IAM veya bir doğrulama mekanizması kullanın.

