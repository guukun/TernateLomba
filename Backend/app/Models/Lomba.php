<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Lomba extends Model
{
    protected $table = 'lomba';

    protected $primaryKey = 'id_lomba';

    protected $fillable = [
        'id_pengajuan',
        'status_lomba',
    ];

    protected $casts = [
        'status_lomba' => 'string',
    ];

    public function getStatusLombaAttribute($value): ?string
    {
        return $value === null ? null : ucfirst(strtolower((string) $value));
    }

    public function getStatusEfektifAttribute(): ?string
    {
        if ($this->penghentian) {
            return $this->penghentian->jenis_tindakan === 'Batalkan' ? 'Dibatalkan' : 'Dihentikan';
        }
        return $this->status_lomba;
    }

    public function penghentian(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(LombaPenghentian::class, 'id_lomba', 'id_lomba');
    }

    public function pengajuan(): BelongsTo
    {
        return $this->belongsTo(
            PengajuanLomba::class,
            'id_pengajuan',
            'id_pengajuan'
        );
    }

    public function pendaftaran(): HasMany
    {
        return $this->hasMany(
            Pendaftaran::class,
            'id_lomba',
            'id_lomba'
        );
    }
}