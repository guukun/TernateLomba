<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notifikasi extends Model
{
    protected $table = 'notifikasi';

    protected $primaryKey = 'id';

    protected $fillable = [
        'user_id',
        'pengajuan_id',
        'judul',
        'pesan',
        'tipe',
        'is_read',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Relasi ke tabel users.
     * notifikasi.user_id -> users.id_user
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(
            User::class,
            'user_id',
            'id_user'
        );
    }

    /**
     * Relasi ke tabel pengajuan_lomba.
     */
    public function pengajuan(): BelongsTo
    {
        return $this->belongsTo(
            PengajuanLomba::class,
            'pengajuan_id',
            'id_pengajuan'
        );
    }
}