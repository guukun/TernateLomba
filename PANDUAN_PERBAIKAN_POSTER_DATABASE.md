# Perbaikan alur poster berbasis database

## Prinsip
MySQL menyimpan referensi/path pada `pengajuan_lomba.poster_lomba`.
File gambar fisik disimpan oleh Laravel pada `storage/app/public`.
Flutter mengambil data lomba dari API dan meminta gambar ke endpoint Laravel.

Alur:
1. Flutter mengirim `poster_lomba` sebagai multipart file.
2. Laravel memvalidasi file, menyimpannya pada disk `public`, lalu menyimpan path ke MySQL.
3. API katalog/admin/riwayat mengembalikan nilai `poster_lomba`.
4. Flutter membentuk URL `/api/poster-lomba/{filename}`.
5. `PosterLombaController` mencari record MySQL berdasarkan path poster, lalu mengirim file gambar dari disk public.

## Perubahan
- Poster diwajibkan pada formulir pengajuan agar pengajuan baru tidak menghasilkan `poster_lomba = NULL`.
- Flutter selalu mengirim file sebagai multipart.
- Laravel memvalidasi file sebagai JPG/JPEG/PNG maksimal 5 MB.
- Laravel memverifikasi file benar-benar ada setelah disimpan.
- Endpoint poster membaca referensi path dari tabel `pengajuan_lomba`, bukan mengasumsikan semua path selalu berada di `poster-lomba/`.
- Mendukung path lama seperti `nama-file.jpg` dan path baru `poster-lomba/nama-file.jpg`.
- Tidak ada perubahan skema database.

## Lokasi penyimpanan
File fisik:
`Backend/storage/app/public/poster-lomba/`

Contoh nilai MySQL:
`poster-lomba/abc123.jpg`

Contoh URL:
`http://IP-KOMPUTER:8000/api/poster-lomba/abc123.jpg`

## Jalankan
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

## Verifikasi MySQL melalui phpMyAdmin
```sql
SELECT id_pengajuan, nama_lomba, poster_lomba, status_pengajuan
FROM pengajuan_lomba
ORDER BY id_pengajuan DESC;
```

Jika `poster_lomba` bernilai NULL, pengajuan lama tersebut memang tidak mempunyai referensi poster.
Jika path terisi, pastikan file dengan nama tersebut ada pada public storage Laravel.

## Catatan data lama
Perbaikan ini mencegah pengajuan baru tanpa poster. Data lama yang `poster_lomba`-nya NULL tidak bisa dibuatkan gambar secara otomatis. Unggah ulang poster atau pulihkan file aslinya dan path-nya.
