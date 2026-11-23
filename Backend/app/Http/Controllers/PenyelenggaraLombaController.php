<?php

namespace App\Http\Controllers;

use App\Models\JawabanPendaftaran;
use App\Models\Lomba;
use App\Models\Notifikasi;
use App\Models\Pendaftaran;
use App\Services\LombaLifecycleService;
use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Symfony\Component\HttpFoundation\StreamedResponse;
use Throwable;

class PenyelenggaraLombaController extends Controller
{
    public function __construct(private readonly LombaLifecycleService $lifecycle)
    {
    }

    /** GET /api/penyelenggara/lomba/{id}/peserta */
    public function peserta(Request $request, int $id): JsonResponse
    {
        $this->lifecycle->sync();
        $user = $request->user();

        $lomba = Lomba::query()
            ->with(['pengajuan.kategori', 'pengajuan.penyelenggara'])
            ->withCount([
                'pendaftaran as jumlah_peserta_diterima' => fn ($query) => $query->where('status_pendaftaran', 'Diterima'),
                'pendaftaran as jumlah_peserta_menunggu' => fn ($query) => $query->where('status_pendaftaran', 'Menunggu'),
                'pendaftaran as jumlah_peserta_ditolak' => fn ($query) => $query->where('status_pendaftaran', 'Ditolak'),
            ])
            ->whereHas('pengajuan', fn ($query) => $query->where('id_user', $user->id_user))
            ->find($id);

        if (!$lomba) {
            return response()->json(['pesan' => 'Lomba tidak ditemukan atau bukan milik Anda.'], 404);
        }

        $peserta = Pendaftaran::query()
            ->with(['peserta:id_user,username,foto_profil'])
            ->withCount('jawabanPendaftaran')
            ->where('id_lomba', $lomba->id_lomba)
            ->orderByRaw("CASE status_pendaftaran WHEN 'Menunggu' THEN 0 WHEN 'Diterima' THEN 1 ELSE 2 END")
            ->orderByDesc('tanggal_pendaftaran')
            ->get()
            ->map(fn (Pendaftaran $item) => [
                'id_pendaftaran' => $item->id_pendaftaran,
                'id_user' => $item->id_user,
                'username' => $item->peserta?->username ?? 'Pengguna',
                'foto_profil' => $item->peserta?->foto_profil,
                'foto_profil_url' => $item->peserta?->foto_profil
                    ? url('/api/profile-photo/' . rawurlencode(basename($item->peserta->foto_profil)))
                    : null,
                'tanggal_pendaftaran' => $item->tanggal_pendaftaran?->toISOString(),
                'status_pendaftaran' => $item->status_pendaftaran,
                'jumlah_jawaban' => (int) $item->jawaban_pendaftaran_count,
            ])->values();

        $pengajuan = $lomba->pengajuan;

        return response()->json([
            'pesan' => 'Daftar peserta lomba berhasil diambil.',
            'data' => [
                'lomba' => [
                    'id_lomba' => $lomba->id_lomba,
                    'id_pengajuan' => $lomba->id_pengajuan,
                    'nama_lomba' => $pengajuan?->nama_lomba,
                    'deskripsi' => $pengajuan?->deskripsi,
                    'poster_url' => $pengajuan?->poster_lomba
                        ? url('/api/poster-lomba/' . rawurlencode(basename($pengajuan->poster_lomba)))
                        : null,
                    'status_lomba' => $lomba->penghentian ? 'Dihentikan' : $lomba->status_lomba,
                    'status_pengajuan' => $pengajuan?->status_pengajuan,
                    'tanggal_pelaksanaan' => $pengajuan?->tanggal_pelaksanaan?->format('Y-m-d'),
                    'batas_pendaftaran' => $pengajuan?->batas_pendaftaran?->format('Y-m-d'),
                    'kuota_peserta' => $pengajuan?->kuota_peserta,
                    'jumlah_peserta_diterima' => (int) $lomba->jumlah_peserta_diterima,
                    'jumlah_peserta_menunggu' => (int) $lomba->jumlah_peserta_menunggu,
                    'jumlah_peserta_ditolak' => (int) $lomba->jumlah_peserta_ditolak,
                    'kategori' => $pengajuan?->kategori?->nama_kategori,
                ],
                'peserta' => $peserta,
            ],
        ], 200);
    }

