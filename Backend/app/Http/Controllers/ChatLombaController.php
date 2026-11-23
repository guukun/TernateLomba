<?php
namespace App\Http\Controllers;

use App\Models\ChatPesan;
use App\Models\Lomba;
use App\Models\Pendaftaran;
use App\Models\User;
use App\Services\LombaLifecycleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChatLombaController extends Controller
{
    /** Tidak ada ruang global: setiap lomba aktif punya ruang sendiri. */
    public function rooms(Request $request): JsonResponse
    {
        app(LombaLifecycleService::class)->sync();
        $userId = (int) $request->user()->id_user;

        $items = Lomba::query()
            ->with(['pengajuan.kategori'])
            ->whereHas('pengajuan', fn ($q) => $q->where('status_pengajuan', 'Disetujui'))
            ->where(function ($q) use ($userId) {
                $q->whereHas('pengajuan', fn ($s) => $s->where('id_user', $userId))
                  ->orWhereHas('pendaftaran', fn ($s) => $s->where('id_user', $userId)
                      ->where('status_pendaftaran', 'Diterima'));
            })
            ->orderByDesc('id_lomba')
            ->get();

        return response()->json([
            'pesan' => 'Ruang chat berhasil diambil.',
            'data' => $items->map(function (Lomba $lomba) use ($userId) {
                $latest = ChatPesan::query()->where('id_lomba', $lomba->id_lomba)
                    ->orderByDesc('id_pesan')->first();
                return [
                    'id_lomba' => $lomba->id_lomba,
                    'nama_lomba' => $lomba->pengajuan?->nama_lomba,
                    'kategori' => $lomba->pengajuan?->kategori?->nama_kategori,
                    'status_lomba' => $lomba->status_lomba,
                    'is_penyelenggara' => (int) $lomba->pengajuan?->id_user === $userId,
                    'poster_url' => $lomba->pengajuan?->poster_lomba
                        ? url('/api/poster-lomba/' . rawurlencode(basename($lomba->pengajuan->poster_lomba)))
                        : null,
                    'pesan_terakhir' => $latest?->isi_pesan,
                    'pesan_terakhir_at' => $latest?->created_at?->toIso8601String(),
                ];
            })->values(),
        ]);
    }

    private function authorizedLomba(Request $request, int $id, ?Lomba $lockedLomba = null): Lomba
    {
        $userId = (int) $request->user()->id_user;
        $lomba = $lockedLomba ?? Lomba::query()->with(['pengajuan'])->findOrFail($id);
        if ($lockedLomba !== null) {
            $lomba->load('pengajuan');
        }
        if (!$lomba->pengajuan || $lomba->pengajuan->status_pengajuan !== 'Disetujui') {
            abort(404, 'Ruang chat tidak tersedia.');
        }
        $owner = (int) $lomba->pengajuan->id_user === $userId;
        $accepted = Pendaftaran::query()->where('id_lomba', $id)->where('id_user', $userId)
            ->where('status_pendaftaran', 'Diterima')->exists();
        if (!$owner && !$accepted) {
            abort(403, 'Hanya penyelenggara dan peserta yang diterima dapat mengakses room ini.');
        }
        return $lomba;
    }

    /** GET /api/chat/rooms/{id}/messages?after_id=0 */
    public function messages(Request $request, int $id): JsonResponse
    {
        $lomba = $this->authorizedLomba($request, $id);
        $params = $request->validate(['after_id' => ['nullable', 'integer', 'min:0']]);
        $after = (int) ($params['after_id'] ?? 0);
        $query = ChatPesan::query()->with('pengirim:id_user,username,foto_profil')
            ->where('id_lomba', $id);
        // Untuk initial load ambil 80 pesan terbaru, lalu urutkan lama -> baru.
        if ($after === 0) {
            $items = $query->orderByDesc('id_pesan')->limit(80)->get()->reverse()->values();
        } else {
            $items = $query->where('id_pesan', '>', $after)->orderBy('id_pesan')->limit(100)->get();
        }
        return response()->json([
            'pesan' => 'Pesan berhasil diambil.',
            'data' => $items->map(fn (ChatPesan $item) => $this->formatMessage($item))->values(),
            'read_only' => $lomba->status_lomba !== 'Aktif',
        ]);
    }

    /** POST /api/chat/rooms/{id}/messages */
    public function store(Request $request, int $id): JsonResponse
    {
        $data = $request->validate(['isi_pesan' => ['required', 'string', 'max:2000']]);
        $text = trim($data['isi_pesan']);
        if ($text === '') return response()->json(['pesan' => 'Pesan tidak boleh kosong.'], 422);
        $message = DB::transaction(function () use ($request, $id, $text) {
            // Lock lomba agar perubahan status yang bersamaan tidak melewati pemeriksaan.
            $lomba = Lomba::query()->whereKey($id)->lockForUpdate()->firstOrFail();
            $lomba = $this->authorizedLomba($request, $id, $lomba);
            if ($lomba->status_lomba !== 'Aktif') {
                abort(422, 'Room ini hanya dapat dibaca karena lomba telah selesai.');
            }
            return ChatPesan::query()->create([
                'id_lomba' => $id,
                'id_user' => $request->user()->id_user,
                'isi_pesan' => $text,
            ]);
        });
        $message->load('pengirim:id_user,username,foto_profil');
        return response()->json(['pesan' => 'Pesan terkirim.', 'data' => $this->formatMessage($message)], 201);
    }

    private function formatMessage(ChatPesan $item): array
    {
        return [
            'id_pesan' => $item->id_pesan,
            'id_user' => $item->id_user,
            'username' => $item->pengirim?->username ?? 'Pengguna',
            'foto_profil_url' => $item->pengirim?->foto_profil
                ? url('/api/profile-photo/' . rawurlencode(basename($item->pengirim->foto_profil)))
                : null,
            'isi_pesan' => $item->isi_pesan,
            'created_at' => $item->created_at?->toIso8601String(),
        ];
    }
}