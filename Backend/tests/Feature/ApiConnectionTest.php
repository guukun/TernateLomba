<?php

namespace Tests\Feature;

use Tests\TestCase;

class ApiConnectionTest extends TestCase
{
    public function test_api_connection_endpoint_returns_successful_json(): void
    {
        $this->getJson('/api/tes-koneksi')
            ->assertOk()
            ->assertJson([
                'pesan' => 'Flutter berhasil terhubung ke Laravel',
            ]);
    }
}
