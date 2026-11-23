<?php

namespace App\Http\Controllers;

use App\Models\KategoriLomba;
use App\Models\Lomba;
use App\Models\InformasiLomba;
use App\Services\LombaLifecycleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LombaController extends Controller
{
    /** GET /api/kategori */
    public function kategori(): JsonResponse
    {
        $kategori = KategoriLomba::query()
            ->orderBy('nama_kategori')
            ->get(['id_kategori', 'nama_kategori', 'deskripsi_kategori']);

        return response()->json([
            'pesan' => 'Kategori berhasil diambil.',
            'data' => $kategori,
        ], 200);
    }

    /** GET /api/lomba */
    public function index(Request $request): JsonResponse
    {
        app(LombaLifecycleService::class)->sync();

        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:200'],
            'id_kategori' => ['nullable', 'integer', 'exists:kategori_lomba,id_kategori'],
        ]);

        $query = Lomba::query()
            ->with(['pengajuan.kategori', 'pengajuan.penyelenggara', 'pengajuan.informasiTambahan'])
            ->withCount([
                'pendaftaran as jumlah_peserta' => function ($query) {
                    $query->where('status_pendaftaran', 'Diterima');
                },
                // Total pendaftaran yang telah diajukan, termasuk ditolak.
                // Draft tidak dihitung karena belum diajukan.
                'pendaftaran as jumlah_pendaftar' => function ($query) {
                    $query->whereIn('status_pendaftaran', ['Menunggu', 'Diterima', 'Ditolak']);
                },
            ])
            ->where('status_lomba', 'Aktif')
            ->whereHas('pengajuan', fn ($query) => $query->where('status_pengajuan', 'Disetujui'));

        if (!empty($validated['search'])) {
            $search = $validated['search'];
            $query->whereHas('pengajuan', fn ($query) => $query->where('nama_lomba', 'like', '%' . $search . '%'));
        }

        if (!empty($validated['id_kategori'])) {
            $kategoriId = $validated['id_kategori'];
            $query->whereHas('pengajuan', fn ($query) => $query->where('id_kategori', $kategoriId));
        }

        $items = $query->orderByDesc('id_lomba')->get();

        return response()->json([
            'pesan' => 'Daftar lomba berhasil diambil.',
            'data' => $items->map(fn (Lomba $item) => $this->formatLomba($item))->values(),
        ], 200);
    }

    /** GET /api/lomba/{id} */
    public function show(int $id): JsonResponse
    {
        app(LombaLifecycleService::class)->sync();

        $lomba = Lomba::query()
            ->with(['pengajuan.kategori', 'pengajuan.penyelenggara', 'pengajuan.informasiTambahan', 'penghentian'])
            ->withCount([
                'pendaftaran as jumlah_peserta' => function ($query) {
                    $query->where('status_pendaftaran', 'Diterima');
                },
                // Total pendaftaran yang telah diajukan, termasuk ditolak.
                // Draft tidak dihitung karena belum diajukan.
                'pendaftaran as jumlah_pendaftar' => function ($query) {
                    $query->whereIn('status_pendaftaran', ['Menunggu', 'Diterima', 'Ditolak']);
                },
            ])
            // Detail arsip tetap dapat diakses; filter Aktif hanya untuk katalog.
            ->whereHas('pengajuan', fn ($query) => $query->where('status_pengajuan', 'Disetujui'))
            ->findOrFail($id);

        return response()->json([
            'pesan' => 'Detail lomba berhasil diambil.',
            'data' => $this->formatLomba($lomba),
        ], 200);
    }

    private function formatLomba(Lomba $lomba): array
    {
        $pengajuan = $lomba->pengajuan;
        $kategori = $pengajuan->kategori;
        $penyelenggara = $pengajuan->penyelenggara;

        $informasiTambahan = $pengajuan->informasiTambahan
            ->sortBy('urutan')
            ->values()
            ->map(fn (InformasiLomba $info) => [
                'id_informasi' => $info->id_informasi,
                'kelompok_informasi' => $info->kelompok_informasi,
                'label_informasi' => $info->label_informasi,
                'nilai_informasi' => $info->nilai_informasi,
                'urutan' => $info->urutan,
            ])->all();

        return [
            'id_lomba' => $lomba->id_lomba,
            'id_pengajuan' => $lomba->id_pengajuan,
            'nama_lomba' => $pengajuan->nama_lomba,
            'deskripsi' => $pengajuan->deskripsi,
            'persyaratan' => $pengajuan->persyaratan,
            'tanggal_mulai_pendaftaran' => $pengajuan->tanggal_mulai_pendaftaran?->format('Y-m-d'),
            'batas_pendaftaran' => $pengajuan->batas_pendaftaran?->format('Y-m-d'),
            'tanggal_pelaksanaan' => $pengajuan->tanggal_pelaksanaan?->format('Y-m-d'),
            'tanggal_selesai_pelaksanaan' => ($pengajuan->tanggal_selesai_pelaksanaan ?? $pengajuan->tanggal_pelaksanaan)?->format('Y-m-d'),
            'metode_pelaksanaan' => $pengajuan->metode_pelaksanaan,
            'detail_pelaksanaan' => $pengajuan->detail_pelaksanaan,
            // Tetap disediakan untuk halaman lama yang masih memakai key ini.
            'lokasi_pendaftaran' => $pengajuan->lokasi_pendaftaran,
            'biaya' => $pengajuan->biaya,
            'hadiah' => $pengajuan->hadiah,
            'kuota_peserta' => $pengajuan->kuota_peserta,
            'jumlah_peserta' => (int) ($lomba->jumlah_peserta ?? 0),
            'jumlah_pendaftar' => (int) ($lomba->jumlah_pendaftar ?? 0),
            'kontak_penyelenggara' => $pengajuan->kontak_penyelenggara,
            'poster_lomba' => $pengajuan->poster_lomba,
            'poster_url' => $pengajuan->poster_lomba
                ? url('/api/poster-lomba/' . rawurlencode(basename($pengajuan->poster_lomba)))
                : null,
            'status_lomba' => $lomba->status_efektif,
            'jenis_tindakan' => $lomba->penghentian?->jenis_tindakan,
            'alasan_penghentian' => $lomba->penghentian?->alasan,
            'dihentikan_at' => $lomba->penghentian?->dihentikan_at?->toIso8601String(),
            'kategori' => $kategori ? [
                'id_kategori' => $kategori->id_kategori,
                'nama_kategori' => $kategori->nama_kategori,
            ] : null,
            'penyelenggara' => $penyelenggara ? [
                'username' => $penyelenggara->username,
            ] : null,
            'informasi_tambahan' => $informasiTambahan,
        ];
    }
}