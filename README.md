# sosyal_app

Supabase kullanan Flutter sosyal medya uygulaması.

## Mac'te devam etme

Bu proje Android emülatöründe Flutter **3.38.10** ile derlenip çalıştırıldı.
Aynı sürümü kullanın; daha yeni Flutter sürümleri Android Gradle ayarlarının
güncellenmesini gerektirebilir.

1. Depoyu klonlayın veya mevcut kopyada `git pull` çalıştırın.
2. Proje kökünde `.env.example` dosyasını `.env` adıyla kopyalayın:

   ```sh
   cp .env.example .env
   ```

3. `.env` içine Supabase proje URL'sini ve publishable anahtarını ekleyin.
   Kod publishable anahtarını `SUPABASE_ANON_KEY` adıyla okur.
   Secret/service role anahtarını eklemeyin: bu dosya uygulamaya dahil edilir.
   Yerel `.env` dosyası Git'e gönderilmez.
4. Paketleri hazırlayıp bir cihazda çalıştırın:

   ```sh
   flutter pub get
   flutter devices
   flutter run -d <cihaz-kimliği>
   ```

Android için Android Studio, Android SDK ve bir emülatör veya bağlı telefon gerekir.
iOS için Xcode, komut satırı araçları ve gerekli CocoaPods kurulumu gerekir;
iOS derlemesi henüz doğrulanmadı.

Windows emülatöründeki klavye sorunu, Android'in el yazısı girişi kapatılarak
çözüldü. Bu emülatör ayarı Git ile taşınmaz.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
