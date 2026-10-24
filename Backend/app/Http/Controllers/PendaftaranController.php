<?php

namespace App\Http\Controllers;

use App\Models\FormField;
use App\Models\Lomba;
use App\Models\Pendaftaran;
use App\Models\JawabanPendaftaran;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use Throwable;

class PendaftaranController extends Controller
{
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

    public function formFields(int $id)
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

            foreach ($fields as $field) {
                if (!in_array($field->tipe_field, ['Text', 'File'], true)) {
                    return response()->json([
                        'pesan' => 'Tipe field formulir tidak didukung.',
                        'id_field' => $field->id_field,
                    ], 422);
                }
            }

        return response()->json([
            'pesan' => 'Formulir berhasil diambil',
            'id_lomba' => $lomba->id_lomba,
            'data' => $fields,
        ]);
    }

    public function store(Request $request, int $id)
    {
        // Menggunakan token yang sudah diterbitkan
        // oleh sistem login TernateLomba.
        $user = $request->user();

        $lomba = $this->cariLomba($id);
        $pengajuan = $lomba->pengajuan;

        if (
            $pengajuan->batas_pendaftaran &&
            now()->toDateString() >
                substr((string) $pengajuan->batas_pendaftaran, 0, 10)
        ) {
            return response()->json([
                'pesan' => 'Batas pendaftaran telah berakhir.',
            ], 422);
        }

        $sudahDaftar = Pendaftaran::query()
            ->where('id_lomba', $id)
            ->where('id_user', $user->getKey())
            ->exists();

        if ($sudahDaftar) {
            return response()->json([
                'pesan' => 'Anda sudah terdaftar pada lomba ini.',
            ], 409);
        }

        $fields = FormField::query()
            ->where('id_pengajuan', $lomba->id_pengajuan)
            ->orderBy('urutan')
            ->get();


        $rules = [
            'jawaban' => ['sometimes', 'array'],
            'files' => ['sometimes', 'array'],
        ];

        foreach ($fields as $field) {
            $key = (string) $field->id_field;

            if ($field->tipe_field === 'File') {
                $rules["files.$key"] = [
                    $field->wajib ? 'required' : 'nullable',
                    'file',
                    'max:5120',
                    'mimes:pdf,jpg,jpeg,png',
                ];
            } else {
                $rules["jawaban.$key"] = [
                    $field->wajib ? 'required' : 'nullable',
                    'string',
                    'max:5000',
                ];
            }
        }

        $validator = Validator::make(
            $request->all(),
            $rules
        );

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
                $lomba,
                $pengajuan,
                $fields,
                $request,
                &$uploadedPaths
            ) {
                // Kunci baris lomba untuk menjaga kuota
                // saat beberapa peserta mendaftar bersamaan.
                $lockedLomba = Lomba::query()
                    ->whereKey($id)
                    ->lockForUpdate()
                    ->firstOrFail();

                if ($lockedLomba->status_lomba !== 'Aktif') {
                    throw ValidationException::withMessages([
                        'lomba' => 'Lomba sudah tidak aktif dan tidak dapat menerima pendaftaran.',
                    ]);
                }

                $lockedLomba->load('pengajuan');

                if (
                    !$lockedLomba->pengajuan ||
                    $lockedLomba->pengajuan->status_pengajuan !== 'Disetujui'
                ) {
                    throw ValidationException::withMessages([
                        'lomba' => 'Pengajuan lomba belum disetujui atau sudah tidak berlaku.',
                    ]);
                }

                $batasPendaftaran = $lockedLomba->pengajuan->batas_pendaftaran;

                if (
                    $batasPendaftaran &&
                    now()->toDateString() >
                        substr((string) $batasPendaftaran, 0, 10)
                ) {
                    throw ValidationException::withMessages([
                        'batas_pendaftaran' => 'Batas pendaftaran telah berakhir.',
                    ]);
                }


                $sudahDaftarDalamTransaksi = Pendaftaran::query()
                    ->where('id_lomba', $lockedLomba->id_lomba)
                    ->where('id_user', $user->getKey())
                    ->exists();

                if ($sudahDaftarDalamTransaksi) {
                    throw ValidationException::withMessages([
                        'pendaftaran' => 'Anda sudah terdaftar pada lomba ini.',
                    ]);
                }

                $jumlahPeserta = Pendaftaran::query()
                    ->where('id_lomba', $id)
                    ->whereIn('status_pendaftaran', [
                        'Menunggu',
                        'Diterima',
                    ])
                    ->count();

                if (
                    $pengajuan->kuota_peserta !== null &&
                    $jumlahPeserta >= (int) $pengajuan->kuota_peserta
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
                    $nilai = null;

                    if ($field->tipe_field === 'File') {
                        $file = $request->file("files.$key");

                        if ($file) {
                            $nilai = $file->store(
                                'pendaftaran/' . $pendaftaran->id_pendaftaran,
                                'local'
                            );

                            $uploadedPaths[] = $nilai;
                        }
                    } else {
                        $nilai = $request->input("jawaban.$key");
                    }

                    if ($nilai === null || $nilai === '') {
                        continue;
                    }

                    JawabanPendaftaran::create([
                        'id_pendaftaran' =>
                            $pendaftaran->id_pendaftaran,
                        'id_field' => $field->id_field,
                        'jawaban' => $nilai,
                    ]);
                }

                return $pendaftaran;
            });

            return response()->json([
                'pesan' => 'Pendaftaran berhasil dikirim.',
                'data' => [
                    'id_pendaftaran' =>
                        $pendaftaran->id_pendaftaran,
                    'id_lomba' => $pendaftaran->id_lomba,
                    'status_pendaftaran' =>
                        $pendaftaran->status_pendaftaran,
                ],
            ], 201);
        } catch (ValidationException $e) {
            foreach ($uploadedPaths as $path) {
                Storage::disk('local')->delete($path);
            }

            throw $e;
        } catch (Throwable $e) {
            foreach ($uploadedPaths as $path) {
                Storage::disk('local')->delete($path);
            }

            throw $e;
        }
    }

    

