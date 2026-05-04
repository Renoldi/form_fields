# FormFieldsMyImage

Widget untuk memilih, menampilkan, dan mengunggah gambar (atau dokumen) dengan dukungan multi-image, upload langsung, validasi form, serta label yang dapat dikonfigurasi. Mendukung integrasi dengan kamera, galeri, dan scanner dokumen.

---

## Contoh Penggunaan Dasar

```dart
FormFieldsMyImage(
  label: 'Foto Profil',
  maxImages: 1,
  onImageChanged: (image) {
    // Handle single image result
  },
  uploadUrl: 'https://api.example.com/upload',
  uploadToken: 'Bearer your_token',
  isDirectUpload: true,
)
```

## Contoh: Single Image Direct Upload (maxImages: 1)

```dart
FormFieldsMyImage(
  controller: FormFieldsMyImageController(),
  maxImages: 1,
  isDirectUpload: true,
  uploadUrl: 'https://api.example.com/upload',
  uploadFileUrlKey: 'fileUrl',
  uploadImageIdKey: 'imageId',
  onImageChanged: (image) {
    // Pada direct upload, callback ini membawa hasil final.
    // Cek image.link untuk URL file dari server.
    debugPrint('Uploaded link: ${image.link}');
    debugPrint('Image id: ${image.imageId}');
  },
)
```

> Jika `image.link` masih kosong, pastikan response upload memang mengandung key URL sesuai `uploadFileUrlKey`.

---

## Fitur Utama

- Pilihan single (`maxImages: 1`) / multi image
- Upload langsung ke server (opsional)
- **Validasi form** — `isRequired`, `validator`, `autovalidateMode`, `externalErrorText`
- **Label** dengan posisi fleksibel — `top`, `bottom`, `left`, `right`, atau `none`
- Callback perubahan gambar dan penghapusan
- Kustomisasi builder untuk tampilan gambar dan tombol tambah/hapus
- Dukungan scanner dokumen (Cunning Document Scanner)
- Dukungan upload dengan token dan pesan sukses/gagal kustom

---

## Properti

### Core

| Properti     | Tipe                           | Default            | Deskripsi                                        |
| ------------ | ------------------------------ | ------------------ | ------------------------------------------------ |
| `controller` | `FormFieldsMyImageController?` | `null`             | Kontrol eksternal untuk daftar gambar            |
| `maxImages`  | `int?`                         | `null` (unlimited) | Batas jumlah gambar; `1` untuk mode single image |
| `isDoc`      | `bool`                         | `false`            | Aktifkan mode scanner dokumen                    |
| `allow`      | `bool`                         | `true`             | Nonaktifkan interaksi (read-only)                |

### Label

| Properti         | Tipe            | Default              | Deskripsi                                              |
| ---------------- | --------------- | -------------------- | ------------------------------------------------------ |
| `label`          | `String?`       | `null`               | Teks label yang ditampilkan                            |
| `labelPosition`  | `LabelPosition` | `LabelPosition.none` | Posisi label: `top`, `bottom`, `left`, `right`, `none` |
| `labelTextStyle` | `TextStyle?`    | `null`               | Style kustom untuk teks label                          |

> Saat `isRequired: true`, asterisk merah (` *`) otomatis ditambahkan di akhir label.

### Validasi

| Properti            | Tipe                                      | Default             | Deskripsi                                                              |
| ------------------- | ----------------------------------------- | ------------------- | ---------------------------------------------------------------------- |
| `isRequired`        | `bool`                                    | `false`             | Tampilkan error jika tidak ada gambar                                  |
| `validator`         | `String? Function(List<MyimageResult>?)?` | `null`              | Custom validator; kembalikan string error atau `null` jika valid       |
| `autovalidateMode`  | `AutovalidateMode`                        | `onUserInteraction` | Kapan error mulai ditampilkan                                          |
| `externalErrorText` | `String?`                                 | `null`              | Error dari luar (misal: validasi backend); selalu tampil saat non-null |

### Callbacks

