<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class ProfileController extends Controller
{
    /** GET /api/users */
    public function show(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return response()->json([
            'user' => $this->formatUser($user),
        ], 200);
    }

    /** PUT /api/profile */
    public function update(Request $request): JsonResponse
    {
        $usernameInput = $request->input('username');
        if (is_string($usernameInput)) {
            $request->merge(['username' => trim($usernameInput)]);
        }

        /** @var User $user */
        $user = $request->user();

        $data = $request->validate([
            'username' => [
                'required',
                'string',
                'max:255',
                Rule::unique('users', 'username')->ignore(
                    $user->getKey(),
                    $user->getKeyName()
                ),
            ],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
        ]);

        $user->username = $data['username'];

        if (!empty($data['password'])) {
            $user->password = Hash::make($data['password']);
        }

        $user->save();

        return response()->json([
            'pesan' => 'Profil berhasil diperbarui.',
            'user' => [
                'id_user' => $user->id_user,
                'username' => $user->username,
                'role' => $user->role,
            ],
        ], 200);
    }

    /** POST /api/profile/foto */
    public function uploadPhoto(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $data = $request->validate([
            'foto_profil' => [
                'required',
                'image',
                'mimes:jpg,jpeg,png,webp',
                'max:2048',
            ],
        ]);

        $disk = Storage::disk('public');
        $newPath = $data['foto_profil']->store('profile-photos', 'public');

        if (!$newPath) {
            return response()->json([
                'pesan' => 'Foto gagal disimpan.',
            ], 500);
        }

        $oldPath = $user->foto_profil;

        try {
            $user->foto_profil = $newPath;
            $user->save();
        } catch (\Throwable $exception) {
            $disk->delete($newPath);
            throw $exception;
        }

        if ($oldPath && $oldPath !== $newPath && $disk->exists($oldPath)) {
            $disk->delete($oldPath);
        }

        return response()->json([
            'pesan' => 'Foto profil berhasil diperbarui.',
            'user' => $this->formatUser($user),
        ], 200);
    }

    /** GET /api/profile-photo/{filename} */
    public function photo(string $filename): BinaryFileResponse
    {
        // Hanya izinkan nama file sederhana dengan ekstensi gambar yang didukung.
        if (!preg_match('/\A[a-zA-Z0-9_-]+\.(jpg|jpeg|png|webp)\z/i', $filename)) {
            abort(404);
        }

        $path = 'profile-photos/' . $filename;
        $disk = Storage::disk('public');

        if (!$disk->exists($path)) {
            abort(404);
        }

        return response()->file($disk->path($path), [
            'Cache-Control' => 'private, max-age=300',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    /** Format data profil agar konsisten untuk respons API. */
    private function formatUser(User $user): array
    {
        return [
            'id_user' => $user->id_user,
            'username' => $user->username,
            'role' => $user->role,
            'foto_profil' => $user->foto_profil,
            'foto_profil_url' => $user->foto_profil
                ? url('/api/profile-photo/' . basename($user->foto_profil))
                : null,
        ];
    }
}
