<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateApiToken
{
    public function handle(
        Request $request,
        Closure $next
    ): Response {
        $plainToken = $request->bearerToken();

        if (!$plainToken) {
            return response()->json([
                'pesan' => 'Token autentikasi tidak ditemukan.',
            ], 401);
        }

        $tokenHash = hash('sha256', $plainToken);

        $user = User::query()
            ->where('api_token_hash', $tokenHash)
            ->whereNotNull('api_token_expires_at')
            ->where('api_token_expires_at', '>', now())
            ->first();

        if (!$user) {
            return response()->json([
                'pesan' => 'Token tidak valid atau sudah kedaluwarsa.',
            ], 401);
        }

        // Membuat $request->user() mengembalikan
        // pengguna yang sudah diverifikasi.
        $request->setUserResolver(
            fn () => $user
        );

        return $next($request);
    }
}