<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seeder default sengaja tidak membuat akun otomatis.
     * Struktur users proyek ini berbeda dari skema bawaan Laravel.
     * Buat akun melalui endpoint POST /api/register atau tambahkan
     * seeder khusus proyek jika data awal memang dibutuhkan.
     */
    public function run(): void
    {
        // Tidak ada data awal yang wajib dibuat.
    }
}
