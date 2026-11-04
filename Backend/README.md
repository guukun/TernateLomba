# Backend TernateLomba

Backend API aplikasi TernateLomba menggunakan Laravel dan database MariaDB/MySQL.

## Kebutuhan

- PHP 8.3 atau lebih baru yang kompatibel dengan versi Laravel pada `composer.json`.
- Composer.
- MySQL atau MariaDB.
- Ekstensi PHP `pdo_mysql`, `mbstring`, `openssl`, `fileinfo`, `curl`, dan `gd` atau `exif` sesuai kebutuhan pemrosesan gambar.

## 1. Siapkan database

1. Buat database bernama `ternateLomba`.
2. Impor dump SQL asli proyek yang disediakan.
3. Pastikan tabel `users`, `kategori_lomba`, `pengajuan_lomba`, `lomba`, `form_field`, `pendaftaran`, dan `jawaban_pendaftaran` sudah tersedia.

Database proyek menggunakan skema khusus. Jangan menjalankan migrasi Laravel standar yang membuat tabel `users` bawaan Laravel karena kolomnya berbeda dari skema proyek.

## 2. Siapkan konfigurasi Laravel

Jalankan dari folder `Backend`:

```bash
composer install
cp .env.example .env
php artisan key:generate
```

Pada Windows Command Prompt, salin `.env.example` menjadi `.env` menggunakan File Explorer atau perintah:

```bat
copy .env.example .env
```

Sesuaikan konfigurasi database pada `.env` dengan komputer masing-masing:

```dotenv
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ternateLomba
DB_USERNAME=root
DB_PASSWORD=
```

Nama database mengikuti dump SQL asli. Jika MySQL dijalankan pada server berbeda, sesuaikan `DB_HOST`, nama pengguna, dan kata sandi.

## 3. Jalankan API

```bash
php artisan optimize:clear
php artisan serve --host=0.0.0.0 --port=8000
```

Uji endpoint koneksi melalui browser atau alat API:

```text
GET http://127.0.0.1:8000/api/tes-koneksi
```

Untuk Flutter pada perangkat lain, gunakan alamat IP LAN komputer yang menjalankan Laravel, bukan `127.0.0.1` atau `localhost`. Pastikan perangkat dan komputer berada pada jaringan yang dapat saling mengakses dan firewall mengizinkan port 8000.

## 4. Alur autentikasi

- `POST /api/register`: membuat akun. Body JSON memuat `username`, `password`, dan `password_confirmation`.
- `POST /api/login`: memverifikasi akun dan mengembalikan token API.
- Database menyimpan hash token di `api_token_hash`, bukan token asli.
- Token berlaku selama 30 hari dan disimpan pada klien untuk dikirim melalui header `Authorization: Bearer <token>`.
- `POST /api/logout`: menghapus token aktif pengguna.

Token `NULL` setelah registrasi adalah kondisi yang diharapkan. Token baru dibuat saat login, mengikuti alur Flutter saat ini.

Skema database hanya menyediakan satu token aktif per akun. Login baru akan mengganti token sebelumnya untuk akun tersebut.

## 5. Endpoint API

| Metode | Endpoint | Akses |
|---|---|---|
| GET | `/api/tes-koneksi` | Publik |
| POST | `/api/register` | Publik |
| POST | `/api/login` | Publik |
| GET | `/api/profile-photo/{filename}` | Publik, hanya file gambar yang valid |
| GET | `/api/kategori` | Publik |
| GET | `/api/lomba` | Publik |
| GET | `/api/lomba/{id}` | Publik |
| GET | `/api/lomba/{id}/form-fields` | Publik |
| GET | `/api/users` | Token |
| PUT | `/api/profile` | Token |
| POST | `/api/profile/foto` | Token |
| POST | `/api/logout` | Token |
| POST | `/api/lomba/{id}/pendaftaran` | Token |
| GET | `/api/pendaftaran/riwayat` | Token |
| GET | `/api/pendaftaran/{id}` | Token, hanya pemilik pendaftaran |
| GET | `/api/pendaftaran/{id}/jawaban/{idJawaban}/file` | Token, hanya pemilik pendaftaran |

## 6. Penyimpanan berkas

- Foto profil disimpan pada disk `public` di `storage/app/public/profile-photos`.
- Berkas pendaftaran disimpan pada disk `local` di `storage/app/private/pendaftaran` dan hanya dapat diunduh melalui endpoint terautentikasi.
- Jangan mengubah berkas pendaftaran menjadi tautan publik karena dapat berisi data peserta.

## 7. Pemeriksaan kode

Periksa daftar route:

```bash
php artisan route:list --path=api
```

Jalankan pengujian:

```bash
php artisan test
```

Pengujian integrasi database memerlukan database proyek yang sudah diimpor dan konfigurasi `.env` yang benar.
