# Perbaikan Flutter dan Backend TernateLomba

## Perubahan pada Flutter (`lib`)

1. `lib/services/api_service.dart`
   - URL API dapat dikonfigurasi dengan `--dart-define=API_BASE_URL=...` tanpa mengubah kode.
   - Respons API diperiksa agar pesan error menampilkan status HTTP dan pesan validasi Laravel.
   - Permintaan formulir memeriksa ID lomba dan struktur JSON sebelum mengolah data.
   - Permintaan jaringan utama diberi batas waktu agar tidak menggantung terus-menerus.

2. `lib/pages/beranda/formulirPesertaPage.dart`
   - Menampilkan pesan error dari API pada layar, bukan hanya teks umum.
   - Memvalidasi ID dan tipe kolom formulir yang diterima dari server.
   - Memperbaiki pemanggilan File Picker menjadi `FilePicker.platform.pickFiles`.
   - Membaca berkas melalui `PlatformFile.bytes` dengan `withData: true`, memeriksa batas 5 MB, lalu mengirim sebagai multipart.

## Perubahan Android

`android/app/src/main/AndroidManifest.xml` sekarang memiliki izin `INTERNET` dan mengizinkan HTTP untuk pengembangan lokal. Untuk rilis produksi, gunakan HTTPS dan tinjau kembali `usesCleartextTraffic`.

## Konfigurasi URL API

Nilai bawaan masih memakai alamat proyek sebelumnya: `http://10.245.39.67:8000/api`.

- Android Emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api`
- HP fisik: `flutter run --dart-define=API_BASE_URL=http://IP_KOMPUTER:8000/api`

Ganti `IP_KOMPUTER` dengan IP LAN komputer yang menjalankan Laravel. Pastikan HP dan komputer berada di jaringan yang dapat saling mengakses. Jalankan Laravel dengan `php artisan serve --host=0.0.0.0 --port=8000`.

## Backend dan database

Backend tetap mengikuti nama kolom database SQL pertama yang diberikan, termasuk `username` dan `biaya`. File `.env` tidak disertakan karena berisi konfigurasi lokal. Pastikan `.env` milik sendiri menggunakan `DB_DATABASE=ternateLomba` dan kredensial MySQL yang benar.

Endpoint formulir yang dipakai Flutter adalah:

`GET /api/lomba/{id_lomba}/form-fields`

Bila masih gagal, lihat pesan error yang tampil di formulir dan periksa `Backend/storage/logs/laravel.log`. Jangan menjalankan `php artisan migrate:fresh` pada database yang berisi data penting.

## Batas verifikasi

Perubahan statis sudah dilakukan pada kode. Pengujian Flutter end-to-end belum dijalankan di lingkungan ini karena Flutter/Dart dan server MySQL aktif tidak tersedia. Setelah diekstrak, jalankan `flutter pub get`, `flutter analyze`, dan uji registrasi, login, daftar lomba, buka formulir, pilih berkas, serta kirim pendaftaran.
