<?php

namespace App\Http\Controllers;

use App\Models\Lomba;
use App\Models\LombaPenghentian;
use App\Models\Notifikasi;
use App\Services\LombaLifecycleService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class AdminLombaActionController extends Controller
{
    private function authorizeAdmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'Administrator', 403, 'Khusus administrator.');
    }

    /** GET /api/admin/semua-lomba/{id} */
    public function show(Request $request, int $id): JsonResponse
    {
        $this->authorizeAdmin($request);
        app(LombaLifecycleService::class)->sync();
        $lomba = Lomba::query()
            ->with(['pengajuan.penyelenggara', 'pengajuan.kategori', 'penghentian'])
            ->withCount(['pendaftaran as jumlah_pendaftar', 'pendaftaran as jumlah_diterima' =>
                fn ($query) => $query->where('status_pendaftaran', 'Diterima')])
            ->findOrFail($id);
        return response()->json(['data' => $this->format($lomba)]);
    }

    /** PATCH /api/admin/semua-lomba/{id}/batalkan */
    public function cancel(Request $request, int $id): JsonResponse
    {
        return $this->takeAction($request, $id, 'Batalkan');
    }

    /** PATCH /api/admin/semua-lomba/{id}/hentikan */
    public function stop(Request $request, int $id): JsonResponse
    {
        return $this->takeAction($request, $id, 'Hentikan');
    }

    /**
     * Immutable administrative action, serialized with participant registration.
     * Existing enum remains compatible (status_lomba becomes Selesai).
     */
    private function takeAction(Request $request, int $id, string $action): JsonResponse
    {
        $this->authorizeAdmin($request);
        $validated = $request->validate([
            'alasan' => ['required', 'string', 'min:10', 'max:1000'],
        ]);
        $alasan = trim($validated['alasan']);
        if (mb_strlen($alasan) < 10) {
            throw ValidationException::withMessages(['alasan' => 'Alasan minimal 10 karakter.']);
        }

        $result = DB::transaction(function () use ($id, $request, $alasan, $action): array {
            $lomba = Lomba::query()->whereKey($id)->lockForUpdate()->firstOrFail();
            $lomba->load(['pengajuan', 'penghentian']);
            if ($lomba->penghentian) {
                abort(409, 'Lomba sudah dibatalkan atau dihentikan sebelumnya.');
            }
            $pengajuan = $lomba->pengajuan;
            if ($lomba->status_lomba !== 'Aktif' || !$pengajuan || $pengajuan->status_pengajuan !== 'Disetujui') {
                abort(409, 'Lomba sudah tidak aktif atau belum disetujui.');
            }
            $today = Carbon::now('Asia/Jayapura')->toDateString();
            $start = $pengajuan->tanggal_pelaksanaan?->toDateString();
            $end = $pengajuan->tanggal_selesai_pelaksanaan?->toDateString() ?? $start;
            if (!$start) {
                abort(409, 'Tanggal mulai pelaksanaan belum tersedia.');
            }
            if ($action === 'Batalkan' && $today >= $start) {
                abort(409, 'Pelaksanaan sudah dimulai. Gunakan Hentikan Lomba jika masih berlangsung.');
            }
            if ($action === 'Hentikan' && ($today < $start || $today > $end)) {
                abort(409, 'Hentikan Lomba hanya tersedia selama masa pelaksanaan.');
            }

            LombaPenghentian::create([
                'id_lomba' => $id,
                'id_admin' => $request->user()->id_user,
                'jenis_tindakan' => $action,
                'alasan' => $alasan,
                'dihentikan_at' => now(),
            ]);
            $lomba->update(['status_lomba' => 'Selesai']);
            $recipientIds = $lomba->pendaftaran()->pluck('id_user')
                ->push($pengajuan->id_user)->unique()->values();
            $status = $action === 'Batalkan' ? 'Dibatalkan' : 'Dihentikan';
            foreach ($recipientIds as $recipientId) {
                Notifikasi::create([
                    'id_user' => $recipientId,
                    'judul' => 'Lomba ' . $status . ' Administrator',
                    'pesan' => 'Lomba "' . $pengajuan->nama_lomba . '" ' . strtolower($status) . '. Alasan: ' . $alasan,
                    'tipe' => 'lomba',
                    'data' => ['id_lomba' => $id, 'status_lomba' => $status],
                ]);
            }
            return ['id_lomba' => $id, 'status_lomba' => $status, 'alasan' => $alasan];
        }, 3);

        app(LombaLifecycleService::class)->sync();
        return response()->json([
            'pesan' => 'Lomba berhasil ' . ($action === 'Batalkan' ? 'dibatalkan.' : 'dihentikan.'),
            'data' => $result,
        ]);
    }

    private function format(Lomba $lomba): array
    {
        $p = $lomba->pengajuan;
        return [
            'id_lomba' => $lomba->id_lomba,
            'id_pengajuan' => $lomba->id_pengajuan,
            'nama_lomba' => $p?->nama_lomba,
            'deskripsi' => $p?->deskripsi,
            'persyaratan' => $p?->persyaratan,
            'penyelenggara' => $p?->penyelenggara?->username,
            'kategori' => $p?->kategori?->nama_kategori,
            'poster_lomba' => $p?->poster_lomba,
            'poster_url' => $p?->poster_lomba
                ? url('/api/poster-lomba/' . rawurlencode(basename($p->poster_lomba))) : null,
            'biaya' => $p?->biaya,
            'hadiah' => $p?->hadiah,
            'kuota_peserta' => $p?->kuota_peserta,
            'lokasi_pendaftaran' => $p?->lokasi_pendaftaran,
            'metode_pelaksanaan' => $p?->metode_pelaksanaan,
            'detail_pelaksanaan' => $p?->detail_pelaksanaan,
            'kontak_penyelenggara' => $p?->kontak_penyelenggara,
            'tanggal_mulai_pendaftaran' => $p?->tanggal_mulai_pendaftaran?->format('Y-m-d'),
            'batas_pendaftaran' => $p?->batas_pendaftaran?->format('Y-m-d'),
            'tanggal_pelaksanaan' => $p?->tanggal_pelaksanaan?->format('Y-m-d'),
            'tanggal_selesai_pelaksanaan' => ($p?->tanggal_selesai_pelaksanaan ?? $p?->tanggal_pelaksanaan)?->format('Y-m-d'),
            'status_lomba' => $lomba->status_efektif,
            'boleh_dibatalkan' => !$lomba->penghentian
                && $lomba->status_lomba === 'Aktif'
                && $p?->status_pengajuan === 'Disetujui'
                && $p?->tanggal_pelaksanaan
                && Carbon::now('Asia/Jayapura')->toDateString() < $p->tanggal_pelaksanaan->toDateString(),
            'boleh_dihentikan' => !$lomba->penghentian
                && $lomba->status_lomba === 'Aktif'
                && $p?->status_pengajuan === 'Disetujui'
                && $p?->tanggal_pelaksanaan
                && Carbon::now('Asia/Jayapura')->toDateString() >= $p->tanggal_pelaksanaan->toDateString()
                && Carbon::now('Asia/Jayapura')->toDateString() <= ($p->tanggal_selesai_pelaksanaan ?? $p->tanggal_pelaksanaan)->toDateString(),
            'jenis_tindakan' => $lomba->penghentian?->jenis_tindakan,
            'alasan_penghentian' => $lomba->penghentian?->alasan,
            'dihentikan_at' => $lomba->penghentian?->dihentikan_at?->toIso8601String(),
            'id_admin_penghenti' => $lomba->penghentian?->id_admin,
            'jumlah_pendaftar' => $lomba->jumlah_pendaftar,
            'jumlah_diterima' => $lomba->jumlah_diterima,
        ];
    }
}