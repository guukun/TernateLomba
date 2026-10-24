<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pendaftaran extends Model
{
    protected $table = 'pendaftaran';

    protected $primaryKey = 'id_pendaftaran';

    protected $fillable = [
        'id_lomba',
        'id_user',
        'tanggal_pendaftaran',
        'status_pendaftaran',
    ];

    protected $casts = [
        'tanggal_pendaftaran' => 'datetime',
    ];

    public function lomba(): BelongsTo
    {
        return $this->belongsTo(
            Lomba::class,
            'id_lomba',
            'id_lomba'
        );
    }

    public function peserta(): BelongsTo
    {
        return $this->belongsTo(
            User::class,
            'id_user',
            'id_user'
        );
    }

    public function jawabanPendaftaran(): HasMany
    {
        return $this->hasMany(
            JawabanPendaftaran::class,
            'id_pendaftaran',
            'id_pendaftaran'
        );
    }
}
