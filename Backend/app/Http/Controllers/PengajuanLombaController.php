<?php

namespace App\Http\Controllers;

use App\Models\FormField;
use App\Models\InformasiLomba;
use App\Models\Lomba;
use App\Models\Notifikasi;
use App\Models\PengajuanLomba;
use App\Models\User;
use App\Services\LombaLifecycleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\ValidationException;
use Throwable;

class PengajuanLombaController extends Controller
{
    /** GET /api/pengajuan-lomba/saya */
    public function mine(Request $request): JsonResponse
    {
        app(LombaLifecycleService::class)->sync();

        $user = $request->user();
        if (!$user) {
            return response()->json(['pesan' => 'Silakan login terlebih dahulu.'], 401);
        }

        $items = PengajuanLomba::query()
            ->with([
                'kategori',
                'penyelenggara',
                'lomba' => function ($query) {
                    $query->withCount([
                        'pendaftaran as jumlah_peserta_diterima' => fn ($q) => $q->where('status_pendaftaran', 'Diterima'),
                        'pendaftaran as jumlah_peserta_menunggu' => fn ($q) => $q->where('status_pendaftaran', 'Menunggu'),
                        'pendaftaran as jumlah_peserta_ditolak' => fn ($q) => $q->where('status_pendaftaran', 'Ditolak'),
                    ]);
                },
                'formFields',
                'informasiTambahan',
            ])
            ->where('id_user', $user->id_user)
            ->orderByDesc('tanggal_pengajuan')
            ->orderByDesc('id_pengajuan')
            ->get();

        return response()->json([
            'pesan' => 'Daftar pengajuan berhasil diambil.',
            'data' => $items->map(fn (PengajuanLomba $item) => $this->formatPengajuan($item))->values(),
        ], 200);
    }

