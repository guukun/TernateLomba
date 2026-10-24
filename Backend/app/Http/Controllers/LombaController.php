<?php

namespace App\Http\Controllers;
use App\Models\KategoriLomba;
use App\Models\Lomba;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LombaController extends Controller
{
    // GET /api/kategori
    public function kategori(): JsonResponse
    {
        $kategori = KategoriLomba::query()
            ->orderBy('nama_kategori')
            ->get([
                'id_kategori',
                'nama_kategori',
                'deskripsi_kategori',
            ]);

        return response()->json([
            'pesan' => 'Kategori berhasil diambil',
            'data' => $kategori,
        ], 200);
    }

    // GET /api/lomba
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:200'],
            'id_kategori' => [
                'nullable',
                'integer',
                'exists:kategori_lomba,id_kategori',
            ],
        ]);

        $query = Lomba::query()
            ->with([
                'pengajuan.kategori',
                'pengajuan.penyelenggara',
            ])
            ->where('status_lomba', 'Aktif')
            ->whereHas('pengajuan', function ($q) {
                $q->where('status_pengajuan', 'Disetujui');
            });

        if (!empty($validated['search'])) {
            $search = $validated['search'];

            $query->whereHas('pengajuan', function ($q) use ($search) {
                $q->where('nama_lomba', 'like', '%' . $search . '%');
            });
        }

        if (!empty($validated['id_kategori'])) {
            $kategoriId = $validated['id_kategori'];

            $query->whereHas('pengajuan', function ($q) use ($kategoriId) {
                $q->where('id_kategori', $kategoriId);
            });
        }

        $lomba = $query->orderByDesc('id_lomba')->get();

        return response()->json([
            'pesan' => 'Daftar lomba berhasil diambil',
            'data' => $lomba->map(
                fn (Lomba $item) => $this->formatLomba($item)
            )->values(),
        ], 200);
    }

    // GET /api/lomba/{id}
    public function show(int $id): JsonResponse
    {
        $lomba = Lomba::query()
            ->with([
                'pengajuan.kategori',
                'pengajuan.penyelenggara',
            ])
            ->where('status_lomba', 'Aktif')
            ->whereHas('pengajuan', function ($q) {
                $q->where('status_pengajuan', 'Disetujui');
            })
            ->findOrFail($id);

        return response()->json([
            'pesan' => 'Detail lomba berhasil diambil',
            'data' => $this->formatLomba($lomba),
        ], 200);
    }

    private function formatLomba(Lomba $lomba): array
    {
        $pengajuan = $lomba->pengajuan;
        $kategori = $pengajuan->kategori;
        $penyelenggara = $pengajuan->penyelenggara;

        return [
            'id_lomba' => $lomba->id_lomba,
            'id_pengajuan' => $lomba->id_pengajuan,
            'nama_lomba' => $pengajuan->nama_lomba,
            'deskripsi' => $pengajuan->deskripsi,
            'persyaratan' => $pengajuan->persyaratan,
            'tanggal_pelaksanaan' => $pengajuan
                ->tanggal_pelaksanaan?->format('Y-m-d'),
            'batas_pendaftaran' => $pengajuan
                ->batas_pendaftaran?->format('Y-m-d'),
            'lokasi_pendaftaran' => $pengajuan->lokasi_pendaftaran,
            'biaya' => $pengajuan->biaya,
            'hadiah' => $pengajuan->hadiah,
            'kuota_peserta' => $pengajuan->kuota_peserta,
            'kontak_penyelenggara' => $pengajuan->kontak_penyelenggara,
            'poster_lomba' => $pengajuan->poster_lomba,
            'status_lomba' => $lomba->status_lomba,
            'kategori' => [
                'id_kategori' => $kategori->id_kategori,
                'nama_kategori' => $kategori->nama_kategori,
            ],
            'penyelenggara' => [
                'username' => $penyelenggara->username,
            ],
        ];
    }
}
