<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\LombaController;
use App\Http\Controllers\NotifikasiController;
use App\Http\Controllers\PendaftaranController;
use App\Http\Controllers\PengajuanLombaController;
use App\Http\Controllers\PosterLombaController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\PenyelenggaraLombaController;
use App\Http\Middleware\AuthenticateApiToken;
use Illuminate\Support\Facades\Route;

// ==========================================
// ENDPOINT PUBLIK
// ==========================================

Route::get('/tes-koneksi', function () {
    return response()->json([
        'pesan' => 'Flutter berhasil terhubung ke Laravel',
    ]);
});

Route::post('/register', [AuthController::class, 'register'])
    ->middleware('throttle:5,1');

Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle:10,1');

Route::get('/profile-photo/{filename}', [
    ProfileController::class,
    'photo'
]);

// ==========================================
// KATALOG LOMBA PUBLIK
// ==========================================

Route::get('/kategori', [
    LombaController::class,
    'kategori'
]);

Route::get('/lomba', [
    LombaController::class,
    'index'
]);

Route::get('/lomba/{id}', [
    LombaController::class,
    'show'
])->whereNumber('id');

Route::get('/poster-lomba/{filename}', [
    PosterLombaController::class,
    'show'
])->where('filename', '[^/]+');

Route::get('/lomba/{id}/form-fields', [
    PendaftaranController::class,
    'formFields'
])->whereNumber('id');

// File jawaban peserta menggunakan signed URL berumur 10 menit.
Route::get('/penyelenggara/pendaftaran/{id}/jawaban/{idJawaban}/file', [
    PenyelenggaraLombaController::class,
    'downloadFile',
])->whereNumber('id')->whereNumber('idJawaban')
  ->middleware('signed')
  ->name('penyelenggara.pendaftaran.file');

// ==========================================
// ENDPOINT YANG MEMERLUKAN TOKEN API AKTIF
// ==========================================

Route::middleware(AuthenticateApiToken::class)->group(function () {

    // NOTIFIKASI PENGGUNA
    Route::get('/notifikasi', [NotifikasiController::class, 'index']);
    Route::patch('/notifikasi/{id}/baca', [NotifikasiController::class, 'read'])->whereNumber('id');
    Route::patch('/notifikasi/baca-semua', [NotifikasiController::class, 'readAll']);
    Route::delete('/notifikasi/{id}', [NotifikasiController::class, 'destroy'])->whereNumber('id');


    // PROFIL PENGGUNA

    Route::get('/users', [
        ProfileController::class,
        'show'
    ]);

    Route::put('/profile', [
        ProfileController::class,
        'update'
    ]);

    Route::post('/profile/foto', [
        ProfileController::class,
        'uploadPhoto'
    ]);

    Route::post('/logout', [
        AuthController::class,
        'logout'
    ]);

    // PENGAJUAN LOMBA

    Route::get('/pengajuan-lomba/saya', [
        PengajuanLombaController::class,
        'mine'
    ]);

    Route::post('/pengajuan-lomba', [
        PengajuanLombaController::class,
        'store'
    ]);

    // VERIFIKASI ADMINISTRATOR

    Route::get('/admin/pengajuan-lomba', [
        PengajuanLombaController::class,
        'adminIndex'
    ]);

    Route::patch('/admin/pengajuan-lomba/{id}/keputusan', [
        PengajuanLombaController::class,
        'decide'
    ])->whereNumber('id');

    // MANAJEMEN PESERTA OLEH PENYELENGGARA

    Route::get('/penyelenggara/lomba/{id}/peserta', [
        PenyelenggaraLombaController::class,
        'peserta',
    ])->whereNumber('id');

    Route::get('/penyelenggara/pendaftaran/{id}', [
        PenyelenggaraLombaController::class,
        'detailPendaftaran',
    ])->whereNumber('id');

    Route::patch('/penyelenggara/pendaftaran/{id}/keputusan', [
        PenyelenggaraLombaController::class,
        'keputusan',
    ])->whereNumber('id');

    // PENDAFTARAN PESERTA

    Route::post('/lomba/{id}/pendaftaran', [
        PendaftaranController::class,
        'store'
    ])->whereNumber('id');

    Route::get('/pendaftaran/riwayat', [
        PendaftaranController::class,
        'riwayat'
    ]);

    Route::get('/pendaftaran/{id}', [
        PendaftaranController::class,
        'detail'
    ])->whereNumber('id');

    Route::get(
        '/pendaftaran/{id}/jawaban/{idJawaban}/file',
        [
            PendaftaranController::class,
            'unduhJawabanFile'
        ]
    )->whereNumber('id')->whereNumber('idJawaban');

    // CEK STATUS PENDAFTARAN LOMBA
    Route::get('/lomba/{id}/status-pendaftaran', [
        PendaftaranController::class,
        'statusPendaftaran'
    ])->whereNumber('id');

    // FAVORIT: privat untuk tiap akun, semua role.
    Route::get('/favorit', [\App\Http\Controllers\FavoritController::class, 'index']);
    Route::post('/favorit/{id}', [\App\Http\Controllers\FavoritController::class, 'store'])->whereNumber('id');
    Route::delete('/favorit/{id}', [\App\Http\Controllers\FavoritController::class, 'destroy'])->whereNumber('id');

    // ROOM CHAT: hanya pembuat lomba atau peserta dengan status Diterima.
    Route::get('/chat/rooms', [\App\Http\Controllers\ChatLombaController::class, 'rooms']);
    Route::get('/chat/rooms/{id}/messages', [\App\Http\Controllers\ChatLombaController::class, 'messages'])->whereNumber('id');
    Route::post('/chat/rooms/{id}/messages', [\App\Http\Controllers\ChatLombaController::class, 'store'])
        ->whereNumber('id')->middleware('throttle:30,1');

    // DASHBOARD DAN PENGELOLAAN SISTEM: otorisasi tambahan di controller.
    Route::get('/admin/panel', [\App\Http\Controllers\AdminPanelController::class, 'overview']);
    Route::get('/admin/kategori', [\App\Http\Controllers\AdminPanelController::class, 'categories']);
    Route::post('/admin/kategori', [\App\Http\Controllers\AdminPanelController::class, 'createCategory']);
    Route::put('/admin/kategori/{id}', [\App\Http\Controllers\AdminPanelController::class, 'updateCategory'])->whereNumber('id');
    Route::delete('/admin/kategori/{id}', [\App\Http\Controllers\AdminPanelController::class, 'deleteCategory'])->whereNumber('id');
    Route::get('/admin/pengguna', [\App\Http\Controllers\AdminPanelController::class, 'users']);
    Route::get('/admin/semua-lomba', [\App\Http\Controllers\AdminPanelController::class, 'lomba']);
    Route::get('/admin/semua-lomba/{id}', [\App\Http\Controllers\AdminLombaActionController::class, 'show'])->whereNumber('id');
    Route::patch('/admin/semua-lomba/{id}/batalkan', [\App\Http\Controllers\AdminLombaActionController::class, 'cancel'])->whereNumber('id')->middleware('throttle:5,1');
    Route::patch('/admin/semua-lomba/{id}/hentikan', [\App\Http\Controllers\AdminLombaActionController::class, 'stop'])->whereNumber('id')->middleware('throttle:5,1');
});