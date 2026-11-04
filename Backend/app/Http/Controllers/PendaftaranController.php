<?php

namespace App\Http\Controllers;

use App\Models\FormField;
use App\Models\JawabanPendaftaran;
use App\Models\Lomba;
use App\Models\Pendaftaran;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use RuntimeException;
use Throwable;

class PendaftaranController extends Controller
{
    /** Ambil lomba yang masih aktif dan sudah disetujui. */
    private function cariLomba(int $id): Lomba
    {
        return Lomba::query()
            ->with('pengajuan')
            ->where('status_lomba', 'Aktif')
            ->whereHas('pengajuan', function ($query) {
                $query->where('status_pengajuan', 'Disetujui');
            })
            ->findOrFail($id);
    }

    private function batasPendaftaranLewat(mixed $batasPendaftaran): bool
    {
        if (!$batasPendaftaran) {
            return false;
        }

        // Tanggal batas masih berlaku sampai akhir hari yang ditentukan.
        return now()->toDateString() > Carbon::parse($batasPendaftaran)->toDateString();
    }

    /** GET /api/lomba/{id}/form-fields */
    public function formFields(int $id): JsonResponse
    {
        $lomba = $this->cariLomba($id);

        $fields = FormField::query()
            ->where('id_pengajuan', $lomba->id_pengajuan)
            ->orderBy('urutan')
            ->orderBy('id_field')
            ->get([
                'id_field',
                'nama_field',
                'tipe_field',
                'wajib',
                'urutan',
            ]);

        return response()->json([
            'pesan' => 'Formulir berhasil diambil.',
            'id_lomba' => $lomba->id_lomba,
            'data' => $fields,
        ], 200);
    }

