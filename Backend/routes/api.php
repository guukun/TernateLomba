<?php

use App\Http\Controllers\LombaController;
use App\Http\Middleware\AuthenticateApiToken;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use Illuminate\Validation\Rule;
use App\Http\Controllers\AuthController;

// Tes koneksi Flutter ke Laravel.
// GET /api/tes-koneksi
Route::get('/tes-koneksi', function () {
    return response()->json([
        'pesan' => 'Flutter berhasil terhubung ke Laravel',
    ], 200);
});

// Mengambil pengguna yang sedang login.
// GET /api/users
// Header: Authorization: Bearer TOKEN
Route::get('/users', function (Request $request) {
    $user = $request->user();

    return response()->json([
        'user' => [
            'id_user' => $user->id_user,
            'username' => $user->username,
            'role' => $user->role,

            // URL foto yang bisa diakses Flutter
        'foto_profil_url' => $user->foto_profil
            ? url('/api/profile-photo/' . basename($user->foto_profil))
            : null,
        ],
    ], 200);
})->middleware(AuthenticateApiToken::class);


Route::get('/profile-photo/{filename}', function (string $filename) {
    // Batasi nama file untuk mencegah akses ke file lain.
    if (!preg_match(
        '/\A[a-zA-Z0-9_-]+\.(jpg|jpeg|png|webp)\z/i',
        $filename
    )) {
        abort(404);
    }

    $path = 'profile-photos/' . $filename;
    $disk = Storage::disk('public');

    if (!$disk->exists($path)) {
        abort(404);
    }

    return response()->file($disk->path($path), [
        'Access-Control-Allow-Origin' => '*',
        'Cache-Control' => 'no-cache',
    ]);
});


// Login pengguna.
// POST /api/login
Route::post('/login', function (Request $request) {
    $data = $request->validate([
        'username' => ['required', 'string'],
        'password' => ['required', 'string'],
    ]);

    $user = User::where(
        'username',
        $data['username']
    )->first();

    if (
        !$user ||
        !Hash::check($data['password'], $user->password)
    ) {
        return response()->json([
            'pesan' => 'Username atau password salah',
        ], 401);
    }

    // Buat token acak untuk pengguna.
    $plainToken = Str::random(80);

    // Simpan hash token, bukan token aslinya.
    $user->api_token_hash = hash(
        'sha256',
        $plainToken
    );

    // Token berlaku selama 30 hari.
    $user->api_token_expires_at = now()->addDays(30);

    $user->save();

    return response()->json([
        'pesan' => 'Login berhasil',
        'token' => $plainToken,
        'user' => [
            'id_user' => $user->id_user,
            'username' => $user->username,
            'role' => $user->role,
        ],
    ], 200);
});


// Registrasi pengguna.
// POST /api/register
Route::post('/register', [AuthController::class, 'register']);

/*
| UPDATE PROFIL
| Endpoint:
| PUT /api/profile
*/

// UPDATE PROFILE
Route::put('/profile', function (Request $request) {

    $user = $request->user();

    if (!$user) {
        return response()->json([
            'pesan' => 'User tidak ditemukan',
        ], 401);
    }

    // Validasi
    $data = $request->validate([

        'username' => [
            'required',
            'string',
            'max:255',

            Rule::unique('users', 'username')
                ->ignore(
                    $user->id_user,
                    'id_user'
                ),
        ],

        // Password tidak wajib diganti
        'password' => [
            'nullable',
            'string',
            'min:8',
            'confirmed',
        ],
    ]);

    // Update username
    $user->username =
        $data['username'];

    // Update password jika diisi
    if (!empty($data['password'])) {

        $user->password =
            Hash::make(
                $data['password']
            );
    }

    // Simpan ke database
    $user->save();

    return response()->json([

        'pesan' =>
            'Profil berhasil diperbarui',

        'user' => [
            'id_user' =>
                $user->id_user,

            'username' =>
                $user->username,

            'role' =>
                $user->role,
        ],

    ], 200);

})->middleware(AuthenticateApiToken::class);

Route::post('/logout', function (Request $request) {
    $user = $request->user();

    $user->api_token_hash = null;
    $user->api_token_expires_at = null;
    $user->save();

    return response()->json([
        'pesan' => 'Logout berhasil',
    ], 200);
})->middleware(AuthenticateApiToken::class);

Route::post('/profile/foto', function (Request $request) {
    $user = $request->user();

    $request->validate([
        'foto_profil' => [
            'required',
            'image',
            'mimes:jpg,jpeg,png,webp',
            'max:2048',
        ],
    ]);

    $path = $request->file('foto_profil')
        ->store('profile-photos', 'public');

    if (!$path) {
        return response()->json([
            'pesan' => 'Foto gagal disimpan.',
        ], 500);
    }

    $fotoLama = $user->foto_profil;

    $user->foto_profil = $path;
    $user->save();

    if (
        $fotoLama &&
        Storage::disk('public')->exists($fotoLama)
    ) {
        Storage::disk('public')->delete($fotoLama);
    }

    return response()->json([
        'pesan' => 'Foto profil berhasil diperbarui.',
        'user' => [
            'id_user' => $user->id_user,
            'username' => $user->username,
            'role' => $user->role,
            'foto_profil' => $user->foto_profil,
            'foto_profil_url' => url(
                '/api/profile-photo/' . basename($user->foto_profil)
            ),
        ],
    ], 200);
})->middleware(AuthenticateApiToken::class);

// KATALOG LOMBA PUBLIK

Route::get('/kategori', [
    LombaController::class,
    'kategori',
]);

Route::get('/lomba', [
    LombaController::class,
    'index',
]);

Route::get('/lomba/{id}', [
    LombaController::class,
    'show',
])->whereNumber('id');