    /** GET /api/penyelenggara/pendaftaran/{id} */
    public function detailPendaftaran(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $pendaftaran = Pendaftaran::query()
            ->with(['peserta:id_user,username,foto_profil', 'lomba.pengajuan.formFields'])
            ->whereKey($id)
            ->whereHas('lomba.pengajuan', fn ($query) => $query->where('id_user', $user->id_user))
            ->first();

        if (!$pendaftaran) {
            return response()->json(['pesan' => 'Pendaftaran tidak ditemukan atau bukan milik lomba Anda.'], 404);
        }

        $answers = $pendaftaran->jawabanPendaftaran()
            ->with('formField')
            ->get()
            ->map(function (JawabanPendaftaran $answer) use ($id): array {
                $field = $answer->formField;
                $isFile = $field?->tipe_field === 'File';

                return [
                    'id_jawaban' => $answer->id_jawaban,
                    'id_field' => $answer->id_field,
                    'nama_field' => $field?->nama_field ?? 'Informasi',
                    'tipe_field' => $field?->tipe_field ?? 'Text',
                    'jawaban' => $isFile ? null : $answer->jawaban,
                    'file_url' => $isFile
                        ? URL::temporarySignedRoute(
                            'penyelenggara.pendaftaran.file',
                            now()->addMinutes(10),
                            ['id' => $id, 'idJawaban' => $answer->id_jawaban]
                        )
                        : null,
                    'nama_file' => $isFile && $answer->jawaban
                        ? basename($answer->jawaban)
                        : null,
                ];
            })->values();

        return response()->json([
            'pesan' => 'Detail peserta berhasil diambil.',
            'data' => [
                'id_pendaftaran' => $pendaftaran->id_pendaftaran,
                'id_lomba' => $pendaftaran->id_lomba,
                'id_user' => $pendaftaran->id_user,
                'username' => $pendaftaran->peserta?->username ?? 'Pengguna',
                'foto_profil_url' => $pendaftaran->peserta?->foto_profil
                    ? url('/api/profile-photo/' . rawurlencode(basename($pendaftaran->peserta->foto_profil)))
                    : null,
                'tanggal_pendaftaran' => $pendaftaran->tanggal_pendaftaran?->toISOString(),
                'status_pendaftaran' => $pendaftaran->status_pendaftaran,
                'nama_lomba' => $pendaftaran->lomba?->pengajuan?->nama_lomba,
                'jawaban' => $answers,
            ],
        ], 200);
    }