public function riwayat(Request $request)
{
    $user = $request->user();

    $pendaftaran = Pendaftaran::query()
        ->with(['lomba.pengajuan'])
        ->where('id_user', $user->getKey())
        ->orderByDesc('tanggal_pendaftaran')
        ->get();

    return response()->json([
        'pesan' => 'Riwayat pendaftaran berhasil diambil.',
        'data' => $pendaftaran->map(function ($item) {
            return [
                'id_pendaftaran' => $item->id_pendaftaran,
                'id_lomba' => $item->id_lomba,
                'nama_lomba' => $item->lomba?->pengajuan?->nama_lomba,
                'tanggal_pendaftaran' => $item->tanggal_pendaftaran,
                'status_pendaftaran' => $item->status_pendaftaran,
            ];
        }),
    ], 200);
}



public function unduhJawabanFile(Request $request, int $id, int $idJawaban)
{
    $user = $request->user();

    $jawaban = JawabanPendaftaran::query()
        ->with('pendaftaran')
        ->where('id_jawaban', $idJawaban)
        ->whereHas('pendaftaran', function ($query) use ($id, $user) {
            $query->where('id_pendaftaran', $id)
                ->where('id_user', $user->getKey());
        })
        ->first();

    if (!$jawaban || !$jawaban->pendaftaran) {
        return response()->json([
            'pesan' => 'Dokumen tidak ditemukan atau Anda tidak memiliki akses.',
        ], 404);
    }

    $field = FormField::query()
        ->where('id_field', $jawaban->id_field)
        ->where(
            'id_pengajuan',
            $jawaban->pendaftaran->lomba->id_pengajuan
        )
        ->first();

    if (!$field || $field->tipe_field !== 'File') {
        return response()->json([
            'pesan' => 'Jawaban tersebut bukan dokumen yang dapat diunduh.',
        ], 404);
    }

    $path = $jawaban->jawaban;
    $disk = Storage::disk('local');

    if (
        !is_string($path) ||
        !str_starts_with(
            $path,
            'pendaftaran/' . $id . '/'
        ) ||
        !$disk->exists($path)
    ) {
        return response()->json([
            'pesan' => 'File tidak ditemukan.',
        ], 404);
    }

    return $disk->download(
        $path,
        basename($path),
        ['Cache-Control' => 'private, no-store']
    );
}

}
