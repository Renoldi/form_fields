# FormFieldsMyImage

Widget untuk memilih, menampilkan, dan mengunggah gambar (atau dokumen) dengan dukungan multi-image, upload langsung, serta callback perubahan gambar. Mendukung integrasi dengan kamera, galeri, dan scanner dokumen.

## Contoh Penggunaan Dasar

```dart
FormFieldsMyImage(
  label: 'Foto Profil',
  maxImages: 1,
  onImageChanged: (image) {
    // Handle image result
  },
  uploadUrl: 'https://api.example.com/upload',
  uploadToken: 'Bearer your_token',
  isDirectUpload: true,
)
```

## Fitur Utama

- Pilihan single/multi image
- Upload langsung ke server (opsional)
- Callback perubahan gambar dan penghapusan
- Kustomisasi builder untuk tampilan gambar dan tombol tambah/hapus
- Dukungan scanner dokumen (Cunning Document Scanner)
- Dukungan upload dengan token dan pesan sukses/gagal kustom

## Properti Penting

- `controller`: Kontrol eksternal untuk daftar gambar
- `onImagesChanged`, `onImageChanged`, `onRemoveImage`: Callback perubahan
- `plusBuilder`, `imageBuilder`, `removeIconBuilder`: Kustomisasi UI
- `uploadUrl`, `uploadToken`, `isDirectUpload`: Pengaturan upload

Lihat [API.md](../../API.md) untuk detail parameter lengkap.
