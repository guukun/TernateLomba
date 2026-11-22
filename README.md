<div align="center">

# TERNATELOMBA

**MONO EDITION — LOCK IN.**

*Temukan lomba. Ambil kesempatan. Mulai berkompetisi.*

![Flutter](https://img.shields.io/badge/Flutter-Dart-171717?style=flat-square&logo=flutter&logoColor=white)
![Laravel](https://img.shields.io/badge/Laravel-PHP-171717?style=flat-square&logo=laravel&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-MySQL-171717?style=flat-square&logo=mariadb&logoColor=white)

</div>

---

## Tentang Proyek

**TernateLomba** adalah platform informasi dan pengelolaan perlombaan yang memudahkan pengguna menemukan lomba, mendaftar sebagai peserta, serta mengajukan dan menyelenggarakan kompetisi. Aplikasi dibuat dengan antarmuka **Mono Edition** yang minimalis, responsif, dan berfokus pada kemudahan penggunaan.

## Fitur Utama

| Peran | Fitur |
|:--|:--|
| **Pengguna** | Registrasi/login, jelajah lomba, kategori dan favorit, pendaftaran, riwayat, notifikasi, pengelolaan profil |
| **Penyelenggara** | Pengajuan lomba, formulir pendaftaran dinamis, pengelolaan peserta, keputusan pendaftaran, ruang chat lomba |
| **Administrator** | Verifikasi pengajuan, kelola kategori, pantau pengguna/lomba, batalkan atau hentikan lomba jika diperlukan |

**Status lomba** mengikuti jadwal pendaftaran dan pelaksanaan secara otomatis. Pengguna dapat berkomunikasi melalui chat sesuai hak aksesnya.

## Teknologi

| Bagian | Teknologi |
|:--|:--|
| Frontend | Flutter, Dart |
| Backend/API | Laravel 13, PHP 8.3+ |
| Database | MariaDB / MySQL |
| Autentikasi | Token API |
| Platform pengembangan utama | Flutter Web |

## Struktur Proyek

```text
TernateLomba/
├── assets/                 # Aset aplikasi
├── lib/                    # Source Flutter
│   ├── pages/              # Halaman aplikasi
│   ├── navigation/         # Navigasi
│   ├── services/           # Komunikasi API
│   └── widgets/            # Komponen UI
├── test/                   # Pengujian Flutter
├── Backend/                # REST API Laravel
│   ├── app/                # Controller, model, service
│   ├── routes/             # Endpoint API
│   └── database/
│       └── ternatelomba.sql # Skema dan kategori awal
└── pubspec.yaml
```

## Menjalankan di Komputer Sendiri

### Persyaratan

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi kompatibel dengan `pubspec.yaml`; proyek memakai Dart 3.13+)
- [PHP](https://www.php.net/) **8.3+** dan [Composer](https://getcomposer.org/)
- MariaDB/MySQL serta phpMyAdmin atau klien SQL lain
- Browser untuk Flutter Web (Chrome direkomendasikan)

### 1 — Clone repository

```bash
git clone https://github.com/guukun/TernateLomba.git
cd TernateLomba
```

### 2 — Siapkan database

Buat **database baru yang kosong** bernama `ternatelomba` (gunakan `utf8mb4`), lalu impor file:

```text
Backend/database/ternatelomba.sql
```

File ini berisi **12 tabel dan 4 kategori awal**, tanpa akun, token, atau data pengguna. **Jangan impor ke database yang sudah berisi data**, karena skrip ini ditujukan untuk instalasi baru.

### 3 — Konfigurasi dan jalankan Laravel

Dari folder `Backend`:

```bash
cd Backend
composer install
cp .env.example .env
php artisan key:generate
```

Atur koneksi database di `Backend/.env` sesuai komputer masing-masing:

```dotenv
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=ternatelomba
DB_USERNAME=root
DB_PASSWORD=
```

Lalu jalankan:

```bash
php artisan optimize:clear
php artisan serve --host=127.0.0.1 --port=8000
```

Buka [`http://127.0.0.1:8000/api/tes-koneksi`](http://127.0.0.1:8000/api/tes-koneksi) untuk mengecek API. Biarkan terminal ini berjalan.

> **Catatan:** Database menggunakan skema SQL khusus. **Jangan menjalankan `php artisan migrate` atau `migrate:fresh`** pada database ini. Di Windows Command Prompt, gunakan `copy .env.example .env` sebagai pengganti `cp`.

### 4 — Jalankan Flutter Web

Buka terminal baru dari **folder utama** `TernateLomba`:

```bash
flutter pub get
flutter run -d chrome
```

Secara default, frontend mengakses `http://127.0.0.1:8000/api`. Jika API berjalan di perangkat/port berbeda, sesuaikan saat menjalankan Flutter:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

### 5 — Buat akun dan Administrator

Daftarkan akun melalui halaman registrasi. Semua akun baru memiliki role **User**. Untuk menetapkan satu akun sebagai **Administrator** pada instalasi lokal, jalankan query berikut melalui phpMyAdmin setelah akun dibuat:

```sql
UPDATE users
SET role = 'Administrator'
WHERE username = 'username_admin_yang_sudah_didaftarkan';
```

Ganti nilai `username_admin_yang_sudah_didaftarkan` dengan username yang benar. Login ulang untuk membuka fitur Administrator. Jangan memasukkan akun maupun password pribadi ke file SQL publik.

## Pengujian

```bash
# Dari root proyek
flutter analyze
flutter test

# Dari Backend/
cd Backend
php artisan test
```

## Tim Pengembang

**Teguh · Nisa · Putry · Adit · Lina · Valdo**

## Lisensi

Lisensi proyek ditetapkan berdasarkan persetujuan seluruh anggota tim. Untuk menjadikannya open source dengan izin penggunaan dan modifikasi yang jelas.

---

<div align="center"><strong>LOCK IN. FIND YOUR COMPETITION.</strong></div>
