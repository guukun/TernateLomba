<?php

namespace App\Http\Controllers;

use App\Models\PengajuanLomba;
use App\Models\Lomba;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Throwable;

class PengajuanLombaController extends Controller
{
    /** GET /api/pengajuan-lomba/saya */
    public function mine(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user) {
            return response()->json([
                'pesan' => 'Silakan login untuk melihat pengajuan lomba.',
            ], 401);
        }

        $items = PengajuanLomba::query()
            ->with(['kategori:id_kategori,nama_kategori', 'lomba:id_lomba,id_pengajuan,status_lomba'])
            ->where('id_user', $user->id_user)
            ->orderByDesc('tanggal_pengajuan')
            ->orderByDesc('id_pengajuan')
            ->get();

        return response()->json([
            'pesan' => 'Daftar lomba yang dibuat berhasil diambil.',
            'data' => $items->map(function (PengajuanLomba $item): array {
                return [
                    'id_pengajuan' => $item->id_pengajuan,
                    'id_kategori' => $item->id_kategori,
                    'nama_lomba' => $item->nama_lomba,
                    'deskripsi' => $item->deskripsi,
                    'persyaratan' => $item->persyaratan,
                    'tanggal_pelaksanaan' => $item->tanggal_pelaksanaan?->format('Y-m-d'),
                    'batas_pendaftaran' => $item->batas_pendaftaran?->format('Y-m-d'),
                    'lokasi_pendaftaran' => $item->lokasi_pendaftaran,
                    'biaya' => $item->biaya,
                    'hadiah' => $item->hadiah,
                    'kuota_peserta' => $item->kuota_peserta,
                    'kontak_penyelenggara' => $item->kontak_penyelenggara,
                    'poster_lomba' => $item->poster_lomba,
                    'status_pengajuan' => $item->status_pengajuan,
                    'catatan_admin' => $item->catatan_admin,
                    'tanggal_pengajuan' => $item->tanggal_pengajuan?->toISOString(),
                    'kategori' => $item->kategori ? [
                        'id_kategori' => $item->kategori->id_kategori,
                        'nama_kategori' => $item->kategori->nama_kategori,
                    ] : null,
                    'lomba' => $item->lomba ? [
                        'id_lomba' => $item->lomba->id_lomba,
                        'status_lomba' => $item->lomba->status_lomba,
                    ] : null,
                ];
            })->values(),
        ], 200);
    }

    /** POST /api/pengajuan-lomba */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user) {
            return response()->json([
                'pesan' => 'Silakan login untuk mengajukan lomba.',
            ], 401);
        }

        $data = $request->validate([
            'id_kategori' => ['required', 'integer', 'exists:kategori_lomba,id_kategori'],
            'nama_lomba' => ['required', 'string', 'max:200'],
            'deskripsi' => ['required', 'string', 'max:10000'],
            'persyaratan' => ['nullable', 'string', 'max:10000'],
            'tanggal_pelaksanaan' => ['required', 'date_format:Y-m-d', 'after_or_equal:today'],
            'batas_pendaftaran' => ['required', 'date_format:Y-m-d', 'after_or_equal:today', 'before_or_equal:tanggal_pelaksanaan'],
            'lokasi_pendaftaran' => ['required', 'string', 'max:255'],
            'biaya' => ['required', 'numeric', 'min:0'],
            'hadiah' => ['nullable', 'string', 'max:10000'],
            'kuota_peserta' => ['nullable', 'integer', 'min:1'],
            'kontak_penyelenggara' => ['required', 'string', 'max:100'],
            'poster_lomba' => ['nullable', 'image', 'mimes:jpg,jpeg,png', 'max:5120'],
        ]);

        $posterPath = null;
        if ($request->hasFile('poster_lomba')) {
            $posterPath = $request->file('poster_lomba')->store('poster-lomba', 'public');
            if (!$posterPath) {
                return response()->json([
                    'pesan' => 'Poster gagal disimpan. Silakan coba lagi.',
                ], 500);
            }
        }

        try {
            $pengajuan = PengajuanLomba::create([
                'id_user' => $user->id_user,
                'id_kategori' => (int) $data['id_kategori'],
                'nama_lomba' => trim($data['nama_lomba']),
                'deskripsi' => trim($data['deskripsi']),
                'persyaratan' => isset($data['persyaratan']) ? trim($data['persyaratan']) : null,
                'tanggal_pelaksanaan' => $data['tanggal_pelaksanaan'],
                'batas_pendaftaran' => $data['batas_pendaftaran'],
                'lokasi_pendaftaran' => trim($data['lokasi_pendaftaran']),
                'biaya' => $data['biaya'],
                'hadiah' => isset($data['hadiah']) ? trim($data['hadiah']) : null,
                'kuota_peserta' => $data['kuota_peserta'] ?? null,
                'kontak_penyelenggara' => trim($data['kontak_penyelenggara']),
                'poster_lomba' => $posterPath,
                'status_pengajuan' => 'Menunggu',
                'catatan_admin' => null,
                'tanggal_pengajuan' => now(),
            ]);
        } catch (Throwable $exception) {
            if ($posterPath) {
                Storage::disk('public')->delete($posterPath);
            }
            throw $exception;
        }

        return response()->json([
            'pesan' => 'Pengajuan lomba berhasil dikirim dan menunggu verifikasi admin.',
            'data' => [
                'id_pengajuan' => $pengajuan->id_pengajuan,
                'nama_lomba' => $pengajuan->nama_lomba,
                'status_pengajuan' => $pengajuan->status_pengajuan,
                'tanggal_pengajuan' => $pengajuan->tanggal_pengajuan?->toISOString(),
            ],
        ], 201);
    }

    /** GET /api/admin/pengajuan-lomba */
    public function adminIndex(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user || strtolower((string) $user->role) !== 'administrator') {
            return response()->json(['pesan' => 'Akses hanya untuk administrator.'], 403);
        }

        $items = PengajuanLomba::query()
            ->with(['kategori:id_kategori,nama_kategori', 'penyelenggara:id_user,username'])
            ->orderByRaw("CASE WHEN LOWER(status_pengajuan) = 'menunggu' THEN 0 ELSE 1 END")
            ->orderByDesc('tanggal_pengajuan')
            ->get();

        return response()->json([
            'pesan' => 'Daftar pengajuan lomba berhasil diambil.',
            'data' => $items->map(fn (PengajuanLomba $item) => [
                'id_pengajuan' => $item->id_pengajuan,
                'nama_lomba' => $item->nama_lomba,
                'deskripsi' => $item->deskripsi,
                'persyaratan' => $item->persyaratan,
                'tanggal_pelaksanaan' => $item->tanggal_pelaksanaan?->format('Y-m-d'),
                'batas_pendaftaran' => $item->batas_pendaftaran?->format('Y-m-d'),
                'lokasi_pendaftaran' => $item->lokasi_pendaftaran,
                'biaya' => $item->biaya,
                'hadiah' => $item->hadiah,
                'kuota_peserta' => $item->kuota_peserta,
                'kontak_penyelenggara' => $item->kontak_penyelenggara,
                'poster_lomba' => $item->poster_lomba,
                'status_pengajuan' => $item->status_pengajuan,
                'catatan_admin' => $item->catatan_admin,
                'tanggal_pengajuan' => $item->tanggal_pengajuan?->toISOString(),
                'kategori' => $item->kategori ? [
                    'id_kategori' => $item->kategori->id_kategori,
                    'nama_kategori' => $item->kategori->nama_kategori,
                ] : null,
                'penyelenggara' => $item->penyelenggara ? [
                    'id_user' => $item->penyelenggara->id_user,
                    'username' => $item->penyelenggara->username,
                ] : null,
            ])->values(),
        ]);
    }

    /** PATCH /api/admin/pengajuan-lomba/{id}/keputusan */
    public function decide(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if (!$user || strtolower((string) $user->role) !== 'administrator') {
            return response()->json(['pesan' => 'Akses hanya untuk administrator.'], 403);
        }

        $data = $request->validate([
            'keputusan' => ['required', 'in:Disetujui,Ditolak'],
            'catatan_admin' => ['nullable', 'string', 'max:5000'],
        ]);

        $result = DB::transaction(function () use ($id, $data) {
            $pengajuan = PengajuanLomba::query()
                ->whereKey($id)
                ->lockForUpdate()
                ->first();

            if (!$pengajuan) {
                return ['error' => 'Pengajuan lomba tidak ditemukan.', 'status' => 404];
            }

            if (strtolower((string) $pengajuan->status_pengajuan) !== 'menunggu') {
                return [
                    'error' => 'Pengajuan ini sudah diproses sebelumnya.',
                    'status' => 409,
                ];
            }

            $pengajuan->status_pengajuan = $data['keputusan'];
            $pengajuan->catatan_admin = isset($data['catatan_admin'])
                ? trim($data['catatan_admin'])
                : null;
            $pengajuan->save();

            if ($data['keputusan'] === 'Disetujui') {
                Lomba::query()->updateOrCreate(
                    ['id_pengajuan' => $pengajuan->id_pengajuan],
                    ['status_lomba' => 'Aktif']
                );
            }

            return ['pengajuan' => $pengajuan->fresh()];
        });

        if (isset($result['error'])) {
            return response()->json(['pesan' => $result['error']], $result['status']);
        }

        return response()->json([
            'pesan' => $data['keputusan'] === 'Disetujui'
                ? 'Pengajuan lomba berhasil disetujui dan diterbitkan.'
                : 'Pengajuan lomba berhasil ditolak.',
            'data' => [
                'id_pengajuan' => $result['pengajuan']->id_pengajuan,
                'nama_lomba' => $result['pengajuan']->nama_lomba,
                'status_pengajuan' => $result['pengajuan']->status_pengajuan,
                'catatan_admin' => $result['pengajuan']->catatan_admin,
            ],
        ]);
    }


}
