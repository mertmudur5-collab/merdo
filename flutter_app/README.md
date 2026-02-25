# Flutter app

Kısa: Basit bir Flutter uygulaması `http` ile backend'den `/deals` çekip gösterir.


Çalıştırma:

```bash
cd flutter_app
flutter pub get
flutter run
```

Firebase entegrasyonu:

1. Firebase console'da yeni bir proje oluşturun.
2. `flutterfire` CLI ile platform konfigürasyonlarını oluşturun ve `firebase_options.dart` dosyasını üretin:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

3. Oluşan `firebase_options.dart` dosyasını `flutter_app/lib/` altında bırakın.
4. Android için `google-services.json`, iOS için `GoogleService-Info.plist` dosyalarını Firebase'den indirin ve projeye ekleyin.
5. Uygulamada Google Sign-In kullanmak için Android/iOS platform ayarlarını Firebase dökümanuna göre yapın.

Backend varsayılan `http://10.0.2.2:3000/deals` adresini kullanır (Android emulator için). Gerçek cihazda backend IP'yi güncelleyin.
