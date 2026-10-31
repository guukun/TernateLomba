# Perbaikan fitur Ajukan Lomba

## Penyebab sebelumnya

Tombol `Mulai Pengajuan Lomba` pada `lib/pages/ajukan/ajukanPage.dart` menggunakan `onPressed: () {}` sehingga tidak menjalankan aksi. Backend juga belum memiliki endpoint untuk menyimpan pengajuan lomba.

## Perubahan

- Tombol Ajukan membuka `FormAjukanLombaPage`.
- Token login dari `MainPage` diteruskan ke halaman formulir.
- Formulir memuat kategori dari `GET /api/kategori`.
- Formulir memvalidasi data lomba, tanggal, biaya, kuota, dan kontak.
- Poster JPG/JPEG/PNG bersifat opsional, maksimal 5 MB.
- Flutter mengirim data melalui `POST /api/pengajuan-lomba` dengan header `Authorization: Bearer <token>`.
- Laravel memvalidasi input, mengambil `id_user` dari token aktif, menyimpan pengajuan dengan status `Menunggu`, dan menyimpan poster ke disk `public`.
- Skema database asli dipertahankan. Kolom yang dipakai adalah `biaya`, bukan `biaya_pendaftaran`.

## Menjalankan

1. Cadangkan proyek lama.
2. Ekstrak ZIP dan pastikan `.env` backend mengarah ke database `ternateLomba`.
3. Di folder `Backend`, jalankan:

   ```bash
   php artisan optimize:clear
   php artisan storage:link
   php artisan serve --host=0.0.0.0 --port=8000
   ```

4. Di folder Flutter, jalankan:

   ```bash
   flutter pub get
   flutter run
   ```

5. Pastikan `API_BASE_URL` mengarah ke komputer server. Untuk Android Emulator standar gunakan `http://10.0.2.2:8000/api`; untuk HP fisik gunakan IP LAN komputer.

## Catatan

- Pengguna harus login karena endpoint pengajuan dilindungi token API.
- Pengajuan baru berstatus `Menunggu`. Pengajuan tidak langsung muncul di katalog lomba sampai admin menyetujuinya dan membuat/mengaktifkan data lomba sesuai alur admin.
- Sintaks PHP diperiksa dengan `php -l`. Pengujian end-to-end Flutter, Laravel, dan MySQL tetap perlu dilakukan di lingkungan lokal.
