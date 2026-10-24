<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FormField extends Model
{
    protected $table = 'form_field';

    protected $primaryKey = 'id_field';

    protected $fillable = [
        'id_pengajuan',
        'nama_field',
        'tipe_field',
        'wajib',
        'urutan',
    ];

    protected $casts = [
        'wajib' => 'boolean',
        'urutan' => 'integer',
    ];

    public function pengajuan(): BelongsTo
    {
        return $this->belongsTo(
            PengajuanLomba::class,
            'id_pengajuan',
            'id_pengajuan'
        );
    }

    public function jawabanPendaftaran(): HasMany
    {
        return $this->hasMany(
            JawabanPendaftaran::class,
            'id_field',
            'id_field'
        );
    }
}
