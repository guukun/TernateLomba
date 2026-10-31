import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  // URL API dapat diganti tanpa mengedit kode:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  // Untuk HP fisik, gunakan IP LAN komputer yang menjalankan Laravel.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  // MEMBACA RESPONSE JSON
  // Fungsi ini mencegah error ketika Laravel
  // mengembalikan response yang bukan JSON.
  static Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Ditangani dengan pesan yang menyertakan status HTTP di bawah.
    }

    throw Exception(
      'Respons server bukan JSON yang valid (HTTP ${response.statusCode}). '
      'Periksa URL API, konfigurasi Laravel, dan log server.',
    );
  }

  static Exception _responseError(
    http.Response response,
    Map<String, dynamic> data,
    String fallback,
  ) {
    String? detail;
    final errors = data['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          detail = value.first.toString();
          break;
        }
        if (value != null && value.toString().trim().isNotEmpty) {
          detail = value.toString();
          break;
        }
      }
    }

    final message = (data['pesan'] ?? data['message'])?.toString().trim();
    final reason = (detail != null && detail.isNotEmpty)
        ? detail
        : (message != null && message.isNotEmpty ? message : fallback);

    return Exception('HTTP ${response.statusCode}: $reason');
  }

  // TES KONEKSI
  static Future<String> tesKoneksi() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/tes-koneksi'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Koneksi ke server gagal.');
    }

    return data['pesan']?.toString() ?? 'Koneksi berhasil';
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    // Laravel mengembalikan 200 jika login berhasil.
    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Login gagal.');
    }

    return data;
  }

  // REGISTER
  static Future<Map<String, dynamic>> register(
    String username,
    String password,
    String confirmation,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/register'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'username': username,
            'password': password,
            // Laravel menggunakan validator "confirmed".
            'password_confirmation': confirmation,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    // Laravel mengembalikan 201
    // ketika akun berhasil dibuat.
    if (response.statusCode != 201) {
      throw _responseError(response, data, 'Pendaftaran akun gagal.');
    }

    return data;
  }

  // UPDATE PROFILE
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    // Username selalu dikirim.
    final Map<String, dynamic> body = {'username': username};

    // Password hanya dikirim jika pengguna
    // benar-benar ingin mengganti password.
    if (password.isNotEmpty) {
      body['password'] = password;

      body['password_confirmation'] = passwordConfirmation;
    }

    final response = await http
        .put(
          Uri.parse('$baseUrl/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    // Laravel mengembalikan 200
    // ketika profil berhasil diperbarui.
    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal memperbarui profil.');
    }

    return data;
  }

  // UPLOAD FOTO PROFIL
  static Future<Map<String, dynamic>> uploadFotoProfil({
    required String token,
    required XFile foto,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/foto'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'foto_profil',
        await foto.readAsBytes(),
        filename: foto.name,
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );

    final response = await http.Response.fromStream(streamedResponse)
        .timeout(const Duration(seconds: 30));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal mengunggah foto profil.');
    }

    return data;
  }

  // MENGAMBIL PROFIL PENGGUNA
  static Future<Map<String, dynamic>> getCurrentUser({
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/users'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal mengambil profil pengguna.');
    }

    final user = data['user'];

    if (user is! Map<String, dynamic>) {
      throw Exception('Data profil dari server tidak valid.');
    }

    return user;
  }

  // LOGOUT
  static Future<void> logout({required String token}) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      String message =
          'Logout gagal. '
          'HTTP ${response.statusCode}.';

      try {
        final data = _decodeResponse(response);
        message = (data['pesan'] ?? data['message'] ?? message).toString();
      } catch (_) {
        // Pertahankan pesan error awal.
      }

      throw Exception(message);
    }
  }

  // MENGAMBIL KATEGORI DARI MYSQL
  static Future<List<Map<String, dynamic>>> getKategori() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/kategori'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal mengambil kategori.');
    }

    final items = data['data'];

    if (items is! List) {
      throw Exception('Format data kategori tidak valid.');
    }

    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // MENGAMBIL DAFTAR LOMBA AKTIF DARI MYSQL
  static Future<List<Map<String, dynamic>>> getLomba({
    String? search,
    int? idKategori,
  }) async {
    final uri = Uri.parse('$baseUrl/lomba').replace(
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (idKategori != null) 'id_kategori': idKategori.toString(),
      },
    );

    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal mengambil daftar lomba.');
    }

    final items = data['data'];

    if (items is! List) {
      throw Exception('Format data lomba tidak valid.');
    }

    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // MENGAMBIL DETAIL LOMBA BERDASARKAN ID
  static Future<Map<String, dynamic>> getDetailLomba(int idLomba) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/lomba/$idLomba'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal mengambil detail lomba.');
    }

    final item = data['data'];

    if (item is! Map) {
      throw Exception('Format detail lomba tidak valid.');
    }

    return Map<String, dynamic>.from(item);
  }

  // MENGAMBIL PERTANYAAN FORMULIR LOMBA
  static Future<List<Map<String, dynamic>>> getFormFields(int idLomba) async {
    if (idLomba <= 0) {
      throw Exception('ID lomba tidak valid. Silakan buka detail lomba lagi.');
    }

    final uri = Uri.parse('$baseUrl/lomba/$idLomba/form-fields');
    final response = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal mengambil formulir.');
    }

    final fields = data['data'];
    if (fields is! List) {
      throw Exception(
        'Format respons formulir tidak sesuai. '
        'Pastikan endpoint Laravel mengembalikan properti "data" berupa daftar.',
      );
    }

    final parsed = <Map<String, dynamic>>[];
    for (final item in fields) {
      if (item is! Map) {
        throw Exception('Salah satu data kolom formulir tidak valid.');
      }
      final field = Map<String, dynamic>.from(item);
      if (field['id_field'] == null || field['nama_field'] == null) {
        throw Exception('Respons formulir tidak memiliki ID atau nama field.');
      }
      parsed.add(field);
    }

    return parsed;
  }

  // MENGAMBIL RIWAYAT PENDAFTARAN PENGGUNA
  static Future<Map<String, dynamic>> getRiwayatPendaftaran({
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/pendaftaran/riwayat'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal mengambil riwayat pendaftaran.');
    }

    if (data['data'] is! List) {
      throw Exception('Format riwayat pendaftaran tidak valid.');
    }

    return data;
  }

  // MENGAMBIL DAFTAR LOMBA YANG DIBUAT OLEH PENGGUNA LOGIN
  static Future<Map<String, dynamic>> getPengajuanLombaSaya({
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/pengajuan-lomba/saya'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(
        response,
        data,
        'Gagal mengambil lomba yang dibuat.',
      );
    }
    if (data['data'] is! List) {
      throw Exception('Format data lomba yang dibuat tidak valid.');
    }
    return data;
  }

  // MENGIRIM PENGAJUAN LOMBA KE LARAVEL
  static Future<Map<String, dynamic>> ajukanLomba({
    required String token,
    required int idKategori,
    required String namaLomba,
    required String deskripsi,
    required String tanggalPelaksanaan,
    required String batasPendaftaran,
    required String lokasiPendaftaran,
    required String biaya,
    required String kontakPenyelenggara,
    String? persyaratan,
    String? hadiah,
    String? kuotaPeserta,
    XFile? poster,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/pengajuan-lomba'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields.addAll({
      'id_kategori': idKategori.toString(),
      'nama_lomba': namaLomba.trim(),
      'deskripsi': deskripsi.trim(),
      'tanggal_pelaksanaan': tanggalPelaksanaan,
      'batas_pendaftaran': batasPendaftaran,
      'lokasi_pendaftaran': lokasiPendaftaran.trim(),
      'biaya': biaya.trim().isEmpty ? '0' : biaya.trim(),
      'kontak_penyelenggara': kontakPenyelenggara.trim(),
    });

    if (persyaratan != null && persyaratan.trim().isNotEmpty) {
      request.fields['persyaratan'] = persyaratan.trim();
    }
    if (hadiah != null && hadiah.trim().isNotEmpty) {
      request.fields['hadiah'] = hadiah.trim();
    }
    if (kuotaPeserta != null && kuotaPeserta.trim().isNotEmpty) {
      request.fields['kuota_peserta'] = kuotaPeserta.trim();
    }

    if (poster != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'poster_lomba',
          await poster.readAsBytes(),
          filename: poster.name,
        ),
      );
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    final response = await http.Response.fromStream(streamedResponse)
        .timeout(const Duration(seconds: 30));
    final data = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw _responseError(response, data, 'Pengajuan lomba gagal dikirim.');
    }

    return data;
  }

  // MENGAMBIL SEMUA PENGAJUAN UNTUK DASHBOARD ADMIN
  static Future<Map<String, dynamic>> getPengajuanLombaAdmin({
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/admin/pengajuan-lomba'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 25));

    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal mengambil pengajuan lomba.');
    }
    if (data['data'] is! List) {
      throw Exception('Format daftar pengajuan admin tidak valid.');
    }
    return data;
  }

  // ADMIN MENYETUJUI ATAU MENOLAK PENGAJUAN
  static Future<Map<String, dynamic>> putuskanPengajuanLomba({
    required String token,
    required int idPengajuan,
    required String keputusan,
    String? catatanAdmin,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/admin/pengajuan-lomba/$idPengajuan/keputusan'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'keputusan': keputusan,
            if (catatanAdmin != null && catatanAdmin.trim().isNotEmpty)
              'catatan_admin': catatanAdmin.trim(),
          }),
        )
        .timeout(const Duration(seconds: 25));

    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal memproses pengajuan lomba.');
    }
    return data;
  }

  // MENGIRIM PENDAFTARAN KE LARAVEL
  static Future<Map<String, dynamic>> kirimPendaftaran({
    required int idLomba,
    required String token,
    required Map<int, String> jawaban,
    required Map<int, XFile> berkas,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/lomba/$idLomba/pendaftaran'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    for (final entry in jawaban.entries) {
      request.fields['jawaban[${entry.key}]'] = entry.value;
    }

    for (final entry in berkas.entries) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files[${entry.key}]',
          await entry.value.readAsBytes(),
          filename: entry.value.name,
        ),
      );
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );

    final response = await http.Response.fromStream(streamedResponse);

    final data = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw _responseError(response, data, 'Pendaftaran gagal dikirim.');
    }

    return data;
  }
}
