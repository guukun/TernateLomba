# Panduan Perbaikan Poster TernateLomba

## Arsitektur penyimpanan
- MySQL/phpMyAdmin menyimpan referensi file pada `pengajuan_lomba.poster_lomba`.
- File gambar fisik disimpan Laravel pada `Backend/storage/app/public/poster-lomba/`.
- Flutter meminta gambar melalui `GET /api/poster-lomba/{filename}`.
- Laravel mencari nama file pada kolom MySQL, lalu membaca file fisik dari disk `public`.

Database tidak menyimpan file gambar sebagai blob. Database menyimpan path file.

## Perubahan kode
1. `Backend/app/Http/Controllers/PengajuanLombaController.php`
   - Membuat folder `poster-lomba` sebelum penyimpanan.
   - Menyimpan upload ke disk `public`.
   - Memastikan file benar-benar ada sebelum membuat record pengajuan.
   - Mengembalikan pesan error yang lebih spesifik jika penyimpanan gagal.

2. `Backend/app/Http/Controllers/PosterLombaController.php`
   - Mencari referensi gambar pada MySQL.
   - Mendukung format path baru dan path lama.
   - Menolak path traversal.
   - Mengambil file dari disk `public`.
   - Mengirim gambar dengan Content-Type yang benar.

3. `Backend/storage/app/public/poster-lomba/.gitkeep`
   - Memastikan folder tersedia setelah proyek diekstrak atau di-clone.
   - File gambar yang diunggah tidak ikut masuk Git.

## Langkah menjalankan
Buka terminal pada folder `Backend`:

```powershell
php artisan optimize:clear
php artisan route:list --path=poster-lomba
php artisan serve --host=0.0.0.0 --port=8000
```

Tidak perlu mengubah struktur database atau menghapus tabel.

## Periksa data pada phpMyAdmin

```sql
SELECT
    id_pengajuan,
    nama_lomba,
    poster_lomba,
    status_pengajuan
FROM pengajuan_lomba
ORDER BY id_pengajuan DESC;
```

Contoh nilai yang diharapkan:
`poster-lomba/namafile.jpg`

Pastikan file bernama sama tersedia pada:
`Backend/storage/app/public/poster-lomba/namafile.jpg`

## Uji endpoint gambar
Jika database berisi `poster-lomba/namafile.jpg`, buka:

`http://IP-KOMPUTER:8000/api/poster-lomba/namafile.jpg`

Jika gambar tampil di browser, endpoint Laravel berhasil.
Jika 404, periksa pesan 404 dan pastikan referensi MySQL serta file fisiknya cocok.

## Jalankan Flutter
Dari folder utama Flutter:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run
```

Pastikan `API_BASE_URL` di `lib/services/api_service.dart` menunjuk ke komputer yang menjalankan Laravel. Untuk HP fisik, gunakan IP LAN komputer. Untuk Android Emulator standar, gunakan `10.0.2.2`.

## Catatan data lama
Pengajuan yang `poster_lomba`-nya NULL tidak memiliki referensi poster. Pengajuan tersebut perlu mengunggah ulang gambar atau dipulihkan path-nya jika file lama masih tersedia.