    /** POST /api/pengajuan-lomba */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['pesan' => 'Silakan login terlebih dahulu.'], 401);
        }

        $data = $request->validate([
            'id_kategori' => ['required', 'integer', 'exists:kategori_lomba,id_kategori'],
            'nama_lomba' => ['required', 'string', 'max:200'],
            'deskripsi' => ['required', 'string', 'max:10000'],
            'tanggal_mulai_pendaftaran' => ['required', 'date_format:Y-m-d', 'after_or_equal:' . now('Asia/Jayapura')->toDateString()],
            'batas_pendaftaran' => ['required', 'date_format:Y-m-d', 'after_or_equal:tanggal_mulai_pendaftaran'],
            'tanggal_pelaksanaan' => ['required', 'date_format:Y-m-d', 'after_or_equal:batas_pendaftaran'],
            'tanggal_selesai_pelaksanaan' => ['required', 'date_format:Y-m-d', 'after_or_equal:tanggal_pelaksanaan'],
            'metode_pelaksanaan' => ['required', 'in:Online,Offline'],
            'detail_pelaksanaan' => ['required', 'string', 'max:500'],
            'biaya' => ['required', 'numeric', 'min:0', 'max:9999999999.99'],
            'kuota_peserta' => ['nullable', 'integer', 'min:1'],
            'poster_lomba' => ['required', 'image', 'mimes:jpg,jpeg,png', 'max:5120'],

            'informasi_tambahan' => ['nullable', 'array', 'max:30'],
            'informasi_tambahan.*.label_informasi' => ['required', 'string', 'max:150'],
            'informasi_tambahan.*.nilai_informasi' => ['required', 'string', 'max:5000'],
            'informasi_tambahan.*.urutan' => ['nullable', 'integer', 'min:1'],

            'form_fields' => ['required', 'array', 'min:1', 'max:30'],
            'form_fields.*.nama_field' => ['required', 'string', 'max:100'],
            'form_fields.*.tipe_field' => ['required', 'in:Text,Textarea,Number,Dropdown,Date,File,Email,Phone'],
            'form_fields.*.placeholder' => ['nullable', 'string', 'max:255'],
            'form_fields.*.opsi_field' => ['nullable', 'array', 'max:30'],
            'form_fields.*.opsi_field.*' => ['required', 'string', 'max:100'],
            'form_fields.*.wajib' => ['required', 'boolean'],
        ]);


        $formFields = $this->prepareFormFields($data['form_fields']);
        foreach ($formFields as $index => $field) {
            if ($field['tipe_field'] === 'Dropdown' && empty($field['opsi_field'])) {
                throw ValidationException::withMessages([
                    "form_fields.$index.opsi_field" => 'Dropdown harus memiliki minimal satu pilihan.',
                ]);
            }
        }

        if (!$request->hasFile('poster_lomba') || !$request->file('poster_lomba')->isValid()) {
            return response()->json(['pesan' => 'Poster tidak valid atau gagal diunggah.'], 422);
        }

        $disk = Storage::disk('public');
        $disk->makeDirectory('poster-lomba');

        try {
            $posterPath = $request->file('poster_lomba')->store('poster-lomba', 'public');
        } catch (Throwable $exception) {
            report($exception);
            return response()->json(['pesan' => 'Poster gagal disimpan. Periksa konfigurasi storage Laravel.'], 500);
        }

        if (!is_string($posterPath) || $posterPath === '' || !$disk->exists($posterPath)) {
            return response()->json(['pesan' => 'File poster tidak ditemukan setelah disimpan.'], 500);
        }

        $biaya = (float) $data['biaya'];
        $detail = trim($data['detail_pelaksanaan']);

        try {
            $pengajuan = DB::transaction(function () use ($data, $user, $posterPath, $formFields, $biaya, $detail) {
                $pengajuan = PengajuanLomba::create([
                    'id_user' => $user->id_user,
                    'id_kategori' => (int) $data['id_kategori'],
                    'nama_lomba' => trim($data['nama_lomba']),
                    'deskripsi' => trim($data['deskripsi']),
                    'persyaratan' => null,
                    'tanggal_mulai_pendaftaran' => $data['tanggal_mulai_pendaftaran'],
                    'batas_pendaftaran' => $data['batas_pendaftaran'],
                    'tanggal_pelaksanaan' => $data['tanggal_pelaksanaan'],
                    'tanggal_selesai_pelaksanaan' => $data['tanggal_selesai_pelaksanaan'],
                    'metode_pelaksanaan' => $data['metode_pelaksanaan'],
                    'detail_pelaksanaan' => $detail,
                    // Diisi juga agar aplikasi lama yang membaca kolom ini tetap kompatibel.
                    'lokasi_pendaftaran' => $detail,
                    'biaya' => $biaya,
                    'hadiah' => null,
                    'kuota_peserta' => $data['kuota_peserta'] ?? null,
                    'kontak_penyelenggara' => null,
                    'poster_lomba' => $posterPath,
                    'status_pengajuan' => 'Menunggu',
                    'catatan_admin' => null,
                    'tanggal_pengajuan' => now(),
                ]);

                foreach (($data['informasi_tambahan'] ?? []) as $index => $info) {
                    InformasiLomba::create([
                        'id_pengajuan' => $pengajuan->id_pengajuan,
                        'kelompok_informasi' => 'Informasi Tambahan',
                        'label_informasi' => trim($info['label_informasi']),
                        'nilai_informasi' => trim($info['nilai_informasi']),
                        'urutan' => $info['urutan'] ?? ($index + 1),
                    ]);
                }

                foreach ($formFields as $index => $field) {
                    FormField::create([
                        'id_pengajuan' => $pengajuan->id_pengajuan,
                        'nama_field' => $field['nama_field'],
                        'placeholder' => $field['placeholder'],
                        'tipe_field' => $field['tipe_field'],
                        'opsi_field' => $field['opsi_field'],
                        'wajib' => $field['wajib'],
                        'urutan' => $index + 1,
                        'is_default' => $field['is_default'],
                    ]);
                }

                // TL_PATCH3_ATOMIC_NOTIFICATIONS: ikut dalam transaksi pengajuan.
                Notifikasi::create([
                    'id_user' => $user->id_user,
                    'judul' => 'Pengajuan Lomba Berhasil Dikirim',
                    'pesan' => 'Pengajuan lomba "' . $pengajuan->nama_lomba . '" berhasil dikirim dan menunggu verifikasi.',
                    'tipe' => 'pengajuan',
                    'data' => ['id_pengajuan' => $pengajuan->id_pengajuan],
                ]);

                $admins = User::query()
                    ->whereRaw("LOWER(role) = 'administrator'")
                    ->get(['id_user', 'username']);
                $namaPengaju = trim((string) $user->username) ?: 'Pengguna #' . $user->id_user;

                foreach ($admins as $admin) {
                    Notifikasi::create([
                        'id_user' => $admin->id_user,
                        'judul' => 'Pengajuan Lomba Baru',
                        'pesan' => 'Pengguna ' . $namaPengaju . ' mengajukan lomba "' . $pengajuan->nama_lomba . '". Menunggu verifikasi administrator.',
                        'tipe' => 'pengajuan',
                        'data' => [
                            'id_pengajuan' => $pengajuan->id_pengajuan,
                            'id_pengaju' => $user->id_user,
                            'nama_pengaju' => $namaPengaju,
                            'nama_lomba' => $pengajuan->nama_lomba,
                        ],
                    ]);
                }

                return $pengajuan;
            });
        } catch (Throwable $exception) {
            $disk->delete($posterPath);
            report($exception);
            return response()->json(['pesan' => 'Pengajuan gagal disimpan. Periksa log Laravel.'], 500);
        }

        return response()->json([
            'pesan' => 'Pengajuan lomba berhasil dikirim dan menunggu verifikasi admin.',
            'data' => [
                'id_pengajuan' => $pengajuan->id_pengajuan,
                'nama_lomba' => $pengajuan->nama_lomba,
                'status_pengajuan' => $pengajuan->status_pengajuan,
                'poster_lomba' => $pengajuan->poster_lomba,
                'poster_url' => $this->posterUrl($pengajuan->poster_lomba),
            ],
        ], 201);
    }

    private function prepareFormFields(array $fields): array
    {
        $nameField = null;
        $others = [];

        foreach ($fields as $field) {
            $normalized = strtolower(trim($field['nama_field']));
            if ($nameField === null && in_array($normalized, ['nama', 'nama lengkap'], true)) {
                $nameField = $field;
                continue;
            }
            if (in_array($normalized, ['nama', 'nama lengkap'], true)) {
                continue;
            }
            $others[] = $field;
        }

        $nameField ??= [
            'placeholder' => 'Masukkan nama lengkap',
        ];

        $result = [[
            'nama_field' => 'Nama',
            'placeholder' => $nameField['placeholder'] ?? 'Masukkan nama lengkap',
            'tipe_field' => 'Text',
            'opsi_field' => null,
            'wajib' => true,
            'is_default' => true,
        ]];

        foreach ($others as $field) {
            $options = $field['opsi_field'] ?? [];
            if (!is_array($options)) {
                $options = [];
            }
            $options = array_values(array_unique(array_filter(array_map(
                fn ($option) => trim((string) $option),
                $options
            ), fn ($option) => $option !== '')));

            $result[] = [
                'nama_field' => trim($field['nama_field']),
                'placeholder' => isset($field['placeholder']) ? trim($field['placeholder']) : null,
                'tipe_field' => $field['tipe_field'],
                'opsi_field' => $field['tipe_field'] === 'Dropdown' ? $options : null,
                'wajib' => (bool) $field['wajib'],
                'is_default' => false,
            ];
        }

        if (count($result) > 30) {
            throw ValidationException::withMessages([
                'form_fields' => 'Maksimal 30 field termasuk field Nama.',
            ]);
        }

        return $result;
    }

    /** GET /api/admin/pengajuan-lomba */
    public function adminIndex(Request $request): JsonResponse
    {
        app(LombaLifecycleService::class)->sync();

        $user = $request->user();
        if (!$user || strtolower((string) $user->role) !== 'administrator') {
            return response()->json(['pesan' => 'Akses hanya untuk administrator.'], 403);
        }

        $items = PengajuanLomba::query()
            ->with(['kategori', 'penyelenggara', 'formFields', 'informasiTambahan', 'lomba'])
            ->orderByRaw("CASE WHEN LOWER(status_pengajuan) = 'menunggu' THEN 0 ELSE 1 END")
            ->orderByDesc('tanggal_pengajuan')
            ->get();

        return response()->json([
            'pesan' => 'Daftar pengajuan lomba berhasil diambil.',
            'data' => $items->map(fn (PengajuanLomba $item) => $this->formatPengajuan($item))->values(),
        ], 200);
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
            $pengajuan = PengajuanLomba::query()->whereKey($id)->lockForUpdate()->first();
            if (!$pengajuan) {
                return ['error' => 'Pengajuan lomba tidak ditemukan.', 'status' => 404];
            }
            if (strtolower((string) $pengajuan->status_pengajuan) !== 'menunggu') {
                return ['error' => 'Pengajuan ini sudah diproses sebelumnya.', 'status' => 409];
            }
            if ($data['keputusan'] === 'Disetujui' && !$pengajuan->formFields()->exists()) {
                return ['error' => 'Pengajuan belum memiliki formulir pendaftaran.', 'status' => 422];
            }

            $pengajuan->status_pengajuan = $data['keputusan'];
            $pengajuan->catatan_admin = isset($data['catatan_admin']) ? trim($data['catatan_admin']) : null;
            $pengajuan->save();

            if ($data['keputusan'] === 'Disetujui') {
                Lomba::query()->updateOrCreate(
                    ['id_pengajuan' => $pengajuan->id_pengajuan],
                    ['status_lomba' => 'Aktif']
                );
            }

            // TL_PATCH3_ATOMIC_NOTIFICATIONS: status dan notifikasi satu transaksi.
            $processed = $pengajuan->fresh();
            Notifikasi::create([
                'id_user' => $processed->id_user,
                'judul' => $data['keputusan'] === 'Disetujui' ? 'Pengajuan Lomba Disetujui' : 'Pengajuan Lomba Ditolak',
                'pesan' => $data['keputusan'] === 'Disetujui'
                    ? 'Pengajuan lomba "' . $processed->nama_lomba . '" telah disetujui dan diterbitkan.'
                    : 'Pengajuan lomba "' . $processed->nama_lomba . '" ditolak.' . (!empty($processed->catatan_admin) ? ' Catatan admin: ' . $processed->catatan_admin : ''),
                'tipe' => strtolower($data['keputusan']),
                'data' => ['id_pengajuan' => $processed->id_pengajuan],
            ]);

            return ['pengajuan' => $pengajuan->fresh()];
        });

        if (isset($result['error'])) {
            return response()->json(['pesan' => $result['error']], $result['status']);
        }

        app(LombaLifecycleService::class)->sync();

        $processed = $result['pengajuan'];
        return response()->json([
            'pesan' => $data['keputusan'] === 'Disetujui'
                ? 'Pengajuan lomba berhasil disetujui dan diterbitkan.'
                : 'Pengajuan lomba berhasil ditolak.',
            'data' => [
                'id_pengajuan' => $processed->id_pengajuan,
                'nama_lomba' => $processed->nama_lomba,
                'status_pengajuan' => $processed->status_pengajuan,
                'catatan_admin' => $processed->catatan_admin,
            ],
        ], 200);
    }

    private function formatPengajuan(PengajuanLomba $item): array
    {
        $formFields = $item->formFields->sortBy('urutan')->values()->map(fn (FormField $field) => [
            'id_field' => $field->id_field,
            'nama_field' => $field->nama_field,
            'placeholder' => $field->placeholder,
            'tipe_field' => $field->tipe_field,
            'opsi_field' => $field->opsi_field,
            'wajib' => (bool) $field->wajib,
            'is_default' => (bool) $field->is_default,
            'urutan' => $field->urutan,
        ])->all();

        $info = $item->informasiTambahan->sortBy('urutan')->values()->map(fn (InformasiLomba $row) => [
            'id_informasi' => $row->id_informasi,
            'kelompok_informasi' => $row->kelompok_informasi,
            'label_informasi' => $row->label_informasi,
            'nilai_informasi' => $row->nilai_informasi,
            'urutan' => $row->urutan,
        ])->all();

        return [
            'id_pengajuan' => $item->id_pengajuan,
            'id_user' => $item->id_user,
            'id_kategori' => $item->id_kategori,
            'nama_lomba' => $item->nama_lomba,
            'deskripsi' => $item->deskripsi,
            'persyaratan' => $item->persyaratan,
            'tanggal_mulai_pendaftaran' => $item->tanggal_mulai_pendaftaran?->format('Y-m-d'),
            'batas_pendaftaran' => $item->batas_pendaftaran?->format('Y-m-d'),
            'tanggal_pelaksanaan' => $item->tanggal_pelaksanaan?->format('Y-m-d'),
            'tanggal_selesai_pelaksanaan' => ($item->tanggal_selesai_pelaksanaan ?? $item->tanggal_pelaksanaan)?->format('Y-m-d'),
            'metode_pelaksanaan' => $item->metode_pelaksanaan,
            'detail_pelaksanaan' => $item->detail_pelaksanaan,
            'lokasi_pendaftaran' => $item->lokasi_pendaftaran,
            'biaya' => $item->biaya,
            'hadiah' => $item->hadiah,
            'kuota_peserta' => $item->kuota_peserta,
            'kontak_penyelenggara' => $item->kontak_penyelenggara,
            'poster_lomba' => $item->poster_lomba,
            'poster_url' => $this->posterUrl($item->poster_lomba),
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
            'lomba' => $item->lomba ? [
                'id_lomba' => $item->lomba->id_lomba,
                'status_lomba' => $item->lomba->status_efektif,
                'jumlah_peserta_diterima' => (int) ($item->lomba->jumlah_peserta_diterima ?? 0),
                'jumlah_peserta_menunggu' => (int) ($item->lomba->jumlah_peserta_menunggu ?? 0),
                'jumlah_peserta_ditolak' => (int) ($item->lomba->jumlah_peserta_ditolak ?? 0),
            ] : null,
            'form_fields' => $formFields,
            'informasi_tambahan' => $info,
        ];
    }

    private function posterUrl(?string $path): ?string
    {
        if (!$path) return null;
        return url('/api/poster-lomba/' . rawurlencode(basename($path)));
    }
}