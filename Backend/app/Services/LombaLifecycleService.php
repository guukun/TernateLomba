<?php

namespace App\Services;

use App\Models\Lomba;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Menjaga status lomba dan role penyelenggara tetap sesuai kondisi lomba.
 * Role Penyelenggara aktif selama pengguna masih memiliki minimal satu lomba Aktif.
 */
class LombaLifecycleService
{
    public function sync(): void
    {
        $today = Carbon::now('Asia/Jayapura')->toDateString();

        DB::transaction(function () use ($today): void {
            // Completed after the end of the event. Old records without end date use the start date.
            Lomba::query()
                ->where('status_lomba', 'Aktif')
                ->whereHas('pengajuan', function ($query) use ($today): void {
                    $query->whereNotNull('tanggal_pelaksanaan')
                        ->whereRaw('DATE(COALESCE(tanggal_selesai_pelaksanaan, tanggal_pelaksanaan)) < ?', [$today]);
                })
                ->update([
                    'status_lomba' => 'Selesai',
                    'updated_at' => now(),
                ]);

            $activeOwnerIds = Lomba::query()
                ->where('status_lomba', 'Aktif')
                ->whereHas('pengajuan', function ($query): void {
                    $query->where('status_pengajuan', 'Disetujui');
                })
                ->with('pengajuan:id_pengajuan,id_user')
                ->get()
                ->pluck('pengajuan.id_user')
                ->filter()
                ->unique()
                ->values()
                ->all();

            // Administrator tidak pernah diubah oleh sinkronisasi role ini.
            if (empty($activeOwnerIds)) {
                User::query()
                    ->where('role', 'Penyelenggara')
                    ->update(['role' => 'User', 'updated_at' => now()]);

                return;
            }

            User::query()
                ->where('role', 'Penyelenggara')
                ->whereNotIn('id_user', $activeOwnerIds)
                ->update(['role' => 'User', 'updated_at' => now()]);

            User::query()
                ->where('role', 'User')
                ->whereIn('id_user', $activeOwnerIds)
                ->update(['role' => 'Penyelenggara', 'updated_at' => now()]);
        });
    }
}