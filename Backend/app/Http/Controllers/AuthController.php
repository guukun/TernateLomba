<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * Membuat akun baru.
     * Token API diterbitkan saat login, sesuai alur aplikasi Flutter.
     */
    public function register(Request $request): JsonResponse
    {
        $usernameInput = $request->input('username');
        if (is_string($usernameInput)) {
            $request->merge(['username' => trim($usernameInput)]);
        }

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
    }

    /**
     * Memverifikasi kredensial dan menerbitkan token API.
     * Database hanya menyimpan hash token, bukan token aslinya.
     */
    public function login(Request $request): JsonResponse
    {
        $request->merge([
            'username' => trim((string) $request->input('username', '')),
        ]);

        $data = $request->validate([
            'username' => ['required', 'string', 'max:255'],
            'password' => ['required', 'string'],
        ]);

        $user = User::query()
            ->where('username', $data['username'])
            ->first();

        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json([
                'pesan' => 'Username atau password salah.',
            ], 401);
        }

        // Skema database saat ini menyimpan satu token aktif per pengguna.
        $plainToken = Str::random(80);
        $user->api_token_hash = hash('sha256', $plainToken);
        $user->api_token_expires_at = now()->addDays(30);
        $user->save();

        return response()->json([
            'pesan' => 'Login berhasil.',
            'token' => $plainToken,
            'token_expires_at' => $user->api_token_expires_at?->toISOString(),
            'user' => [
                'id_user' => $user->id_user,
                'username' => $user->username,
                'role' => $user->role,
            ],
        ], 200);
    }

    /** Mengakhiri sesi token pengguna yang sedang login. */
    public function logout(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $user->api_token_hash = null;
        $user->api_token_expires_at = null;
        $user->save();

        return response()->json([
            'pesan' => 'Logout berhasil.',
        ], 200);
    }
}
