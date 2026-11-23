<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InformasiLomba extends Model
{
    protected $table = 'informasi_lomba';
    protected $primaryKey = 'id_informasi';

    protected $fillable = [
        'id_pengajuan',
        'kelompok_informasi',
        'label_informasi',
        'nilai_informasi',
        'urutan',
    ];

    protected $casts = [
        'urutan' => 'integer',
    ];

    public function pengajuan(): BelongsTo
    {
        return $this->belongsTo(PengajuanLomba::class, 'id_pengajuan', 'id_pengajuan');
    }
}