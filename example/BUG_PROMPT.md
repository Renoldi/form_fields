# Bug Report / Debug Prompt

Gunakan prompt ini (salin & tempel) saat menanyakan ke tim/issue tracker agar mereka mendapat semua data yang dibutuhkan untuk debugging force-close.

## Judul singkat

Aplikasi force-close saat background isolate / Workmanager dijalankan

## Reproduksi singkat

1. Perangkat / emulator: [Android / iOS — model & OS version]
2. Flutter channel & versi: [hasil `flutter --version`]
3. Langkah:
   - Jalankan: `flutter run -d <device>`
   - (Opsional) Jalankan tugas background: tekan tombol "Start All" / atau biarkan scheduler jalan
   - Waktu crash: [timestamp]

## Perilaku yang diharapkan

app tetap berjalan / background handler selesai

## Perilaku aktual

app force-closes / Lost connection to device / engine gagal buat isolate

## Log yang saya lampirkan (pastekan output di bawah)

1. Hasil `flutter run` atau `flutter logs` dari saat crash (sertakan stack trace penuh)
2. Untuk Android: lampirkan `adb logcat -d > logcat.txt` (atau setidaknya baris error)
3. Untuk iOS: lampirkan Crash log dari Console / Xcode Organizer atau `flutter logs`
4. Teks error spesifik yang muncul (contoh yang saya lihat):
   - "[ERROR:flutter/runtime/dart_isolate.cc(886)] Could not resolve main entrypoint function."
   - "[ERROR:flutter/runtime/dart_isolate.cc(177)] Could not run the run main Dart entrypoint."
   - Any Dart stacktrace lines (pakai markup/code block)

## Potongan kode relevan (paste bagian ini)

- `example/lib/main.dart` — bagian `main()` dan pemanggilan `FormFieldsInitializer.initAll(...)`
- `lib/src/service/workmanager_service.dart` — top-level `workmanagerCallbackDispatcher` / initialize
- `lib/src/service/init_service.dart` — bagaimana `workmanagerCallbackDispatcher` dipass ke `initAll`
- Jika ada: handler top-level yang didaftarkan (mis. `@pragma('vm:entry-point') workmanagerFlushBackgroundHandler`)

## Dependensi & versi

- `pubspec.yaml` (atau `pubspec.lock`)
- output `flutter doctor -v`

## Informasi tambahan

- Apakah `initAll(..., workmanagerCallbackDispatcher: workmanagerCallbackDispatcher)` dipanggil atau tidak?
- Apakah kita mengekspor `workmanagerCallbackDispatcher` dari package (ya/tidak)
- Apakah crash terjadi saat startup (immediate) atau beberapa detik setelah scheduling / runOnce?
- Apakah ini hanya terjadi di iOS / Android / keduanya?

## Permintaan spesifik ke reviewer

- Tolong cek stacktrace dan tunjukkan baris kode/file yang menyebabkan isolate gagal resolve entrypoint.
- Jika perlu, minta saya untuk menyalin potongan kode tertentu atau menjalankan command tambahan.

---

Contoh singkat yang bisa Anda kirim:

> Halo, app saya force-close saat Workmanager/foreground adapter mencoba menjalankan background isolate. Saya sudah melampirkan log dan potongan kode di bawah. Bisa tolong cek apakah masalahnya pada:
>
> - callback dispatcher tidak terdaftar/di-export sehingga callback handle tidak bisa di-resolve, atau
> - pekerjaan dijalankan terlalu dini pada iOS sehingga platform belum siap?
>
> Log utama:
> [paste stacktrace / error lines here]
>
> Kode relevan:
>
> - main.dart initAll call:
>   [pasang 5–20 baris kode di sini]
> - workmanager_service.dart dispatcher export:
>   [pasang fungsi dispatcher di sini]
>
> Env & versi:
>
> - Flutter: [hasil flutter --version]
> - Plugins: [workmanager vX, flutter_foreground_task vY, background_fetch vZ]
>
> Terima kasih — saya bisa menambahkan output `adb logcat` / `flutter logs` jika diperlukan.
