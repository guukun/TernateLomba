<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class KategoriLomba extends Model
{
    protected $table = 'kategori_lomba';

    protected $primaryKey = 'id_kategori';

    public $timestamps = false;

    protected $fillable = [
        'nama_kategori',
        'deskripsi_kategori',
    ];

    public function pengajuanLomba(): HasMany
    {
        return $this->hasMany(
            PengajuanLomba::class,
            'id_kategori',
            'id_kategori'
        );
    }
}