    /** POST /api/lomba/{id}/pendaftaran */
    public function store(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['pesan' => 'Autentikasi diperlukan.'], 401);
        }

        $lomba = $this->cariLomba($id);
        $pengajuan = $lomba->pengajuan;

        if ($this->batasPendaftaranLewat($pengajuan->batas_pendaftaran)) {
            return response()->json([
                'pesan' => 'Batas pendaftaran telah berakhir.',
            ], 422);
        }

        if (Pendaftaran::query()
            ->where('id_lomba', $id)
            ->where('id_user', $user->getKey())
            ->exists()) {
            return response()->json([
                'pesan' => 'Anda sudah terdaftar pada lomba ini.',
            ], 409);
        }

        $fields = FormField::query()
            ->where('id_pengajuan', $lomba->id_pengajuan)
            ->orderBy('urutan')
            ->orderBy('id_field')
            ->get();

        if ($fields->isEmpty()) {
            return response()->json([
                'pesan' => 'Formulir lomba belum dikonfigurasi.',
            ], 422);
        }

        $rules = [
            'jawaban' => ['sometimes', 'array'],
            'files' => ['sometimes', 'array'],
        ];

        foreach ($fields as $field) {
            $key = (string) $field->id_field;
            $requiredRule = $field->wajib ? 'required' : 'nullable';

            if ($field->tipe_field === 'File') {
                $rules["files.$key"] = [
                    $requiredRule,
                    'file',
                    'max:5120',
                    'mimes:pdf,jpg,jpeg,png',
                ];
            } else {
                $rules["jawaban.$key"] = [
                    $requiredRule,
                    'string',
                    'max:5000',
                ];
            }
        }

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return response()->json([
                'pesan' => 'Data formulir tidak valid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $jawaban = $request->input('jawaban', []);
        $files = $request->file('files', []);

        $allowedTextIds = $fields
            ->where('tipe_field', 'Text')
            ->pluck('id_field')
            ->map(fn ($value) => (string) $value)
            ->all();

        $allowedFileIds = $fields
            ->where('tipe_field', 'File')
            ->pluck('id_field')
            ->map(fn ($value) => (string) $value)
            ->all();

        foreach (array_keys($jawaban ?? []) as $key) {
            if (!in_array((string) $key, $allowedTextIds, true)) {
                return response()->json([
                    'pesan' => 'Terdapat field jawaban yang tidak dikenal.',
                ], 422);
            }
        }

        foreach (array_keys($files ?? []) as $key) {
            if (!in_array((string) $key, $allowedFileIds, true)) {
                return response()->json([
                    'pesan' => 'Terdapat field file yang tidak dikenal.',
                ], 422);
            }
        }

        $uploadedPaths = [];

        try {
            $pendaftaran = DB::transaction(function () use (
                $id,
                $user,
                $fields,
                $request,
                &$uploadedPaths
            ): Pendaftaran {
                // Mengunci baris lomba agar pemeriksaan kuota tidak berjalan
                // bersamaan tanpa koordinasi saat beberapa peserta mendaftar.
                $lockedLomba = Lomba::query()
                    ->whereKey($id)
                    ->lockForUpdate()
                    ->firstOrFail();

                $lockedLomba->load('pengajuan');
                $lockedPengajuan = $lockedLomba->pengajuan;

                if ($lockedLomba->status_lomba !== 'Aktif') {
                    throw ValidationException::withMessages([
                        'lomba' => 'Lomba sudah tidak aktif dan tidak dapat menerima pendaftaran.',
                    ]);
                }

                if (!$lockedPengajuan || $lockedPengajuan->status_pengajuan !== 'Disetujui') {
                    throw ValidationException::withMessages([
                        'lomba' => 'Pengajuan lomba belum disetujui atau sudah tidak berlaku.',
                    ]);
                }

                if ($this->batasPendaftaranLewat($lockedPengajuan->batas_pendaftaran)) {
                    throw ValidationException::withMessages([
                        'batas_pendaftaran' => 'Batas pendaftaran telah berakhir.',
                    ]);
                }

                $sudahDaftar = Pendaftaran::query()
                    ->where('id_lomba', $lockedLomba->id_lomba)
                    ->where('id_user', $user->getKey())
                    ->exists();

                if ($sudahDaftar) {
                    throw ValidationException::withMessages([
                        'pendaftaran' => 'Anda sudah terdaftar pada lomba ini.',
                    ]);
                }

                $jumlahPeserta = Pendaftaran::query()
                    ->where('id_lomba', $lockedLomba->id_lomba)
                    ->whereIn('status_pendaftaran', ['Menunggu', 'Diterima'])
                    ->count();

                if (
                    $lockedPengajuan->kuota_peserta !== null &&
                    $jumlahPeserta >= (int) $lockedPengajuan->kuota_peserta
                ) {
                    throw ValidationException::withMessages([
                        'kuota' => 'Kuota lomba sudah penuh.',
                    ]);
                }

                $pendaftaran = Pendaftaran::create([
                    'id_lomba' => $lockedLomba->id_lomba,
                    'id_user' => $user->getKey(),
                    'tanggal_pendaftaran' => now(),
                    'status_pendaftaran' => 'Menunggu',
                ]);

                foreach ($fields as $field) {
                    $key = (string) $field->id_field;
                    $value = null;

                    if ($field->tipe_field === 'File') {
                        $file = $request->file("files.$key");

                        if ($file) {
                            $value = $file->store(
                                'pendaftaran/' . $pendaftaran->id_pendaftaran,
                                'local'
                            );

                            if (!is_string($value) || $value === '') {
                                throw new RuntimeException('Berkas gagal disimpan.');
                            }

                            $uploadedPaths[] = $value;
                        }
                    } else {
                        $value = $request->input("jawaban.$key");
                    }

                    if ($value === null || $value === '') {
                        continue;
                    }

                    JawabanPendaftaran::create([
                        'id_pendaftaran' => $pendaftaran->id_pendaftaran,
                        'id_field' => $field->id_field,
                        'jawaban' => $value,
                    ]);
                }

                return $pendaftaran;
            });

            return response()->json([
                'pesan' => 'Pendaftaran berhasil dikirim.',
                'data' => [
                    'id_pendaftaran' => $pendaftaran->id_pendaftaran,
                    'id_lomba' => $pendaftaran->id_lomba,
                    'status_pendaftaran' => $pendaftaran->status_pendaftaran,
                ],
            ], 201);
        } catch (Throwable $exception) {
            // File tidak ikut rollback bersama transaksi SQL, jadi hapus jika
            // penyimpanan database gagal.
            foreach ($uploadedPaths as $path) {
                Storage::disk('local')->delete($path);
            }

            throw $exception;
        }
    }

    /** GET /api/pendaftaran/riwayat */
    public function riwayat(Request $request): JsonResponse
    {
        $user = $request->user();

        $pendaftaran = Pendaftaran::query()
            ->with(['lomba.pengajuan'])
            ->where('id_user', $user->getKey())
            ->orderByDesc('tanggal_pendaftaran')
            ->get();

        return response()->json([
            'pesan' => 'Riwayat pendaftaran berhasil diambil.',
            'data' => $pendaftaran->map(fn (Pendaftaran $item) => [
                'id_pendaftaran' => $item->id_pendaftaran,
                'id_lomba' => $item->id_lomba,
                'nama_lomba' => $item->lomba?->pengajuan?->nama_lomba,
                'tanggal_pendaftaran' => $item->tanggal_pendaftaran,
                'status_pendaftaran' => $item->status_pendaftaran,
            ])->values(),
        ], 200);
    }

    /** GET /api/pendaftaran/{id} */
    public function detail(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $pendaftaran = Pendaftaran::query()
            ->with([
                'lomba.pengajuan',
                'jawabanPendaftaran.formField',
            ])
            ->where('id_pendaftaran', $id)
            ->where('id_user', $user->getKey())
            ->first();

        if (!$pendaftaran) {
            return response()->json([
                'pesan' => 'Pendaftaran tidak ditemukan atau Anda tidak memiliki akses.',
            ], 404);
        }

        $dataJawaban = $pendaftaran->jawabanPendaftaran->map(function (JawabanPendaftaran $jawaban) use ($id) {
            $field = $jawaban->formField;
            $isFile = $field?->tipe_field === 'File';

            return [
                'id_jawaban' => $jawaban->id_jawaban,
                'id_field' => $jawaban->id_field,
                'nama_field' => $field?->nama_field,
                'tipe_field' => $field?->tipe_field,
                'jawaban' => $field && !$isFile ? $jawaban->jawaban : null,
                'file_url' => $isFile
                    ? url('/api/pendaftaran/' . $id . '/jawaban/' . $jawaban->id_jawaban . '/file')
                    : null,
            ];
        })->values();

        return response()->json([
            'pesan' => 'Detail pendaftaran berhasil diambil.',
            'data' => [
                'id_pendaftaran' => $pendaftaran->id_pendaftaran,
                'id_lomba' => $pendaftaran->id_lomba,
                'nama_lomba' => $pendaftaran->lomba?->pengajuan?->nama_lomba,
                'tanggal_pendaftaran' => $pendaftaran->tanggal_pendaftaran,
                'status_pendaftaran' => $pendaftaran->status_pendaftaran,
                'jawaban' => $dataJawaban,
            ],
        ], 200);
    }

    /** GET /api/pendaftaran/{id}/jawaban/{idJawaban}/file */
    public function unduhJawabanFile(Request $request, int $id, int $idJawaban)
    {
        $user = $request->user();

        $jawaban = JawabanPendaftaran::query()
            ->with(['pendaftaran.lomba', 'formField'])
            ->where('id_jawaban', $idJawaban)
            ->whereHas('pendaftaran', function ($query) use ($id, $user) {
                $query->where('id_pendaftaran', $id)
                    ->where('id_user', $user->getKey());
            })
            ->first();

        if (!$jawaban || !$jawaban->pendaftaran || !$jawaban->pendaftaran->lomba) {
            return response()->json([
                'pesan' => 'Dokumen tidak ditemukan atau Anda tidak memiliki akses.',
            ], 404);
        }

        if (
            $jawaban->formField?->tipe_field !== 'File' ||
            (int) $jawaban->formField->id_pengajuan !==
                (int) $jawaban->pendaftaran->lomba->id_pengajuan
        ) {
            return response()->json([
                'pesan' => 'Jawaban tersebut bukan dokumen yang dapat diunduh.',
            ], 404);
        }

        $path = $jawaban->jawaban;
        $expectedPrefix = 'pendaftaran/' . $id . '/';
        $disk = Storage::disk('local');

        if (
            !is_string($path) ||
            !str_starts_with($path, $expectedPrefix) ||
            str_contains($path, '..') ||
            !$disk->exists($path)
        ) {
            return response()->json([
                'pesan' => 'File tidak ditemukan.',
            ], 404);
        }

        return $disk->download($path, basename($path), [
            'Cache-Control' => 'private, no-store',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }
}