| Properti          | Tipe                                       | Deskripsi                                           |
| ----------------- | ------------------------------------------ | --------------------------------------------------- |
| `onImagesChanged` | `void Function(List<MyimageResult>)?`      | Dipanggil setiap kali daftar gambar berubah         |
| `onImageChanged`  | `void Function(MyimageResult)?`            | Dipanggil pada mode single image (`maxImages == 1`) |
| `onRemoveImage`   | `void Function(int index, MyimageResult)?` | Dipanggil saat gambar dihapus                       |

### Upload

| Properti                     | Tipe      | Default     | Deskripsi                             |
| ---------------------------- | --------- | ----------- | ------------------------------------- |
| `uploadUrl`                  | `String?` | `null`      | Endpoint upload                       |
| `uploadToken`                | `String?` | `null`      | Authorization token                   |
| `isDirectUpload`             | `bool`    | `false`     | Upload otomatis saat gambar dipilih   |
| `uploadFileUrlKey`           | `String`  | `'fileUrl'` | Key JSON untuk URL file hasil upload  |
| `uploadImageIdKey`           | `String`  | `'imageId'` | Key JSON untuk ID gambar hasil upload |
| `showUploadResultDialog`     | `bool`    | `false`     | Tampilkan dialog hasil upload         |
| `uploadSuccessTitle/Message` | `String?` |             | Pesan kustom sukses upload            |
| `uploadFailedTitle/Message`  | `String?` |             | Pesan kustom gagal upload             |
| `uploadErrorTitle/Message`   | `String?` |             | Pesan kustom error upload             |

### UI Builders

| Properti            | Tipe                                      | Deskripsi                   |
| ------------------- | ----------------------------------------- | --------------------------- |
| `imageBuilder`      | `Widget Function(context, image, index)?` | Custom tampilan item gambar |
| `removeIconBuilder` | `Widget Function(context, index, image)?` | Custom ikon hapus           |
| `plusBuilder`       | `Widget Function(context)?`               | Custom tombol tambah gambar |

---

## Contoh: Validasi dengan `isRequired`

```dart
FormFieldsMyImage(
  label: 'KTP',
  labelPosition: LabelPosition.top,
  maxImages: 1,
  isRequired: true,
  autovalidateMode: AutovalidateMode.onUserInteraction,
)
```

## Contoh: Custom Validator (multi-image, minimal 2)

```dart
FormFieldsMyImage(
  label: 'Foto Pendukung',
  labelPosition: LabelPosition.top,
  validator: (images) {
    if (images == null || images.length < 2) {
      return 'Minimal 2 foto diperlukan';
    }
    return null;
  },
)
```

## Contoh: Custom Validator (single image, `maxImages: 1`)

Saat `maxImages == 1`, list tetap `List<MyimageResult>?` dengan maksimal satu elemen.

```dart
FormFieldsMyImage(
  label: 'Foto Profil',
  maxImages: 1,
  isRequired: true,               // handles empty case automatically
  validator: (images) {
    // add extra rules if needed (size, type, etc.)
    final img = images?.firstOrNull;
    if (img != null && img.sizeInBytes > 5 * 1024 * 1024) {
      return 'Ukuran gambar maksimal 5 MB';
    }
    return null;
  },
)
```

> **Catatan:** `validator` dijalankan sebelum pengecekan `isRequired`. Jika kamu menyediakan `validator`, tambahkan sendiri pengecekan null/empty di dalamnya, atau andalkan `isRequired: true` saja untuk kasus wajib-isi dasar.

## Contoh: External Error (validasi backend)

```dart
FormFieldsMyImage(
  label: 'Bukti Pembayaran',
  labelPosition: LabelPosition.top,
  externalErrorText: _serverError,   // set after API call
)
```

## Contoh: Integrasi Form

```dart
final _formKey = GlobalKey<FormState>();
final _controller = FormFieldsMyImageController();

Form(
  key: _formKey,
  child: Column(
    children: [
      FormFieldsMyImage(
        controller: _controller,
        label: 'Dokumen Pendukung',
        labelPosition: LabelPosition.top,
        isRequired: true,
        maxImages: 3,
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            // proceed
          }
        },
        child: const Text('Submit'),
      ),
    ],
  ),
)
```

---

Lihat [API.md](../../API.md) untuk detail parameter lengkap.
