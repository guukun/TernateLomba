<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class JawabanPendaftaran extends Model
{
    protected $table = 'jawaban_pendaftaran';

    protected $primaryKey = 'id_jawaban';

    protected $fillable = [
        'id_pendaftaran',
        'id_field',
        'jawaban',
    ];

    public function pendaftaran(): BelongsTo
    {
        return $this->belongsTo(
            Pendaftaran::class,
            'id_pendaftaran',
            'id_pendaftaran'
        );
    }

    public function formField(): BelongsTo
    {
        return $this->belongsTo(
            FormField::class,
            'id_field',
            'id_field'
        );
    }
}
