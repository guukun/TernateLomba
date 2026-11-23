<?php
namespace App\Http\Controllers;

use App\Models\KategoriLomba;
use App\Models\Lomba;
use App\Models\Pendaftaran;
use App\Models\PengajuanLomba;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminPanelController extends Controller
{
    private function authorizeAdmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'Administrator', 403, 'Akses khusus administrator.');
    }

    public function overview(Request $request): JsonResponse
    {
        $this->authorizeAdmin($request);
        return response()->json(['data' => [
            'jumlah_kategori' => KategoriLomba::count(),
            'jumlah_pengguna' => User::count(),
            'lomba_aktif' => Lomba::where('status_lomba', 'Aktif')->count(),
            'lomba_selesai' => Lomba::where('status_lomba', 'Selesai')->whereDoesntHave('penghentian')->count(),
            'lomba_dihentikan' => Lomba::whereHas('penghentian', fn ($query) => $query->where('jenis_tindakan', 'Hentikan'))->count(),
            'lomba_dibatalkan' => Lomba::whereHas('penghentian', fn ($query) => $query->where('jenis_tindakan', 'Batalkan'))->count(),
            'pengajuan_menunggu' => PengajuanLomba::where('status_pengajuan', 'Menunggu')->count(),
            'pendaftaran_menunggu' => Pendaftaran::where('status_pendaftaran', 'Menunggu')->count(),
        ]]);
    }

    public function categories(Request $request): JsonResponse
    {
        $this->authorizeAdmin($request);
        return response()->json(['data' => KategoriLomba::query()->orderBy('nama_kategori')
            ->get(['id_kategori', 'nama_kategori', 'deskripsi_kategori'])]);
    }

    public function createCategory(Request $request): JsonResponse
    {
        $this->authorizeAdmin($request);
        $data = $request->validate([
            'nama_kategori' => ['required', 'string', 'max:100', Rule::unique('kategori_lomba', 'nama_kategori')],
            'deskripsi_kategori' => ['nullable', 'string', 'max:500'],
        ]);
        $item = KategoriLomba::create($data);
        return response()->json(['pesan' => 'Kategori berhasil ditambahkan.', 'data' => $item], 201);
    }

    public function updateCategory(Request $request, int $id): JsonResponse
    {
        $this->authorizeAdmin($request);
        $item = KategoriLomba::findOrFail($id);
        $data = $request->validate([
            'nama_kategori' => ['required', 'string', 'max:100', Rule::unique('kategori_lomba', 'nama_kategori')->ignore($id, 'id_kategori')],
            'deskripsi_kategori' => ['nullable', 'string', 'max:500'],
        ]);
        $item->update($data);
        return response()->json(['pesan' => 'Kategori diperbarui.', 'data' => $item]);
    }

    public function deleteCategory(Request $request, int $id): JsonResponse
    {
        $this->authorizeAdmin($request);
        $item = KategoriLomba::findOrFail($id);
        if ($item->pengajuanLomba()->exists()) {
            return response()->json(['pesan' => 'Kategori sudah digunakan lomba sehingga tidak dapat dihapus.'], 409);
        }
        $item->delete();
        return response()->json(['pesan' => 'Kategori dihapus.']);
    }

    public function users(Request $request): JsonResponse
    {
        $this->authorizeAdmin($request);
        $items = User::query()->orderByDesc('id_user')->limit(100)
            ->get(['id_user','username','role','foto_profil']);
        return response()->json(['data' => $items->map(fn (User $u) => [
            'id_user' => $u->id_user, 'username' => $u->username, 'role' => $u->role,
            'foto_profil_url' => $u->foto_profil
                ? url('/api/profile-photo/' . rawurlencode(basename($u->foto_profil))) : null,
        ])]);
    }

    public function lomba(Request $request): JsonResponse
    {
        $this->authorizeAdmin($request);
        $items = Lomba::query()->with(['pengajuan.penyelenggara', 'pengajuan.kategori', 'penghentian'])
            ->orderByDesc('id_lomba')->limit(100)->get();
        return response()->json(['data' => $items->map(fn (Lomba $item) => [
            'id_lomba' => $item->id_lomba,
            'nama_lomba' => $item->pengajuan?->nama_lomba,
            'penyelenggara' => $item->pengajuan?->penyelenggara?->username,
            'status_lomba' => $item->status_efektif,
            'poster_lomba' => $item->pengajuan?->poster_lomba,
            'tanggal_pelaksanaan' => $item->pengajuan?->tanggal_pelaksanaan?->format('Y-m-d'),
            'kategori' => ['nama_kategori' => $item->pengajuan?->kategori?->nama_kategori ?? 'Kompetisi'],
        ])]);
    }
}