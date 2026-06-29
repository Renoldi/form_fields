# FCM Platform Setup (Android & iOS)

Panduan langkah-demi-langkah untuk mendaftarkan Firebase Cloud Messaging (FCM) ke aplikasi Flutter pada contoh repo ini.

Ikuti setiap bagian secara berurutan dan pastikan Anda menjalankan build pada perangkat nyata untuk pengujian push.

---

## Ringkasan singkat

- Tempatkan file konfigurasi platform yang didownload dari Firebase Console:
  - Android: `google-services.json` → contoh path: [example/android/app/](example/android/app/)
  - iOS: `GoogleService-Info.plist` → contoh path: [example/ios/Runner/](example/ios/Runner/)
- Daftarkan `fcmBackgroundHandler` (top-level function) sebelum `runApp()` menggunakan helper paket: `FCMService.registerBackgroundHandler(fcmBackgroundHandler);`
- Panggil `await FCMService.instance.initialize(...)` setelah `Firebase.initializeApp()` dan sebelum `runApp()`.

Referensi implementasi contoh startup: [example/lib/main.dart](example/lib/main.dart)

---

## 1) Daftarkan aplikasi di Firebase Console

1. Buka https://console.firebase.google.com/ dan buat atau pilih project.
2. Tambah aplikasi Android:
   - Masukkan Android package name (lihat `example/android/app/src/main/AndroidManifest.xml`).
   - Ikuti wizard, unduh `google-services.json` dan simpan ke folder `example/android/app/`.
3. Tambah aplikasi iOS:
   - Masukkan iOS bundle identifier (lihat `example/ios/Runner/Info.plist`).
   - Unduh `GoogleService-Info.plist` dan simpan ke folder `example/ios/Runner/`.

Catatan: jangan commit file Firebase config ke VCS jika berisi kredensial produksi; gunakan secrets management.

---

## 2) Android — langkah konfig tambahan

1. Tambahkan dependency plugin Google Services pada `example/android/build.gradle` (project level):

```groovy
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
  }
}
```

2. Terapkan plugin pada `example/android/app/build.gradle` (app level) di bagian akhir file:

```groovy
apply plugin: 'com.google.gms.google-services'
```

3. Pastikan `minSdkVersion` memenuhi persyaratan plugin yang Anda gunakan (lihat dokumentasi `firebase_messaging`).

4. Tambahkan icon notifikasi kecil (small icon) di `example/android/app/src/main/res/drawable/` dan gunakan di inisialisasi notifikasi Android (`@mipmap/ic_launcher` dipakai oleh contoh).

5. Runtime permission (Android 13+):
   - Minta `POST_NOTIFICATIONS` saat runtime. Contoh: paket `permission_handler` dipakai di contoh.

6. Sync dan build:

```bash
cd example
flutter pub get
flutter build apk
```

---

## 3) iOS — langkah konfig tambahan

1. Buka Xcode, pilih target `Runner` → Signing & Capabilities:
   - Aktifkan **Push Notifications**.
   - Aktifkan **Background Modes** dan centang **Remote notifications**.

2. Upload APNs key ke Firebase Console (Project Settings → Cloud Messaging) untuk mengizinkan FCM mengirim ke perangkat iOS.

3. Tambahkan `GoogleService-Info.plist` ke `example/ios/Runner/` dan pastikan file termasuk ke target `Runner` di Xcode.

4. Pastikan platform iOS di `example/ios/Podfile` setidaknya ke versi yang direkomendasikan (mis. platform :ios, '11.0' atau lebih tinggi).

5. Instal pods & build:

```bash
cd example/ios
pod install
cd ..
flutter pub get
flutter build ios --no-codesign
```

Catatan: iOS push hanya bekerja pada perangkat nyata (tidak pada simulator).

---

## 4) Integrasi di kode Flutter (contoh pola yang direkomendasikan)

Letakkan inisialisasi FCM di awal `main()` sebelum `runApp()`.

Contoh urutan (lihat [example/lib/main.dart](example/lib/main.dart)):

```dart
WidgetsFlutterBinding.ensureInitialized();
// app config (env, DB, logging)
await Firebase.initializeApp();

// Daftarkan top-level background handler (harus top-level fn)
FCMService.registerBackgroundHandler(fcmBackgroundHandler);

// Inisialisasi helper FCM (foreground handlers, local notifications)
await FCMService.instance.initialize(
  options: const FCMOptions(showLocalNotification: true),
  onMessage: (msg) async { /* handle */ },
  onMessageOpenedApp: (msg) async { /* handle tap */ },
);

// Ambil token dan simpan
final token = await FCMService.instance.getToken();
// persist token ke SharedPreferences / AppState

// Dengarkan token refresh
FCMService.registerOnTokenRefresh((newToken) async {
  // simpan token baru
});

runApp(const MyApp());
```

Catatan penting:

- `fcmBackgroundHandler` harus berupa fungsi top-level (tidak boleh nested/anonim).
- Daftarkan handler background **sebelum** proses background berjalan (mis. sebelum worker yang memicu notifikasi).

---

## 5) Mengirim pesan uji

- Gunakan Firebase Console → Cloud Messaging → Send your first message, kirim ke device token.
- Atau gunakan skrip yang disertakan di `example/tools/`:
  - `example/tools/send_fcm_test.dart` — contoh menggunakan legacy server key.
  - `example/tools/send_fcm_v1.js` — contoh HTTP v1 (direkomendasikan untuk produksi) menggunakan service account.

Contoh curl (legacy):

```bash
curl -X POST -H "Authorization: key=YOUR_SERVER_KEY" -H "Content-Type: application/json" \
 -d '{"to":"<DEVICE_TOKEN>","notification":{"title":"Test","body":"Hello"}}' \
 https://fcm.googleapis.com/fcm/send
```

---

## 6) Keamanan & praktek terbaik

- Jangan commit `google-services.json` / `GoogleService-Info.plist` untuk kredensial produksi.
- Gunakan HTTP v1 + OAuth2 service account atau backend yang aman untuk mengirim pesan produksi.
- Simpan token perangkat secara aman dan rotasi di server bila perlu.

---

## 7) Troubleshooting singkat

- Tidak menerima push iOS: pastikan APNs key di-upload, capability Push Notifications aktif, dan device bukan simulator.
- Token nil: cek log untuk `FCMService.instance.getToken()` dan pastikan Firebase diinisialisasi.
- Background handler tidak berjalan: handler harus top-level dan didaftarkan via `FCMService.registerBackgroundHandler` sebelum `runApp()`.

---

Jika Anda mau, saya bisa:

- Tambahkan checklist otomatis pada `example/README.md` yang merujuk ke file ini, atau
- Menambahkan template `.gitignore` entry dan skrip helper untuk menyalin file platform dari lokasi terproteksi ke folder `example/` sebelum build.

File yang relevan di repo: [example/lib/main.dart](example/lib/main.dart), [lib/src/service/fcm_service.dart](lib/src/service/fcm_service.dart)
