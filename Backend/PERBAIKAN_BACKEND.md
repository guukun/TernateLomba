# Ringkasan Perbaikan Backend TernateLomba

Perubahan dibuat berdasarkan kode backend asli dan dump SQL pertama `ternateLomba`. Skema database tidak diubah.

## Perbaikan

1. Memisahkan autentikasi (`AuthController`) dan profil (`ProfileController`) dari closure di `routes/api.php`.
2. Mempertahankan kontrak endpoint yang digunakan Flutter, termasuk nama `username`, status enum dengan kapitalisasi asli, kolom `biaya`, dan tipe formulir `Text`/`File`.
3. Menambahkan metode `PendaftaranController::detail()` karena route detail sebelumnya memanggil metode yang tidak ada.
4. Memperketat pemeriksaan akses detail dan unduhan berkas agar hanya pemilik pendaftaran yang dapat mengaksesnya.
5. Memperbaiki pemeriksaan kuota agar menggunakan data pengajuan yang dimuat dalam transaksi, serta membersihkan berkas yang sudah tersimpan jika transaksi gagal.
6. Menambahkan validasi ketika formulir lomba belum dikonfigurasi atau berkas gagal disimpan.
7. Menambahkan cast waktu kedaluwarsa token dan menyembunyikan hash token dari serialisasi model.
8. Menyesuaikan factory dan seeder dengan tabel `users` khusus proyek, bukan kolom bawaan Laravel `name`/`email`.
9. Menyamakan nama database di `.env.example` menjadi `ternateLomba` dan memakai driver file/sync untuk session, cache, dan queue agar tidak memerlukan tabel pendukung yang tidak ada pada dump SQL.
10. Menambahkan pembatasan permintaan sederhana pada endpoint login dan registrasi.
11. Menambahkan dokumentasi setup dan pengujian endpoint koneksi.

## Catatan autentikasi

Registrasi hanya membuat akun. Token API diterbitkan setelah login, sehingga `api_token_hash` dan `api_token_expires_at` bernilai `NULL` sebelum login. Saat login, server mengembalikan token asli kepada Flutter dan hanya menyimpan hash-nya di database.

## Validasi yang telah dilakukan

- Seluruh file PHP di folder aplikasi, konfigurasi, route, seeder, factory, dan test diperiksa dengan `php -l` dan tidak ditemukan kesalahan sintaks.
- Pengujian Laravel penuh belum dapat dijalankan di lingkungan penyuntingan ini karena folder `vendor` belum tersedia dan Composer tidak terpasang. Jalankan `composer install` lalu `php artisan test` di komputer pengembangan.
- Tidak ada perubahan pada Flutter atau dump SQL dalam paket backend ini.


## Pengajuan lomba dari Flutter

- Endpoint `POST /api/pengajuan-lomba` memerlukan token Bearer aktif.
- Data pengajuan disimpan dengan `status_pengajuan = Menunggu`; admin perlu menyetujui sebelum lomba muncul di katalog.
- Poster bersifat opsional dan disimpan di disk `public` pada folder `poster-lomba`.
- Untuk mengakses berkas publik di Laravel, jalankan `php artisan storage:link` satu kali pada lingkungan server.
