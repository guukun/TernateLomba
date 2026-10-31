<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class PengajuanLomba extends Model
{
    protected $table = 'pengajuan_lomba';

    protected $primaryKey = 'id_pengajuan';

    public $timestamps = false;

    protected $fillable = [
        'id_user',
        'id_kategori',
        'nama_lomba',
        'deskripsi',
        'persyaratan',
        'tanggal_pelaksanaan',
        'batas_pendaftaran',
        'lokasi_pendaftaran',
        'biaya',
        'hadiah',
        'kuota_peserta',
        'kontak_penyelenggara',
        'poster_lomba',
        'status_pengajuan',
        'catatan_admin',
        'tanggal_pengajuan',
    ];

    protected $casts = [
        'tanggal_pelaksanaan' => 'date',
        'batas_pendaftaran' => 'date',
        'tanggal_pengajuan' => 'datetime',
        'biaya' => 'decimal:2',
        'kuota_peserta' => 'integer',
    ];

    public function getStatusPengajuanAttribute($value): ?string
    {
        return $value === null ? null : ucfirst(strtolower((string) $value));
    }

    public function penyelenggara(): BelongsTo
    {
        return $this->belongsTo(
            User::class,
            'id_user',
            'id_user'
        );
    }

    public function kategori(): BelongsTo
    {
        return $this->belongsTo(
            KategoriLomba::class,
            'id_kategori',
            'id_kategori'
        );
    }

    public function lomba(): HasOne
    {
        return $this->hasOne(
            Lomba::class,
            'id_pengajuan',
            'id_pengajuan'
        );
    }

    public function formFields(): HasMany
    {
        return $this->hasMany(
            FormField::class,
            'id_pengajuan',
            'id_pengajuan'
        );
    }
}
