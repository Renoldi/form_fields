**Overview**

- **Purpose**: Dokumen ini menjelaskan secara detail bagaimana mekanisme pembaruan marker bekerja pada contoh peta, khususnya fungsi `_updateMarkersOnce` di `MapExamplesViewModel`.

**Where to find the code**

- **Main implementation**: [example/lib/ui/pages/map_examples/view_model.dart](example/lib/ui/pages/map_examples/view_model.dart)

**How updates work**

- **Serialize current state**: Kode mengambil snapshot registry marker (`mapController.getRawMarkers()`), menyimpan metadata (`baseHitById`, `basePropsById`) dan membangun `serializable` list yang dikirim ke isolate.
- **Offload to isolate**: Heavy coordinate computation dilakukan di `_computeUpdatedMarkersIsolate` melalui `compute(...)`. Isolate mengembalikan array objek yang berisi salah satu dari:
  - `{'id': <id>, 'deltaLat': ..., 'deltaLon': ...}` (delta kecil untuk patching), atau
  - `{'id': <id>, 'lat': ..., 'lon': ...}` (koordinat absolut), atau
  - `{'pointMetas': [...]}` (full pointMetas untuk marker/polylines).

**Dua jalur utama**

- **Regenerate (buat baru)**
  - Kondisi: jumlah item `computed.length >= regenerateThreshold` (konstanta default 5000).
  - Proses: panggil `mapController.clearRawMarkers()` lalu bangun ulang marker dalam batch dengan `FormFieldsMapController.appendRawMarkers(...)`.
  - ID: usaha dilakukan untuk menjaga `id` asal jika tersedia (`u['id']` atau snapshot `serializable`), sehingga registry akan berisi entri dengan ID yang sama bila snapshot memiliki ID.
  - Metadata (title, properties) direstorasi dari `baseHitById` / `basePropsById`.
- **Update-in-place (patch)**
  - Kondisi: total < threshold.
  - Proses: panggil `mapController.batchUpdateCoordinates(coordsOnly, ...)` dengan payload minimal (`id` + `deltaLat`/`deltaLon` atau `lat`/`lon` atau `pointMetas`).
  - Fallback: jika `batchUpdateCoordinates` gagal, code melakukan per‑item update via `FormFieldsMapController.updateRawMarkerCoordinates(cid, id, pms, ...)`.
  - ID: patch memakai `id` yang sama untuk menarget marker yang ada.

**ID handling**

- Jika snapshot memiliki `id`, kode berupaya untuk menggunakan kembali `id` baik di jalur regenerate maupun update-in-place.
- Jika item tidak memiliki `id` (mis. payload mentah tanpa id), maka marker yang dihasilkan mungkin tidak cocok dengan entri lama — sehingga dianggap sebagai "baru".
- Saat membuat marker baru di generator/append (mis. `generateMarkers`, `generatePolylines`, `generateCircles`), ID biasanya dihasilkan di titik pembuatan (contoh: `m${timestamp}_i`, `l$<timestamp>`, `c$<timestamp>`).

**Konfigurasi penting (di VM)**

- `regenerateThreshold` (hard-coded di `_updateMarkersOnce`): default 5000 — ubah di kode bila butuh.
- `markerUpdateRandomizeCoordinates` (bool): jika `true` isolat mengassign koordinat acak di dalam rentang; jika `false` isolat memberi delta kecil.
- `markerUpdateRandomRangeDegrees` (double): rentang derajat saat `randomize=true`.
- `showVisualMarkerUpdates` (bool): bila `true`, append/regenerate akan membuat widget marker (lebih lambat).
- Batch sizes: `regenBatchSize = 4096`, `batchSize` untuk generate = 4096, delay antar-batch untuk memberi kesempatan UI merespon.

**Performance notes & tips**

- Untuk jumlah marker besar (>= beberapa ribu) gunakan jalur regenerasi lebih cepat daripada patch per-item.
- Matikan `showVisualMarkerUpdates` untuk throughput maksimal (mencegah pembuatan widget pada tiap append).
- Gunakan isolate (`compute`) agar UI tidak tersendat saat menghitung koordinat.
- Jika Anda ingin behavior deterministik untuk testing, set seed di generator/isolate.

**How to run the example**

- Buka folder `example` dan jalankan app Flutter seperti biasa:

```bash
cd example
flutter pub get
flutter run
```

- Di UI contoh, gunakan kontrol `Generate Markers`/`Start Updates` untuk memicu alur.

**FAQ (singkat)**

- Q: "Apakah ID berubah saat regenerasi?"
  - A: Kode berusaha mempertahankan `id` asal apabila tersedia; tetapi karena registry dibersihkan lalu dipopulasi ulang, konsistensi tergantung pada ketersediaan `id` di snapshot.
- Q: "Kenapa kadang marker terlihat hilang lalu muncul lagi?"
  - A: Itu terjadi saat jalur regenerasi: registry dibersihkan lalu di-append ulang dalam batch — tampilan bisa flicker jika `showVisualMarkerUpdates` aktif.

**Next steps / opsi saya bantu**

- Tandai baris kode spesifik untuk `regenerateThreshold`, `batchUpdateCoordinates`, dan `appendRawMarkers` jika ingin saya sorot.
- Ubah `regenerateThreshold` jadi variabel yang bisa dikonfigurasi via VM/setting UI.

---

Terakhir: implementasi utama ada di [example/lib/ui/pages/map_examples/view_model.dart](example/lib/ui/pages/map_examples/view_model.dart). Jika mau, saya bisa menambahkan referensi baris spesifik atau membuat PR perubahan konfigurasi.
