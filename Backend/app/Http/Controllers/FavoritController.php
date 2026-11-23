<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FavoritController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user) return response()->json(['pesan' => 'Harus login.'], 401);

        $rows = DB::table('favorit_lomba as f')
            ->join('lomba as l', 'l.id_lomba', '=', 'f.id_lomba')
            ->join('pengajuan_lomba as p', 'p.id_pengajuan', '=', 'l.id_pengajuan')
            ->leftJoin('kategori_lomba as k', 'k.id_kategori', '=', 'p.id_kategori')
            ->leftJoin('users as u', 'u.id_user', '=', 'p.id_user')
            ->where('f.id_user', '=', $user->id_user)
            ->select([
                'l.id_lomba','l.id_pengajuan','l.status_lomba',
                'p.nama_lomba','p.deskripsi','p.poster_lomba',
                'p.tanggal_pelaksanaan','p.batas_pendaftaran','p.biaya',
                'p.kuota_peserta', 'p.status_pengajuan',
                'k.nama_kategori','u.username as nama_penyelenggara'
            ])
            ->selectSub(
                DB::table('pendaftaran as pd')
                    ->selectRaw('COUNT(*)')
                    ->whereColumn('pd.id_lomba', 'l.id_lomba')
                    ->where('pd.status_pendaftaran', 'Diterima'),
                'jumlah_peserta'
            )
            ->orderByDesc('f.created_at')->get();

        $data = $rows->map(function ($row) {
            return [
                'id_lomba' => (int) $row->id_lomba,
                'id_pengajuan' => (int) $row->id_pengajuan,
                'nama_lomba' => $row->nama_lomba,
                'poster_lomba' => $row->poster_lomba,
                'tanggal_pelaksanaan' => $row->tanggal_pelaksanaan,
                'batas_pendaftaran' => $row->batas_pendaftaran,
                'biaya' => $row->biaya,
                'kuota_peserta' => $row->kuota_peserta,
                'jumlah_peserta' => (int) $row->jumlah_peserta,
                'status_lomba' => $row->status_lomba,
                'kategori' => ['nama_kategori' => $row->nama_kategori],
                'penyelenggara' => ['username' => $row->nama_penyelenggara],
            ];
        });
        return response()->json(['pesan' => 'Favorit dimuat.', 'data' => $data]);
    }

    public function store(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if (!$user) return response()->json(['pesan' => 'Harus login.'], 401);
        $exists = DB::table('lomba')->where('id_lomba', $id)->exists();
        if (!$exists) return response()->json(['pesan' => 'Lomba tidak ditemukan.'], 404);
        DB::table('favorit_lomba')->insertOrIgnore([
            'id_user' => $user->id_user, 'id_lomba' => $id,
            'created_at' => now(),
        ]);
        return response()->json(['pesan' => 'Lomba ditambahkan ke favorit.', 'favorit' => true]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if (!$user) return response()->json(['pesan' => 'Harus login.'], 401);
        DB::table('favorit_lomba')
            ->where('id_user', $user->id_user)
            ->where('id_lomba', $id)->delete();
        return response()->json(['pesan' => 'Lomba dihapus dari favorit.', 'favorit' => false]);
    }
}