# Integrasi flutter_foreground_task (iOS & Android)

Panduan ini menjelaskan langkah-langkah detail untuk mengintegrasikan `flutter_foreground_task` pada contoh aplikasi (iOS dan Android), termasuk perubahan file, potongan kode, dan langkah verifikasi.

Catatan penting:

- Perubahan berikut dibuat di repo contoh: `AndroidManifest.xml`, `AppDelegate.swift`, `Runner-Bridging-Header.h`, dan `Info.plist`.

-- Sekilas perubahan yang diperlukan

- Android:
  - Pastikan deklarasi `<service>` berada di dalam elemen `<application>` pada `android/app/src/main/AndroidManifest.xml`.
  - Tambahkan permission yang diperlukan (mis. `FOREGROUND_SERVICE`).

- iOS:
  - Tambahkan entri `BGTaskSchedulerPermittedIdentifiers` dan `UIBackgroundModes` di `ios/Runner/Info.plist`.
  - Tambahkan `#import <flutter_foreground_task/FlutterForegroundTaskPlugin.h>` ke `ios/Runner/Runner-Bridging-Header.h` (jika menggunakan Objective-C bridge).
  - Update `ios/Runner/AppDelegate.swift` untuk mendaftarkan callback plugin pada background engine.

## iOS — Detail langkah per file

1. `ios/Runner/Info.plist`

Tambahkan entri berikut ke dalam `<dict>` agar task background dapat berjalan:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.pravera.flutter_foreground_task.refresh</string>
</array>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
</array>
```

2. `ios/Runner/Runner-Bridging-Header.h`

Jika belum ada, file bridging header diperlukan untuk mengimpor plugin Swift ke project Objective-C. Tambahkan baris:

```objc
#import <flutter_foreground_task/FlutterForegroundTaskPlugin.h>
```

3. `ios/Runner/AppDelegate.swift` (Swift)

Contoh perubahan utama (Swift):

```swift
import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Daftarkan callback plugin untuk background engine
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Jika proyek Anda menggunakan Objective-C `AppDelegate`, gunakan contoh Objective-C yang setara (lihat dokumentasi plugin). Jika menggunakan Swift + Objective-C bridging, pastikan `Runner-Bridging-Header.h` mengimpor plugin header.

4. Pembatasan iOS

- Jika pengguna 'force close' aplikasi dari recent apps, task akan dihentikan segera.
- Task tidak dapat dijalankan otomatis pada boot seperti Android.
- Task berjalan di background ~30 detik setiap ~15 menit (bisa lebih lama karena pembatasan iOS).

## Android — Detail langkah per file

1. `android/app/src/main/AndroidManifest.xml`

- Permissions: pastikan ada permission berikut (contoh):

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

- Deklarasi `service` harus berada di dalam `<application>`:

```xml
<application ...>
    <!-- other entries -->
    <service
        android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
        android:foregroundServiceType="dataSync|remoteMessaging"
        android:exported="false" />
</application>
```

Catatan: Pada kasus awal build error, sumber masalah umum adalah meletakkan `<service>` di luar `<application>` (AAPT akan menolak elemen tak terduga di dalam `<manifest>`).

## Verifikasi & Build

Langkah singkat untuk memverifikasi integrasi:

```bash
# dari folder example
flutter pub get

# jalankan pada perangkat iOS (device, bukan simulator untuk background fetch)
flutter run -d <device-id>

# build release/ipa
flutter build ios --release

# untuk Android
flutter build apk
```

Catatan: Untuk menguji background fetch pada iOS, gunakan perangkat nyata dan gunakan Xcode > Debug > Simulate Background Fetch, atau perintah `BGTaskScheduler` pada device jika perlu.

## Contoh ringkas perubahan yang telah dibuat di repo ini

- `android/app/src/main/AndroidManifest.xml` — pindah `<service>` ke dalam `<application>` dan pastikan permission.
- `example/ios/Runner/Info.plist` — tambahkan `BGTaskSchedulerPermittedIdentifiers` + `UIBackgroundModes`.
- `example/ios/Runner/Runner-Bridging-Header.h` — import `FlutterForegroundTaskPlugin.h`.
- `example/ios/Runner/AppDelegate.swift` — daftarkan callback plugin untuk background engine.

## Troubleshooting singkat

- Jika build Android gagal dengan pesan AAPT `unexpected element <service> found in <manifest>`, pastikan service berada di dalam `<application>`.
- Jika plugin tidak terdaftar pada background engine (foreground task gagal menjalankan kode Dart), pastikan `setPluginRegistrantCallback` dipanggil dan `GeneratedPluginRegistrant.register(with:)` memanggil semua plugin yang diperlukan.

---

Jika Anda mau, saya bisa juga menambahkan skrip verifikasi otomatis kecil atau checklist di `example/tool` untuk memeriksa file-file kunci ini.
