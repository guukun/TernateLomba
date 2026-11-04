# Perbaikan formulir pendaftaran TernateLomba

Perubahan pada paket ini:

1. Backend `FormField` menormalkan `tipe_field` agar `Text`/`File` dan `text`/`file` diperlakukan sama saat dibaca.
2. Model `Lomba` dan `PengajuanLomba` menormalkan kapitalisasi status untuk pemeriksaan di PHP.
3. Flutter menerima kapitalisasi tipe formulir yang berbeda.
4. Jika permintaan formulir gagal, Flutter sekarang menampilkan pesan kesalahan dari API agar penyebabnya bisa diketahui.
5. Backend yang disertakan adalah backend yang telah dirapikan sebelumnya. Database tidak diubah oleh paket ini.

## Langkah setelah menyalin file

1. Cadangkan folder proyek saat ini.
2. Ekstrak proyek ini, atau salin folder `Backend` dan `lib` ke proyekmu.
3. Pastikan `Backend/.env` menunjuk ke database awal `ternateLomba`.
4. Jalankan dari folder Backend: `php artisan optimize:clear`.
5. Jalankan Laravel dan Flutter kembali.
6. Buka formulir. Jika masih gagal, baca pesan merah yang sekarang tampil di layar dan periksa `Backend/storage/logs/laravel.log`.

Endpoint formulir: `GET /api/lomba/{id_lomba}/form-fields`. Dengan data contoh dari SQL awal, endpoint yang diuji adalah `/api/lomba/1/form-fields`.
