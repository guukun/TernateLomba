<?php

namespace App\Http\Controllers;

use App\Models\PengajuanLomba;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class PosterLombaController extends Controller
{
    /**
     * GET /api/poster-lomba/{filename}
     *
     * Alur:
     * 1. Cari referensi poster_lomba di MySQL berdasarkan nama file.
     * 2. Normalisasi path lama dan baru.
     * 3. Baca file fisik dari disk public Laravel.
     *
     * Mendukung nilai database:
     * - poster-lomba/nama-file.jpg
     * - nama-file.jpg (format data lama)
     * - storage/poster-lomba/nama-file.jpg
     * - storage/app/public/poster-lomba/nama-file.jpg
     * - public/storage/poster-lomba/nama-file.jpg
     */
    public function show(string $filename): BinaryFileResponse
    {
        $filename = rawurldecode($filename);
        $filename = str_replace('\\', '/', $filename);
        $safeFilename = basename($filename);

        if (
            $safeFilename !== $filename ||
            !preg_match('/^[A-Za-z0-9._-]+\.(jpg|jpeg|png)$/i', $safeFilename)
        ) {
            abort(404, 'Nama file poster tidak valid.');
        }

        // Ambil referensi dari MySQL. Pemeriksaan basename juga mendukung
        // path lama yang menggunakan backslash atau URL lengkap.
        $records = PengajuanLomba::query()
            ->whereNotNull('poster_lomba')
            ->where('poster_lomba', '<>', '')
            ->get(['id_pengajuan', 'poster_lomba']);

        $pengajuan = $records->first(function (PengajuanLomba $item) use ($safeFilename): bool {
            $value = trim((string) $item->poster_lomba);

            if (filter_var($value, FILTER_VALIDATE_URL)) {
                $value = (string) parse_url($value, PHP_URL_PATH);
            }

            $value = str_replace('\\', '/', $value);
            $value = rawurldecode($value);

            return strcasecmp(basename($value), $safeFilename) === 0;
        });

        if (!$pengajuan) {
            abort(404, 'Referensi poster tidak ditemukan pada kolom pengajuan_lomba.poster_lomba.');
        }

        $storedPath = trim((string) $pengajuan->poster_lomba);

        if (filter_var($storedPath, FILTER_VALIDATE_URL)) {
            $storedPath = (string) parse_url($storedPath, PHP_URL_PATH);
        }

        $storedPath = rawurldecode(str_replace('\\', '/', $storedPath));
        $storedPath = ltrim($storedPath, '/');

        // Hilangkan prefix yang mungkin tersimpan pada data lama.
        $prefixes = [
            'storage/app/public/',
            'app/public/',
            'public/storage/',
            'storage/',
            'public/',
        ];

        foreach ($prefixes as $prefix) {
            if (str_starts_with(strtolower($storedPath), strtolower($prefix))) {
                $storedPath = substr($storedPath, strlen($prefix));
                break;
            }
        }

        $segments = explode('/', $storedPath);
        if (
            $storedPath === '' ||
            in_array('..', $segments, true) ||
            in_array('.', $segments, true) ||
            basename($storedPath) !== $safeFilename
        ) {
            abort(404, 'Path poster pada database tidak valid.');
        }

        $disk = Storage::disk('public');

        // Prioritaskan path persis dari database. Tambahkan lokasi umum untuk
        // kompatibilitas dengan data lama yang hanya menyimpan nama file.
        $candidates = array_values(array_unique([
            $storedPath,
            'poster-lomba/' . $safeFilename,
            $safeFilename,
        ]));

        foreach ($candidates as $relativePath) {
            if (!$disk->exists($relativePath)) {
                continue;
            }

            $absolutePath = $disk->path($relativePath);

            if (!is_file($absolutePath) || !is_readable($absolutePath)) {
                continue;
            }

            $mimeType = $disk->mimeType($relativePath) ?: 'application/octet-stream';

            if (!in_array(strtolower($mimeType), [
                'image/jpeg',
                'image/png',
            ], true)) {
                abort(404, 'File yang dirujuk bukan gambar JPG atau PNG.');
            }

            return response()->file($absolutePath, [
                'Content-Type' => $mimeType,
                'Content-Disposition' => 'inline; filename="' . $safeFilename . '"',
                'Cache-Control' => 'public, max-age=3600',
                'X-Content-Type-Options' => 'nosniff',
            ]);
        }

        abort(404, 'Referensi poster ada di database, tetapi file tidak ditemukan di storage/app/public.');
    }
}
