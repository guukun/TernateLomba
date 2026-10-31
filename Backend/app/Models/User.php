<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $table = 'users';

    protected $primaryKey = 'id_user';

    protected $fillable = [
        'username',
        'password',
        'role',
        'foto_profil',
    ];

    protected $hidden = [
        'password',
        'api_token_hash',
        'api_token_expires_at',
    ];

    protected function casts(): array
    {
        return [
            'api_token_expires_at' => 'datetime',
        ];
    }

    public function pengajuanLomba(): HasMany
    {
        return $this->hasMany(
            PengajuanLomba::class,
            'id_user',
            'id_user'
        );
    }

    public function pendaftaran(): HasMany
    {
        return $this->hasMany(
            Pendaftaran::class,
            'id_user',
            'id_user'
        );
    }
}