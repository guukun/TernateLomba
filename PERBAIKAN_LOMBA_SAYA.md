# Perbaikan Fitur Lomba Saya

## Fitur
- Tab `Lomba Diikuti` tetap menampilkan riwayat pendaftaran peserta.
- Tab `Lomba Dibuat` mengambil pengajuan milik akun yang sedang login dari Laravel.
- Daftar menampilkan nama lomba, kategori, tanggal pelaksanaan, tanggal pengajuan, status verifikasi, dan catatan admin jika tersedia.
- Daftar dapat ditarik ke bawah untuk diperbarui dan menyediakan tombol coba lagi jika API gagal.
- Setelah pengajuan berhasil dikirim, aplikasi otomatis membuka `Lomba Saya` pada tab `Lomba Dibuat` dan memuat ulang data.
- Pengguna hanya dapat melihat pengajuan miliknya karena backend memfilter berdasarkan `id_user` dari token autentikasi.

## Endpoint baru
`GET /api/pengajuan-lomba/saya`

Endpoint ini berada dalam middleware `AuthenticateApiToken`, sehingga harus dipanggil dengan header:
`Authorization: Bearer <token>`

## File utama yang diubah
- `Backend/routes/api.php`
- `Backend/app/Http/Controllers/PengajuanLombaController.php`
- `lib/services/api_service.dart`
- `lib/pages/lombaSaya/lombaSayaPage.dart`
- `lib/pages/ajukan/ajukanPage.dart`
- `lib/navigation/mainPage.dart`

## Menjalankan
1. Pastikan `Backend/.env` menunjuk ke database `ternateLomba` yang sudah ada.
2. Jalankan `php artisan optimize:clear` di folder `Backend`.
3. Jalankan Laravel menggunakan alamat yang dapat dijangkau Flutter.
4. Dari folder Flutter jalankan `flutter pub get` lalu `flutter run`.
5. Kirim pengajuan baru. Setelah sukses, halaman akan berpindah ke `Lomba Saya > Lomba Dibuat`.

Tidak ada perubahan skema database atau migration baru pada perbaikan ini.
