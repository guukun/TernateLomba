<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

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
        ],
    ], 200);
})->middleware('auth:sanctum');

// Login pengguna.
// POST /api/login
Route::post('/login', function (Request $request) {
    // Validasi input dari Flutter.
    $data = $request->validate([
        'username' => ['required', 'string'],
        'password' => ['required', 'string'],
    ]);

    // Mencari akun pada tabel users.
    $user = User::where('username', $data['username'])->first();

    // Memeriksa akun dan password yang sudah di-hash.
    if (!$user || !Hash::check($data['password'], $user->password)) {
        return response()->json([
            'pesan' => 'Username atau password salah',
        ], 401);
    }

    // Membuat token untuk autentikasi permintaan berikutnya.
    $token = $user->createToken('flutter')->plainTextToken;

    return response()->json([
        'pesan' => 'Login berhasil',
        'token' => $token,
        'user' => [
            'id_user' => $user->id_user,
            'username' => $user->username,
            'role' => $user->role,
        ],
    ], 200);
});

// Registrasi pengguna.
// POST /api/register
Route::post('/register', function (Request $request) {
    $data = $request->validate([
        'username' => [
            'required',
            'string',
            'max:255',
            'unique:users,username',
        ],
        'password' => [
            'required',
            'string',
            'min:8',
            'confirmed',
        ],
    ]);

    // Role ditentukan oleh backend untuk akun baru.
    $user = User::create([
        'username' => $data['username'],
        'password' => Hash::make($data['password']),
        'role' => 'User',
    ]);

    return response()->json([
        'pesan' => 'Akun berhasil dibuat. Silakan masuk.',
        'user' => [
            'id_user' => $user->id_user,
            'username' => $user->username,
            'role' => $user->role,
        ],
    ], 201);
});
