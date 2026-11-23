<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LombaPenghentian extends Model
{
    protected $table = 'lomba_penghentian';
    protected $primaryKey = 'id_penghentian';
    protected $fillable = ['id_lomba', 'id_admin', 'jenis_tindakan', 'alasan', 'dihentikan_at'];
    protected $casts = ['dihentikan_at' => 'datetime'];
}
