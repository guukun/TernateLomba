<?php

namespace App\Http\Controllers;

use App\Models\Notifikasi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotifikasiController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        // Batas akses wajib berdasarkan akun yang sedang login.
        // User hanya melihat notifikasi miliknya sendiri. Administrator juga
        // hanya melihat notifikasi yang secara khusus dikirim ke akun admin.
        $items = Notifikasi::query()
            ->where('id_user', $request->user()->id_user)
            ->orderByDesc('created_at')
            ->orderByDesc('id_notifikasi')
            ->limit(100)
            ->get();

        return response()->json([
            'pesan' => 'Notifikasi berhasil diambil.',
            'data' => $items->map(fn (Notifikasi $item) => $this->format($item)),
            'unread_count' => $items->whereNull('dibaca_at')->count(),
        ]);
    }

    public function read(Request $request, int $id): JsonResponse
    {
        $item = Notifikasi::query()
            ->where('id_user', $request->user()->id_user)
            ->whereKey($id)
            ->firstOrFail();

        if (!$item->dibaca_at) {
            $item->update(['dibaca_at' => now()]);
        }

        return response()->json([
            'pesan' => 'Notifikasi ditandai sudah dibaca.',
            'data' => $this->format($item->fresh()),
        ]);
    }

    public function readAll(Request $request): JsonResponse
    {
        Notifikasi::query()
            ->where('id_user', $request->user()->id_user)
            ->whereNull('dibaca_at')
            ->update(['dibaca_at' => now(), 'updated_at' => now()]);

        return response()->json(['pesan' => 'Semua notifikasi sudah dibaca.']);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        Notifikasi::query()
            ->where('id_user', $request->user()->id_user)
            ->whereKey($id)
            ->firstOrFail()
            ->delete();

        return response()->json(['pesan' => 'Notifikasi berhasil dihapus.']);
    }

    private function format(Notifikasi $item): array
    {
        return [
            'id_notifikasi' => $item->id_notifikasi,
            'judul' => $item->judul,
            'pesan' => $item->pesan,
            'tipe' => $item->tipe,
            'data' => $item->data,
            'dibaca' => $item->dibaca_at !== null,
            'dibaca_at' => $item->dibaca_at?->toISOString(),
            'created_at' => $item->created_at?->toISOString(),
        ];
    }
}
