# Panduan agar poster lomba tampil di semua halaman

Perubahan ini mempertahankan skema database dan nama kolom `poster_lomba`.

## Alur gambar
1. Form Ajukan Lomba memilih JPG/JPEG/PNG dan menampilkan preview sebelum dikirim.
2. Flutter mengirim gambar sebagai multipart field `poster_lomba`.
3. Laravel menyimpan gambar pada disk `public` di folder `poster-lomba/`.
4. Endpoint katalog/detail lomba, daftar pengajuan admin, daftar pengajuan milik user, dan riwayat pendaftaran mengirim path `poster_lomba`.
5. Flutter membentuk URL publik dari `API_BASE_URL` dan menampilkan gambar pada Beranda, Detail Lomba, Admin Verifikasi, Detail Pengajuan Admin, Lomba Dibuat, dan Lomba Diikuti.

## Wajib dilakukan pada backend
Jalankan dari folder `Backend`:
```bash
php artisan storage:link
php artisan optimize:clear
```
Pastikan `Backend/.env` menggunakan `APP_URL` yang dapat diakses perangkat. Untuk HP fisik, gunakan IP LAN komputer. Jangan memakai `localhost` pada URL yang dikirim ke HP.

Contoh:
```env
APP_URL=http://192.168.1.10:8000
```
Sesuaikan alamat dengan IP komputer sendiri. `API_BASE_URL` Flutter juga harus memakai host yang sama:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

## Pemeriksaan
- Folder file: `Backend/storage/app/public/poster-lomba/`
- URL publik: `http://HOST:8000/storage/poster-lomba/NAMA_FILE.jpg`
- Uji URL tersebut dari browser HP. Jika gambar tidak terbuka, periksa symbolic link `Backend/public/storage`, permission folder, dan host API.

Tidak ada migrasi database yang diperlukan.
