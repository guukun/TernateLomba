# Perbaikan alur upload dan tampilan poster TernateLomba

## Temuan dari kode proyek
1. Flutter memilih gambar dengan `image_picker`, menyimpan `XFile` di `_poster`, lalu menampilkan preview dari bytes.
2. `ApiService.ajukanLomba()` mengirim `poster_lomba` melalui `http.MultipartRequest` sebagai multipart file.
3. Laravel memvalidasi `poster_lomba` sebagai image JPG/JPEG/PNG maksimal 5 MB.
4. Laravel menyimpan file ke disk `public` pada folder `storage/app/public/poster-lomba/`.
5. Path relatif disimpan pada kolom `pengajuan_lomba.poster_lomba`.
6. API katalog, detail, pengajuan milik user, dan admin sudah menyertakan `poster_lomba`.
7. Halaman Beranda, Detail Lomba, Lomba Saya, Admin Pengajuan, dan Detail Admin menggunakan helper URL gambar.

## Perbaikan teknis
- Ditambahkan endpoint publik `GET /api/poster-lomba/{filename}`.
- Endpoint membaca file langsung dari disk Laravel `public` dan mengirimkannya sebagai gambar.
- Flutter `ApiService.publicStorageUrl()` sekarang membentuk URL ke endpoint tersebut.
- Akses poster tidak lagi bergantung pada symbolic link `public/storage`.
- Respons upload, daftar pengajuan, katalog lomba, dan riwayat pendaftaran juga menyertakan `poster_url` untuk inspeksi/debugging.
- Nama field database tetap `poster_lomba`. Tidak ada perubahan skema database.

## Lokasi file diubah
### Flutter
- `lib/services/api_service.dart`

Semua halaman yang sudah menggunakan `ApiService.publicStorageUrl()` otomatis memakai endpoint baru:
- `lib/pages/beranda/homePage.dart`
- `lib/pages/beranda/detailLombaPage.dart`
- `lib/pages/admin/pengajuanPage.dart`
- `lib/pages/admin/detailPengajuanPage.dart`
- `lib/pages/lombaSaya/lombaSayaPage.dart`

### Laravel
- `routes/api.php`
- `app/Http/Controllers/PosterLombaController.php` (baru)
- `app/Http/Controllers/PengajuanLombaController.php`
- `app/Http/Controllers/LombaController.php`
- `app/Http/Controllers/PendaftaranController.php`

## Jalankan setelah mengganti proyek
Di folder Backend:
```powershell
php artisan optimize:clear
php artisan route:list --path=poster-lomba
php artisan serve --host=0.0.0.0 --port=8000
```

Di folder Flutter:
```powershell
flutter clean
flutter pub get
flutter analyze
flutter run
```

`php artisan storage:link` tidak lagi menjadi syarat untuk menampilkan poster melalui endpoint API baru. Perintah itu masih boleh dijalankan untuk akses langsung file publik lainnya.

## Pemeriksaan database
Jalankan SQL berikut:
```sql
SELECT
    id_pengajuan,
    nama_lomba,
    poster_lomba,
    status_pengajuan
FROM pengajuan_lomba
ORDER BY id_pengajuan DESC;
```

Untuk setiap baris dengan `poster_lomba` terisi, pastikan file yang sama ada di:
`Backend/storage/app/public/<nilai poster_lomba>`

Contoh:
- Database: `poster-lomba/abc123.jpg`
- File: `Backend/storage/app/public/poster-lomba/abc123.jpg`
- URL gambar: `http://IP-KOMPUTER:8000/api/poster-lomba/abc123.jpg`

## Uji endpoint gambar
Salin nama file dari kolom `poster_lomba`, lalu buka URL endpoint di browser:
`http://IP-KOMPUTER:8000/api/poster-lomba/NAMA-FILE.jpg`

Hasil yang benar adalah browser menampilkan gambar, bukan JSON 404 atau halaman error.

## Catatan untuk data lama
Data lomba lama yang kolom `poster_lomba`-nya `NULL` atau kosong tidak mempunyai referensi gambar. Perbaikan kode tidak dapat membuat gambar lama secara otomatis. Poster harus diunggah ulang atau path yang benar harus dimasukkan jika file aslinya memang masih tersedia.

## Status pemeriksaan
- Sintaks PHP pada route dan controller terkait diperiksa dengan `php -l`.
- Flutter/Dart analyzer tidak tersedia pada lingkungan pembuatan ZIP. Jalankan `flutter analyze` di komputer pengembang.
- Pengujian upload dan tampilan gambar secara langsung memerlukan server Laravel dan database milik pengguna.