    /** PATCH /api/penyelenggara/pendaftaran/{id}/keputusan */
    public function keputusan(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate([
            'keputusan' => ['required', 'in:Diterima,Ditolak'],
            'catatan' => ['nullable', 'string', 'max:2000'],
        ]);

        try {
            $result = DB::transaction(function () use ($id, $user, $data): array {
                // Samakan urutan penguncian dengan pendaftaran dan tindakan admin:
                // lomba terlebih dahulu, lalu pendaftaran.
                $idLomba = Pendaftaran::query()->whereKey($id)->value('id_lomba');
                if ($idLomba === null) {
                    return ['error' => 'Pendaftaran tidak ditemukan.', 'status' => 404];
                }

                $lomba = Lomba::query()
                    ->whereKey($idLomba)
                    ->lockForUpdate()
                    ->first();
                if (!$lomba) {
                    return ['error' => 'Lomba tidak ditemukan.', 'status' => 404];
                }

                $pendaftaran = Pendaftaran::query()
                    ->whereKey($id)
                    ->lockForUpdate()
                    ->first();
                if (!$pendaftaran || (int) $pendaftaran->id_lomba !== (int) $lomba->id_lomba) {
                    return ['error' => 'Pendaftaran sudah tidak tersedia atau berubah.', 'status' => 409];
                }

                $lomba->load('pengajuan');
                $pengajuan = $lomba->pengajuan;

                if (!$pengajuan || (int) $pengajuan->id_user !== (int) $user->id_user) {
                    return ['error' => 'Anda tidak memiliki akses untuk mengelola peserta lomba ini.', 'status' => 403];
                }

                if ($lomba->status_lomba !== 'Aktif' || $pengajuan->status_pengajuan !== 'Disetujui') {
                    return ['error' => 'Lomba tidak aktif sehingga keputusan peserta tidak dapat diubah.', 'status' => 422];
                }

                if ($pendaftaran->status_pendaftaran !== 'Menunggu') {
                    return ['error' => 'Pendaftaran ini sudah diproses sebelumnya.', 'status' => 409];
                }

                if ($data['keputusan'] === 'Diterima') {
                    $acceptedCount = Pendaftaran::query()
                        ->where('id_lomba', $lomba->id_lomba)
                        ->where('status_pendaftaran', 'Diterima')
                        ->count();

                    $quota = $pengajuan->kuota_peserta;
                    if ($quota !== null && $acceptedCount >= (int) $quota) {
                        return ['error' => 'Kuota sudah penuh. Peserta tidak dapat diterima lagi.', 'status' => 409];
                    }
                }

                $pendaftaran->status_pendaftaran = $data['keputusan'];
                $pendaftaran->save();

                // Simpan notifikasi peserta dalam transaksi yang sama dengan
                // perubahan status agar keputusan tidak tersimpan tanpa
                // pemberitahuan kepada peserta.
                $diterima = $data['keputusan'] === 'Diterima';
                Notifikasi::create([
                    'id_user' => $pendaftaran->id_user,
                    'judul' => $diterima
                        ? 'Pendaftaran Lomba Diterima'
                        : 'Pendaftaran Lomba Ditolak',
                    'pesan' => ($diterima
                        ? 'Pendaftaran Anda pada lomba "' . $pengajuan->nama_lomba . '" telah diterima.'
                        : 'Pendaftaran Anda pada lomba "' . $pengajuan->nama_lomba . '" ditolak.')
                        . (!empty($data['catatan'])
                            ? ' Catatan penyelenggara: ' . trim($data['catatan'])
                            : ''),
                    'tipe' => strtolower($data['keputusan']),
                    'data' => [
                        'id_pendaftaran' => $pendaftaran->id_pendaftaran,
                        'id_lomba' => $pendaftaran->id_lomba,
                        'keputusan' => $data['keputusan'],
                        'catatan_penyelenggara' => !empty($data['catatan'])
                            ? trim($data['catatan']) : null,
                    ],
                ]);

                return [
                    'pendaftaran' => $pendaftaran->fresh(),
                    'nama_lomba' => $pengajuan->nama_lomba,
                    'jumlah_peserta_diterima' => Pendaftaran::query()
                        ->where('id_lomba', $lomba->id_lomba)
                        ->where('status_pendaftaran', 'Diterima')
                        ->count(),
                    'kuota_peserta' => $pengajuan->kuota_peserta,
                ];
            }, 3);
        } catch (QueryException $exception) {
            report($exception);
            return response()->json(['pesan' => 'Keputusan peserta gagal disimpan.'], 500);
        } catch (Throwable $exception) {
            report($exception);
            return response()->json(['pesan' => 'Terjadi kesalahan saat memproses peserta.'], 500);
        }

        if (isset($result['error'])) {
            return response()->json(['pesan' => $result['error']], $result['status']);
        }

        $processed = $result['pendaftaran'];

        return response()->json([
            'pesan' => $data['keputusan'] === 'Diterima'
                ? 'Peserta berhasil diterima.'
                : 'Peserta berhasil ditolak.',
            'data' => [
                'id_pendaftaran' => $processed->id_pendaftaran,
                'status_pendaftaran' => $processed->status_pendaftaran,
                'jumlah_peserta_diterima' => $result['jumlah_peserta_diterima'],
                'kuota_peserta' => $result['kuota_peserta'],
            ],
        ], 200);
    }

    /** GET signed URL untuk file jawaban; URL hanya berlaku 10 menit. */
    public function downloadFile(int $id, int $idJawaban): StreamedResponse
    {
        $answer = JawabanPendaftaran::query()
            ->with('formField')
            ->where('id_jawaban', $idJawaban)
            ->where('id_pendaftaran', $id)
            ->firstOrFail();

        if ($answer->formField?->tipe_field !== 'File') {
            abort(404);
        }

        $path = $answer->jawaban;
        $expectedPrefix = 'pendaftaran/' . $id . '/';
        $disk = Storage::disk('local');

        if (!is_string($path) || !str_starts_with($path, $expectedPrefix) || str_contains($path, '..') || !$disk->exists($path)) {
            abort(404);
        }

        return $disk->download($path, basename($path), [
            'Cache-Control' => 'private, no-store',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }
}