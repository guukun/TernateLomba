<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $request)
    {
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
}
