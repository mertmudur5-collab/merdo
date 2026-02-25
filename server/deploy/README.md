# Deploy helper

Bu dizin `deploy_gcloud.sh` script'ini içerir. Script şu işleri yapar:

- `SCRAPE_SECRET` üretir ve `scrapeHttp` fonksiyonuna env var olarak set eder.
- `scrapePubSub` fonksiyonunu (Pub/Sub trigger) deploy eder.
- Pub/Sub topic oluşturur ve Cloud Scheduler job ekler.

Kullanım örneği:

```bash
# tek argüman: GCP project id (opsiyonel)
./deploy_gcloud.sh my-gcp-project us-central1 gamedeals-scrape "0 */6 * * *"
```

Güvenlik notları:
- Script salt bir yardımcıdır; CI'de çalıştırmadan önce secret yönetimini (Secret Manager) kullanmanız önerilir.
- `--quiet` ve hata durumları script'te basitleştirilmiş; production için daha sağlam hata kontrolü ekleyin.
