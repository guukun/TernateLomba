<?php

namespace App\Http\Controllers;

use App\Models\FormField;
use App\Models\JawabanPendaftaran;
use App\Models\Lomba;
use App\Models\InformasiLomba;
use App\Models\Notifikasi;
use App\Models\Pendaftaran;
use App\Services\LombaLifecycleService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use Illuminate\Validation\Rule;
use RuntimeException;
use Throwable;

class PendaftaranController extends Controller
{
    /** Ambil lomba yang masih aktif dan sudah disetujui. */
    private function cariLomba(int $id): Lomba
    {
        app(LombaLifecycleService::class)->sync();

        return Lomba::query()
            ->with('pengajuan')
            ->where('status_lomba', 'Aktif')
            ->whereHas('pengajuan', function ($query) {
                $query->where('status_pengajuan', 'Disetujui');
            })
            ->findOrFail($id);
    }

    private function pendaftaranBelumDibuka(mixed $tanggalMulai): bool
    {
        return $tanggalMulai && Carbon::now('Asia/Jayapura')->toDateString()
            < Carbon::parse($tanggalMulai)->toDateString();
    }

    private function batasPendaftaranLewat(mixed $batasPendaftaran): bool
    {
        if (!$batasPendaftaran) {
            return false;
        }

        // Kolom batas_pendaftaran merupakan tanggal kalender lokal Ternate (WIT).
        // Pendaftaran dibuka hingga akhir tanggal tersebut, waktu Asia/Jayapura.
        return Carbon::now('Asia/Jayapura')->toDateString()
            > Carbon::parse($batasPendaftaran)->toDateString();
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
                'placeholder',
                'tipe_field',
                'opsi_field',
                'wajib',
                'urutan',
                'is_default',
            ]);

        return response()->json([
            'pesan' => 'Formulir berhasil diambil.',
            'id_lomba' => $lomba->id_lomba,
            'data' => $fields,
        ], 200);
    }

    /**
 * GET /api/lomba/{id}/status-pendaftaran
 * Memeriksa apakah pengguna boleh mendaftar.
 */
