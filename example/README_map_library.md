README — Form Fields Map Library (Example)

Tujuan

- Menyediakan panduan terperinci cara menggunakan API peta dari paket `form_fields` yang digunakan dalam contoh aplikasi.

Ringkasan

- File contoh utama: `example/lib/ui/pages/map_examples/view_model.dart` — mengandung pola penggunaan `FormFieldsMapController` dan `MapController`.
- Fitur yang didokumentasikan:
  - Menambahkan marker, polyline, polygon, circle
  - Pembaruan periodik marker (in-place vs regenerasi)
  - Penggunaan batch append / update untuk performa
  - Opsi konfigurasi penting dan tips performa

Prasyarat

- Flutter SDK terpasang
- Jalankan contoh dari folder `example` dengan `flutter run` pada device/emulator

Contoh ringkasan API

- Dapatkan `controllerId` dari `MapController`: `FormFieldsMapController.getIdForController(mapController)`
- Append markers (batch): `FormFieldsMapController.appendRawMarkers(controllerId, batch)`
- Update koordinat (batch): `mapController.batchUpdateCoordinates(coords)`
- Update koordinat per item: `FormFieldsMapController.updateRawMarkerCoordinates(controllerId, id, pointMetas)`
- Clear semua marker: `mapController.clearRawMarkers()`

Marker generation dan update

- Generate besar: gunakan `_generateMarkersIsolate` + `appendRawMarkers` dalam batch (lihat `generateMarkers` di `view_model.dart`).
- Pembaruan periodik: `_updateMarkersOnce()` melakukan:
  1. Serialize snapshot dari registry (preserve `hit` dan `properties` untuk setiap `id`).
  2. Offload hitungan/delta ke isolate `_computeUpdatedMarkersIsolate`.
  3. Jika hasil lebih dari `regenerateThreshold` (default 5000) maka:
     - Clear registry lalu rekonstruksi marker lewat `appendRawMarkers` (regenerasi / "buat baru").
  4. Jika kurang dari threshold maka:
     - Lakukan `mapController.batchUpdateCoordinates(...)` (update-in-place) atau fallback per-item via `updateRawMarkerCoordinates`.

ID handling

- Jika `ShapeMeta.id` tersedia, library akan mempertahankan `id` saat regenerasi (dipertahankan dari snapshot sebelum clear). Jika `id` tidak ada, regenerasi akan membuat entry baru tanpa jaminan ID sama.

Konfigurasi penting (ditemukan di `view_model.dart`)

- `regenerateThreshold` (default 5000): batas jumlah untuk memilih regenerasi vs update-in-place.
- `markerUpdateRandomizeCoordinates`: jika `true`, pembaruan menghasilkan koordinat acak; jika `false`, hanya nudge kecil.
- `markerUpdateRandomRangeDegrees`: rentang random ketika `markerUpdateRandomizeCoordinates=true`.
- `showVisualMarkerUpdates`: jika `true`, buat widget marker saat append/update agar terlihat di UI (membuat operasi lebih lambat).

Tips performa

- Gunakan batch append (`appendRawMarkers`) untuk menambah ribuan marker sekaligus.
- Nonaktifkan `showVisualMarkerUpdates` untuk throughput terbesar.
- Pertimbangkan `regenerateThreshold` lebih kecil jika ingin menghindari potensi flicker pada clear/re-append.

Link ke kode contoh

- Lihat implementasi di `example/lib/ui/pages/map_examples/view_model.dart` untuk alur penuh dan detail implementasi.

Langkah-langkah menjalankan contoh

1. Buka terminal pada folder `example`.
2. Jalankan `flutter pub get`.
3. Jalankan `flutter run`.

Jika Anda mau, saya bisa:

- Menambahkan tautan baris di README ke lokasi kode spesifik, atau
- Membuat versi ringkasan untuk README utama paket.

Code references (important lines in the example)

- `regenerateThreshold` (decides regenerate vs update-in-place): [example/lib/ui/pages/map_examples/view_model.dart](example/lib/ui/pages/map_examples/view_model.dart#L600)
- `FormFieldsMapController.appendRawMarkers(...)` used during regeneration (clear+append): [example/lib/ui/pages/map_examples/view_model.dart](example/lib/ui/pages/map_examples/view_model.dart#L715)
- `mapController.batchUpdateCoordinates(...)` used for update-in-place (batch patch): [example/lib/ui/pages/map_examples/view_model.dart](example/lib/ui/pages/map_examples/view_model.dart#L775)
- Marker id generation in `compute` generator (`_generateMarkersIsolate`): [example/lib/ui/pages/map_examples/view_model.dart](example/lib/ui/pages/map_examples/view_model.dart#L1091)
- Example marker id pattern (per-marker id): [example/lib/ui/pages/map_examples/view_model.dart](example/lib/ui/pages/map_examples/view_model.dart#L1110)
- Playback polyline id creation: [example/lib/ui/pages/map_examples/view_model.dart](example/lib/ui/pages/map_examples/view_model.dart#L994)
- Circle id creation example: [example/lib/ui/pages/map_examples/view_model.dart](example/lib/ui/pages/map_examples/view_model.dart#L1058)

These links point to the in-repo example implementation so you can quickly inspect the exact code paths mentioned in this guide.
