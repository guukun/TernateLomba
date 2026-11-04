<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\LombaController;
use App\Http\Controllers\PendaftaranController;
use App\Http\Controllers\PengajuanLombaController;
use App\Http\Controllers\PosterLombaController;
use App\Http\Controllers\ProfileController;
use App\Http\Middleware\AuthenticateApiToken;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\NotifikasiController;

// Endpoint publik.
Route::get('/tes-koneksi', function () {
    return response()->json([
        'pesan' => 'Flutter berhasil terhubung ke Laravel',
    ]);
});

Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:5,1');
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
Route::get('/profile-photo/{filename}', [ProfileController::class, 'photo']);

// Katalog lomba dapat dibaca tanpa login.
Route::get('/kategori', [LombaController::class, 'kategori']);
Route::get('/lomba', [LombaController::class, 'index']);
Route::get('/lomba/{id}', [LombaController::class, 'show'])->whereNumber('id');
Route::get('/poster-lomba/{filename}', [PosterLombaController::class, 'show'])
    ->where('filename', '[^/]+');
Route::get('/lomba/{id}/form-fields', [PendaftaranController::class, 'formFields'])
    ->whereNumber('id');

// Endpoint yang memerlukan token API aktif.
Route::middleware(AuthenticateApiToken::class)->group(function () {
    Route::get('/users', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::post('/profile/foto', [ProfileController::class, 'uploadPhoto']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Pengajuan lomba milik pengguna yang sedang login.
    Route::get('/pengajuan-lomba/saya', [PengajuanLombaController::class, 'mine']);
    Route::post('/pengajuan-lomba', [PengajuanLombaController::class, 'store']);

    // Endpoint khusus administrator untuk memeriksa dan memutuskan pengajuan.
    Route::get('/admin/pengajuan-lomba', [PengajuanLombaController::class, 'adminIndex']);
    Route::patch('/admin/pengajuan-lomba/{id}/keputusan', [PengajuanLombaController::class, 'decide'])
        ->whereNumber('id');

    Route::post('/lomba/{id}/pendaftaran', [PendaftaranController::class, 'store'])
        ->whereNumber('id');
    Route::get('/pendaftaran/riwayat', [PendaftaranController::class, 'riwayat']);
    Route::get('/pendaftaran/{id}', [PendaftaranController::class, 'detail'])
        ->whereNumber('id');
    Route::get(
        '/pendaftaran/{id}/jawaban/{idJawaban}/file',
        [PendaftaranController::class, 'unduhJawabanFile']
    )->whereNumber('id')->whereNumber('idJawaban');

    // NOTIFIKASI
    Route::get('/notifikasi', [NotifikasiController::class, 'index']);

    Route::get('/notifikasi/unread-count', [NotifikasiController::class, 'unreadCount']);

    Route::patch('/notifikasi/{id}/read', [NotifikasiController::class, 'markAsRead']);

    Route::patch('/notifikasi/read-all', [NotifikasiController::class, 'markAllAsRead']);

    Route::delete('/notifikasi/{id}', [NotifikasiController::class, 'destroy']);
});