public function statusPendaftaran(Request $request, int $id): JsonResponse
{
    $user = $request->user();

    if (!$user) {
        return response()->json([
            'pesan' => 'Autentikasi diperlukan.',
        ], 401);
    }

    // Status pendaftaran harus bisa dibaca untuk lomba arsip juga.
    // Endpoint POST tetap memakai cariLomba() yang mewajibkan Aktif.
    app(LombaLifecycleService::class)->sync();
    $lomba = Lomba::query()->with(['pengajuan', 'penghentian'])
        ->whereHas('pengajuan', fn ($query) => $query->where('status_pengajuan', 'Disetujui'))
        ->findOrFail($id);
    $statusEfektif = $lomba->status_efektif;
    $lombaAktif = $lomba->status_lomba === 'Aktif' && !$lomba->penghentian;
    $pengajuan = $lomba->pengajuan;

    // Hanya peserta yang telah diterima penyelenggara dihitung dalam progres kuota.
    $jumlahPeserta = Pendaftaran::query()
        ->where('id_lomba', $id)
        ->where('status_pendaftaran', 'Diterima')
        ->count();

    // Periksa apakah pengguna pernah mendaftar.
    $sudahMendaftar = Pendaftaran::query()
        ->where('id_lomba', $id)
        ->where('id_user', $user->getKey())
        ->exists();

    // Periksa apakah pengguna merupakan pembuat lomba.
    $isPenyelenggara =
        (int) $pengajuan->id_user === (int) $user->getKey();

    // Periksa kuota.
    $kuota = $pengajuan->kuota_peserta;

    $kuotaPenuh = $kuota !== null &&
        $jumlahPeserta >= (int) $kuota;

    // Periksa batas pendaftaran.
    $batasLewat = $this->batasPendaftaranLewat(
        $pengajuan->batas_pendaftaran
    );

    $belumDibuka = $this->pendaftaranBelumDibuka($pengajuan->tanggal_mulai_pendaftaran);

    // Tentukan kelayakan pendaftaran.
    $bolehMendaftar =
        $lombaAktif &&
        !$isPenyelenggara &&
        !$sudahMendaftar &&
        !$kuotaPenuh &&
        !$batasLewat &&
        !$belumDibuka;

    // Pesan alasan jika tidak bisa mendaftar.
    $alasan = null;

    if (!$lombaAktif) {
        $alasan = match ($statusEfektif) {
            'Dibatalkan' => 'Lomba dibatalkan oleh administrator.',
            'Dihentikan' => 'Lomba dihentikan oleh administrator.',
            default => 'Lomba telah selesai. Pendaftaran ditutup.',
        };
    } elseif ($isPenyelenggara) {
        $alasan = 'Anda merupakan penyelenggara lomba ini.';
    } elseif ($sudahMendaftar) {
        $alasan = 'Anda sudah pernah mendaftar pada lomba ini.';
    } elseif ($kuotaPenuh) {
        $alasan = 'Kuota peserta lomba sudah penuh.';
    } elseif ($belumDibuka) {
        $alasan = 'Pendaftaran lomba belum dibuka.';
    } elseif ($batasLewat) {
        $alasan = 'Batas pendaftaran lomba telah berakhir.';
    }

    return response()->json([
        'pesan' => 'Status pendaftaran berhasil diperiksa.',
        'data' => [
            'id_lomba' => $id,
            'jumlah_peserta' => $jumlahPeserta,
            'kuota_peserta' => $kuota,
            'sudah_mendaftar' => $sudahMendaftar,
            'is_penyelenggara' => $isPenyelenggara,
            'kuota_penuh' => $kuotaPenuh,
            'batas_pendaftaran_lewat' => $batasLewat,
            'boleh_mendaftar' => $bolehMendaftar,
            'status_lomba' => $statusEfektif,
            'alasan' => $alasan,
        ],
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

        // Penyelenggara tidak boleh mendaftar pada lombanya sendiri.
    if ((int) $pengajuan->id_user === (int) $user->getKey()) {
        return response()->json([
            'pesan' => 'Penyelenggara tidak dapat mendaftar pada lomba sendiri.',
        ], 403);
    }

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

        $allowedAnswerIds = [];
        $allowedFileIds = [];

        foreach ($fields as $field) {
            $key = (string) $field->id_field;
            $requiredRule = $field->wajib ? 'required' : 'nullable';
            $type = $field->tipe_field;

            if ($type === 'File') {
                $allowedFileIds[] = $key;
                $rules["files.$key"] = [
                    $requiredRule,
                    'file',
                    'max:5120',
                    'mimes:pdf,jpg,jpeg,png',
                ];
                continue;
            }

            $allowedAnswerIds[] = $key;
            $fieldRules = [$requiredRule, 'string', 'max:5000'];

            if ($type === 'Number') {
                $fieldRules[] = 'regex:/^\d+$/';
            } elseif ($type === 'Email') {
                $fieldRules[] = 'email';
            } elseif ($type === 'Date') {
                $fieldRules[] = 'date_format:Y-m-d';
            } elseif ($type === 'Phone') {
                $fieldRules[] = 'regex:/^[0-9+()\-\s]{6,30}$/';
            } elseif ($type === 'Dropdown') {
                $options = $field->opsi_field;
                if (!is_array($options)) {
                    $options = [];
                }
                $fieldRules[] = Rule::in($options);
            }

            $rules["jawaban.$key"] = $fieldRules;
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

        foreach (array_keys($jawaban ?? []) as $key) {
            if (!in_array((string) $key, $allowedAnswerIds, true)) {
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

                // Validasi ulang di dalam transaksi.
                if ((int) $lockedPengajuan->id_user === (int) $user->getKey()) {
                    throw new HttpResponseException(response()->json([
                        'pesan' => 'Penyelenggara tidak dapat mendaftar pada lomba sendiri.',
                    ], 403));
                }

                if ($this->pendaftaranBelumDibuka($lockedPengajuan->tanggal_mulai_pendaftaran)) {
                    throw ValidationException::withMessages([
                        'tanggal_mulai_pendaftaran' => 'Pendaftaran belum dibuka.',
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
                    throw new HttpResponseException(response()->json([
                        'pesan' => 'Anda sudah terdaftar pada lomba ini.',
                    ], 409));
                }

                $jumlahPeserta = Pendaftaran::query()
                    ->where('id_lomba', $lockedLomba->id_lomba)
                    ->where('status_pendaftaran', 'Diterima')
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
                        if ($field->tipe_field === 'Number' && is_string($value)) {
                            $value = preg_replace('/\D+/', '', $value);
                        }
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

            // Beri tahu penyelenggara bahwa ada peserta baru.
            if ($pengajuan && $pengajuan->id_user) {
                Notifikasi::create([
                    'id_user' => $pengajuan->id_user,
                    'judul' => 'Peserta Baru Mendaftar',
                    'pesan' => 'Ada peserta baru yang mendaftar pada lomba "' . $pengajuan->nama_lomba . '".',
                    'tipe' => 'pendaftaran',
                    'data' => [
                        'id_pendaftaran' => $pendaftaran->id_pendaftaran,
                        'id_lomba' => $id,
                    ],
                ]);
            }

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

            // Unique index database tetap menjadi pelindung akhir jika terjadi
            // pendaftaran ganda secara bersamaan dari dua request.
            if ($exception instanceof QueryException
                && (int) ($exception->errorInfo[1] ?? 0) === 1062
                && str_contains($exception->getMessage(), 'uq_pendaftaran_lomba_user')) {
                return response()->json([
                    'pesan' => 'Anda sudah terdaftar pada lomba ini.',
                ], 409);
            }

            throw $exception;
        }
    }

    /** GET /api/pendaftaran/riwayat */
    public function riwayat(Request $request): JsonResponse
    {
        app(LombaLifecycleService::class)->sync();
        $user = $request->user();

        $pendaftaran = Pendaftaran::query()
            ->with(['lomba.pengajuan.kategori', 'lomba.penghentian'])
            ->where('id_user', $user->getKey())
            ->orderByDesc('tanggal_pendaftaran')
            ->get();

        return response()->json([
            'pesan' => 'Riwayat pendaftaran berhasil diambil.',
            'data' => $pendaftaran->map(fn (Pendaftaran $item) => [
                'id_pendaftaran' => $item->id_pendaftaran,
                'id_lomba' => $item->id_lomba,
                'nama_lomba' => $item->lomba?->pengajuan?->nama_lomba,
                'poster_lomba' => $item->lomba?->pengajuan?->poster_lomba,
                'poster_url' => $item->lomba?->pengajuan?->poster_lomba
                    ? url('/api/poster-lomba/' . rawurlencode(basename($item->lomba->pengajuan->poster_lomba)))
                    : null,
                'tanggal_pendaftaran' => $item->tanggal_pendaftaran,
                'status_pendaftaran' => $item->status_pendaftaran,
                'status_lomba' => $item->lomba?->status_efektif,
                'tanggal_pelaksanaan' => $item->lomba?->pengajuan?->tanggal_pelaksanaan?->format('Y-m-d'),
                'batas_pendaftaran' => $item->lomba?->pengajuan?->batas_pendaftaran?->format('Y-m-d'),
                'kuota_peserta' => $item->lomba?->pengajuan?->kuota_peserta,
                'jumlah_peserta_diterima' => $item->lomba ? $item->lomba->pendaftaran()->where('status_pendaftaran', 'Diterima')->count() : 0,
                'kategori' => $item->lomba?->pengajuan?->kategori?->nama_kategori,
            ])->values(),
        ], 200);
    }

    /** GET /api/pendaftaran/{id} */
    public function detail(Request $request, int $id): JsonResponse
    {
        app(LombaLifecycleService::class)->sync();
        $user = $request->user();

        $pendaftaran = Pendaftaran::query()
            ->with([
                'lomba.pengajuan.kategori',
                'lomba.pengajuan.penyelenggara',
                'lomba.pengajuan.informasiTambahan',
                'lomba.penghentian',
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

        $informasiTambahan = $pendaftaran->lomba?->pengajuan?->informasiTambahan ?? collect();

        return response()->json([
            'pesan' => 'Detail pendaftaran berhasil diambil.',
            'data' => [
                'id_pendaftaran' => $pendaftaran->id_pendaftaran,
                'id_lomba' => $pendaftaran->id_lomba,
                'nama_lomba' => $pendaftaran->lomba?->pengajuan?->nama_lomba,
                'deskripsi' => $pendaftaran->lomba?->pengajuan?->deskripsi,
                'persyaratan' => $pendaftaran->lomba?->pengajuan?->persyaratan,
                'poster_lomba' => $pendaftaran->lomba?->pengajuan?->poster_lomba,
                'poster_url' => $pendaftaran->lomba?->pengajuan?->poster_lomba
                    ? url('/api/poster-lomba/' . rawurlencode(basename($pendaftaran->lomba->pengajuan->poster_lomba)))
                    : null,
                'tanggal_pendaftaran' => $pendaftaran->tanggal_pendaftaran,
                'status_pendaftaran' => $pendaftaran->status_pendaftaran,
                'status_lomba' => $pendaftaran->lomba?->status_efektif,
                'tanggal_mulai_pendaftaran' => $pendaftaran->lomba?->pengajuan?->tanggal_mulai_pendaftaran?->format('Y-m-d'),
                'tanggal_pelaksanaan' => $pendaftaran->lomba?->pengajuan?->tanggal_pelaksanaan?->format('Y-m-d'),
                'batas_pendaftaran' => $pendaftaran->lomba?->pengajuan?->batas_pendaftaran?->format('Y-m-d'),
                'metode_pelaksanaan' => $pendaftaran->lomba?->pengajuan?->metode_pelaksanaan,
                'detail_pelaksanaan' => $pendaftaran->lomba?->pengajuan?->detail_pelaksanaan,
                'lokasi_pendaftaran' => $pendaftaran->lomba?->pengajuan?->lokasi_pendaftaran,
                'biaya' => $pendaftaran->lomba?->pengajuan?->biaya,
                'hadiah' => $pendaftaran->lomba?->pengajuan?->hadiah,
                'kuota_peserta' => $pendaftaran->lomba?->pengajuan?->kuota_peserta,
                'jumlah_peserta_diterima' => $pendaftaran->lomba
                    ? $pendaftaran->lomba->pendaftaran()->where('status_pendaftaran', 'Diterima')->count()
                    : 0,
                'kategori' => $pendaftaran->lomba?->pengajuan?->kategori?->nama_kategori,
                'penyelenggara' => $pendaftaran->lomba?->pengajuan?->penyelenggara?->username,
                'informasi_tambahan' => $informasiTambahan
                    ->sortBy('urutan')
                    ->values()
                    ->map(fn (InformasiLomba $info) => [
                        'label_informasi' => $info->label_informasi,
                        'nilai_informasi' => $info->nilai_informasi,
                    ])->all(),
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