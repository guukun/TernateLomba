# Perbaikan verifikasi pengajuan lomba oleh Admin

## Alur
1. Pengguna mengirim pengajuan. Status awal `Menunggu`.
2. Admin dengan role `Administrator` membuka menu **Verifikasi** pada navigasi bawah.
3. Admin melihat seluruh pengajuan dan dapat memilih **Terima** atau **Tolak**.
4. Admin dapat menambahkan catatan. Catatan penolakan disarankan diisi agar alasan terlihat oleh pengaju.
5. Jika diterima, backend mengubah `status_pengajuan` menjadi `Disetujui` dan membuat record pada tabel `lomba` dengan `status_lomba = Aktif`.
6. Jika ditolak, backend mengubah status menjadi `Ditolak` dan menyimpan `catatan_admin`.
7. Pengaju melihat status dan catatan admin pada tab **Lomba Dibuat**.

## Endpoint baru
- `GET /api/admin/pengajuan-lomba`
- `PATCH /api/admin/pengajuan-lomba/{id}/keputusan`

Keduanya memerlukan Bearer token dan memeriksa role `Administrator` di controller. Keputusan hanya dapat diberikan pada pengajuan yang masih `Menunggu`.

## Database
Tidak ada perubahan skema. Menggunakan kolom dan enum pada database awal:
- `pengajuan_lomba.status_pengajuan`: `Menunggu`, `Disetujui`, `Ditolak`
- `pengajuan_lomba.catatan_admin`
- `lomba.status_lomba`: `Aktif`, `Draft`, `Selesai`

## Menjalankan
Di folder `Backend`:
```bash
php artisan optimize:clear
php artisan route:list --path=admin/pengajuan-lomba
php artisan serve --host=0.0.0.0 --port=8000
```
Di folder Flutter:
```bash
flutter pub get
flutter analyze
flutter run
```

Pastikan akun admin memiliki `users.role = 'Administrator'` pada database. Jangan mengubah role dari aplikasi publik.
