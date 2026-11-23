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
        'placeholder',
        'tipe_field',
        'opsi_field',
        'wajib',
        'urutan',
        'is_default',
    ];

    protected $casts = [
        'opsi_field' => 'array',
        'wajib' => 'boolean',
        'urutan' => 'integer',
        'is_default' => 'boolean',
    ];

    public function getTipeFieldAttribute($value): ?string
    {
        return $value === null ? null : ucfirst(strtolower((string) $value));
    }

    public function pengajuan(): BelongsTo
    {
        return $this->belongsTo(PengajuanLomba::class, 'id_pengajuan', 'id_pengajuan');
    }

    public function jawabanPendaftaran(): HasMany
    {
        return $this->hasMany(JawabanPendaftaran::class, 'id_field', 'id_field');
    }
}