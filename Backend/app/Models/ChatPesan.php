<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ChatPesan extends Model
{
    protected $table = 'chat_pesan';
    protected $primaryKey = 'id_pesan';
    public $timestamps = false;
    protected $fillable = ['id_lomba', 'id_user', 'isi_pesan'];
    protected $casts = ['created_at' => 'datetime'];

    public function pengirim(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_user', 'id_user');
    }
}