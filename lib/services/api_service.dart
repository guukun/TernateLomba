import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  /// Sinyal perubahan data lintas halaman dalam satu sesi aplikasi.
  /// Untuk perubahan dari perangkat lain, halaman juga melakukan polling API.
  static final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);

  static void notifyDataChanged() {
    dataRevision.value++;
  }

  // URL API dapat diganti tanpa mengedit kode:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  // Untuk HP fisik, gunakan IP LAN komputer yang menjalankan Laravel.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
    // defaultValue: 'http://10.104.22.67:8000/api',
  );

  /// Pesan terarah untuk masalah koneksi saat API lokal tidak dapat dijangkau.
  /// Kegagalan jaringan tidak berarti pendaftaran atau pengajuan hilang.
  static String readableError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '');
    if (raw.contains('ClientLoad failed') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Connection refused') ||
        raw.contains('XMLHttpRequest error') ||
        raw.contains('SocketException')) {
      return 'Server Laravel belum terhubung. Jalankan backend dan pastikan alamat API sesuai perangkat. Di emulator Android gunakan 10.0.2.2, di HP gunakan IP LAN komputer.';
    }
    return raw;
  }

  /// Membentuk URL gambar dengan merujuk path poster yang disimpan MySQL.
  ///
  /// Nilai database tetap berupa path, misalnya:
  /// poster-lomba/abc123.jpg
  /// Laravel akan mencari record pengajuan berdasarkan nama file tersebut,
  /// lalu membaca file aslinya dari public storage.
  static String? publicStorageUrl(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return null;

    try {
      final normalized = value.replaceAll('\\', '/');
      final parsed = Uri.tryParse(normalized);
      final segments = parsed != null && parsed.hasScheme
          ? parsed.pathSegments.where((segment) => segment.isNotEmpty).toList()
          : normalized
                .split('/')
                .where((segment) => segment.isNotEmpty)
                .toList();

      if (segments.isEmpty) return null;

      final filename = Uri.decodeComponent(segments.last);
      if (filename == '.' ||
          filename == '..' ||
          filename.contains('/') ||
          filename.contains('\\') ||
          !RegExp(
            r'\.(jpg|jpeg|png)$',
            caseSensitive: false,
          ).hasMatch(filename)) {
        return null;
      }

      final endpoint = baseUrl.replaceFirst(RegExp(r'/+$'), '');
      return '$endpoint/poster-lomba/${Uri.encodeComponent(filename)}';
    } catch (_) {
      return null;
    }
  }

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

  // MEMERIKSA STATUS PENDAFTARAN PENGGUNA PADA LOMBA
  static Future<Map<String, dynamic>> getStatusPendaftaranLomba({
    required int idLomba,
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/lomba/$idLomba/status-pendaftaran'),
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
        'Gagal memeriksa status pendaftaran.',
      );
    }

    final item = data['data'];

    if (item is! Map) {
      throw Exception('Format status pendaftaran tidak valid.');
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
      throw _responseError(
        response,
        data,
        'Gagal mengambil riwayat pendaftaran.',
      );
    }

    if (data['data'] is! List) {
      throw Exception('Format riwayat pendaftaran tidak valid.');
    }

    return data;
  }

  // MENGAMBIL DETAIL LOMBA YANG SUDAH DIIKUTI OLEH PENGGUNA
  static Future<Map<String, dynamic>> getDetailPendaftaran({
    required String token,
    required int idPendaftaran,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/pendaftaran/$idPendaftaran'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 25));

    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(
        response,
        data,
        'Gagal mengambil detail lomba yang diikuti.',
      );
    }
    if (data['data'] is! Map) {
      throw Exception('Format detail lomba yang diikuti tidak valid.');
    }
    return Map<String, dynamic>.from(data['data']);
  }

  // MENGAMBIL PESERTA PADA LOMBA MILIK PENYELENGGARA
  static Future<Map<String, dynamic>> getPesertaPenyelenggara({
    required String token,
    required int idLomba,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/penyelenggara/lomba/$idLomba/peserta'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 25));

    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(
        response,
        data,
        'Gagal mengambil daftar peserta lomba.',
      );
    }
    if (data['data'] is! Map) {
      throw Exception('Format data peserta lomba tidak valid.');
    }
    return Map<String, dynamic>.from(data['data']);
  }

  // MENGAMBIL JAWABAN LENGKAP SATU PESERTA UNTUK DIREVIEW PENYELENGGARA
  static Future<Map<String, dynamic>> getDetailPesertaPenyelenggara({
    required String token,
    required int idPendaftaran,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/penyelenggara/pendaftaran/$idPendaftaran'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 25));

    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal mengambil jawaban peserta.');
    }
    if (data['data'] is! Map) {
      throw Exception('Format detail peserta tidak valid.');
    }
    return Map<String, dynamic>.from(data['data']);
  }

  // PENYELENGGARA MENERIMA ATAU MENOLAK PENDAFTARAN PESERTA
  static Future<Map<String, dynamic>> putuskanPendaftaranPeserta({
    required String token,
    required int idPendaftaran,
    required String keputusan,
    String? catatan,
  }) async {
    final response = await http
        .patch(
          Uri.parse(
            '$baseUrl/penyelenggara/pendaftaran/$idPendaftaran/keputusan',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'keputusan': keputusan,
            if (catatan != null && catatan.trim().isNotEmpty)
              'catatan': catatan.trim(),
          }),
        )
        .timeout(const Duration(seconds: 25));

    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(
        response,
        data,
        'Gagal memproses pendaftaran peserta.',
      );
    }
    notifyDataChanged();
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

  // MENGIRIM PENGAJUAN LOMBA KE LARAVEL.
  // Tahap 1 mengirim informasi umum + informasi tambahan semi-dinamis.
  // Tahap 2 mengirim konfigurasi formulir peserta yang sepenuhnya dinamis.
  // Tahap 3 memanggil method ini setelah pengguna memeriksa ringkasan.
  static Future<Map<String, dynamic>> ajukanLomba({
    required String token,
    required int idKategori,
    required String namaLomba,
    required String deskripsi,
    required String tanggalMulaiPendaftaran,
    required String batasPendaftaran,
    required String tanggalPelaksanaan,
    required String tanggalSelesaiPelaksanaan,
    required String metodePelaksanaan,
    required String detailPelaksanaan,
    required String biaya,
    String? kuotaPeserta,
    required XFile poster,
    required List<Map<String, dynamic>> informasiTambahan,
    required List<Map<String, dynamic>> formFields,
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
      'tanggal_mulai_pendaftaran': tanggalMulaiPendaftaran,
      'batas_pendaftaran': batasPendaftaran,
      'tanggal_pelaksanaan': tanggalPelaksanaan,
      'tanggal_selesai_pelaksanaan': tanggalSelesaiPelaksanaan,
      'metode_pelaksanaan': metodePelaksanaan,
      'detail_pelaksanaan': detailPelaksanaan.trim(),
      // Biaya dikirim sebagai angka tanpa pemisah ribuan.
      'biaya': biaya.replaceAll('.', '').trim().isEmpty
          ? '0'
          : biaya.replaceAll('.', '').trim(),
    });

    if (kuotaPeserta != null && kuotaPeserta.trim().isNotEmpty) {
      request.fields['kuota_peserta'] = kuotaPeserta.trim();
    }

    for (var i = 0; i < informasiTambahan.length; i++) {
      final info = informasiTambahan[i];
      request.fields['informasi_tambahan[$i][kelompok_informasi]'] =
          (info['kelompok_informasi'] ?? '').toString().trim();
      request.fields['informasi_tambahan[$i][label_informasi]'] =
          (info['label_informasi'] ?? '').toString().trim();
      request.fields['informasi_tambahan[$i][nilai_informasi]'] =
          (info['nilai_informasi'] ?? '').toString().trim();
      request.fields['informasi_tambahan[$i][urutan]'] =
          (info['urutan'] ?? (i + 1)).toString();
    }

    for (var i = 0; i < formFields.length; i++) {
      final field = formFields[i];
      request.fields['form_fields[$i][nama_field]'] =
          (field['nama_field'] ?? '').toString().trim();
      request.fields['form_fields[$i][tipe_field]'] =
          (field['tipe_field'] ?? 'Text').toString();
      request.fields['form_fields[$i][placeholder]'] =
          (field['placeholder'] ?? '').toString();
      request.fields['form_fields[$i][wajib]'] = field['wajib'] == true
          ? '1'
          : '0';

      final options = field['opsi_field'];
      if (options is List) {
        for (var j = 0; j < options.length; j++) {
          request.fields['form_fields[$i][opsi_field][$j]'] = options[j]
              .toString();
        }
      }
    }

    final posterBytes = await poster.readAsBytes();
    if (posterBytes.isEmpty) {
      throw Exception('File poster kosong atau tidak dapat dibaca.');
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'poster_lomba',
        posterBytes,
        filename: poster.name,
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    final response = await http.Response.fromStream(streamedResponse)
        .timeout(const Duration(seconds: 30));
    final data = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw _responseError(response, data, 'Pengajuan lomba gagal dikirim.');
    }

    notifyDataChanged();
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

    notifyDataChanged();
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

    notifyDataChanged();
    return data;
  }

  // MENGAMBIL NOTIFIKASI DARI DATABASE MYSQL
  static Future<List<Map<String, dynamic>>> getNotifikasi({
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/notifikasi'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));

    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal mengambil notifikasi.');
    }
    final items = data['data'];
    if (items is! List) {
      throw Exception('Format data notifikasi tidak valid.');
    }
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // MENANDAI SATU NOTIFIKASI SUDAH DIBACA
  static Future<void> bacaNotifikasi({
    required String token,
    required int idNotifikasi,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/notifikasi/$idNotifikasi/baca'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal memperbarui notifikasi.');
    }
  }

  // MENANDAI SEMUA NOTIFIKASI SUDAH DIBACA
  static Future<void> bacaSemuaNotifikasi({required String token}) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/notifikasi/baca-semua'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal membaca semua notifikasi.');
    }
  }

  // MENGHAPUS NOTIFIKASI MILIK PENGGUNA LOGIN
  static Future<void> hapusNotifikasi({
    required String token,
    required int idNotifikasi,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/notifikasi/$idNotifikasi'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final data = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(response, data, 'Gagal menghapus notifikasi.');
    }
  }

  // Favorit bersifat privat per akun, termasuk administrator dan penyelenggara.
  static Future<List<Map<String, dynamic>>> getFavorit({
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/favorit'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final decoded = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw _responseError(
        response,
        decoded,
        'Gagal mengambil daftar favorit.',
      );
    }
    final items = decoded['data'];
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> setFavorit({
    required String token,
    required int idLomba,
    required bool favorite,
  }) async {
    final url = Uri.parse('$baseUrl/favorit/$idLomba');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = favorite
        ? await http
              .post(url, headers: headers)
              .timeout(const Duration(seconds: 15))
        : await http
              .delete(url, headers: headers)
              .timeout(const Duration(seconds: 15));
    final decoded = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _responseError(response, decoded, 'Gagal mengubah status favorit.');
    }
    notifyDataChanged();
  }

  // ==================== CHAT KHUSUS LOMBA ====================
  static Map<String, String> _authHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Future<Map<String, dynamic>> _secureJson(
    String token,
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = _authHeaders(token);
    if (body != null) headers['Content-Type'] = 'application/json';
    late final http.Response response;
    switch (method) {
      case 'POST':
        response = await http
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 20));
        break;
      case 'PATCH':
        response = await http
            .patch(
              uri,
              headers: headers,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 20));
        break;
      case 'PUT':
        response = await http
            .put(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 20));
        break;
      case 'DELETE':
        response = await http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
        break;
      default:
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
    }
    final result = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _responseError(response, result, 'Permintaan gagal.');
    }
    return result;
  }

  static List<Map<String, dynamic>> _listData(Map<String, dynamic> data) {
    final list = data['data'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getChatRooms({
    required String token,
  }) async {
    return _listData(await _secureJson(token, '/chat/rooms'));
  }

  static Future<Map<String, dynamic>> getChatMessages({
    required String token,
    required int idLomba,
    int afterId = 0,
  }) async =>
      _secureJson(token, '/chat/rooms/$idLomba/messages?after_id=$afterId');

  static Future<void> sendChatMessage({
    required String token,
    required int idLomba,
    required String message,
  }) async {
    await _secureJson(
      token,
      '/chat/rooms/$idLomba/messages',
      method: 'POST',
      body: {'isi_pesan': message},
    );
    notifyDataChanged();
  }

  // ==================== PANEL ADMIN ====================
  static Future<Map<String, dynamic>> getAdminOverview({
    required String token,
  }) async {
    final result = await _secureJson(token, '/admin/panel');
    return Map<String, dynamic>.from(result['data'] as Map);
  }

  static Future<List<Map<String, dynamic>>> getAdminCategories({
    required String token,
  }) async => _listData(await _secureJson(token, '/admin/kategori'));

  static Future<void> saveAdminCategory({
    required String token,
    int? id,
    required String nama,
    String deskripsi = '',
  }) async {
    await _secureJson(
      token,
      id == null ? '/admin/kategori' : '/admin/kategori/$id',
      method: id == null ? 'POST' : 'PUT',
      body: {'nama_kategori': nama, 'deskripsi_kategori': deskripsi},
    );
    notifyDataChanged();
  }

  static Future<void> deleteAdminCategory({
    required String token,
    required int id,
  }) async {
    await _secureJson(token, '/admin/kategori/$id', method: 'DELETE');
    notifyDataChanged();
  }

  static Future<List<Map<String, dynamic>>> getAdminUsers({
    required String token,
  }) async => _listData(await _secureJson(token, '/admin/pengguna'));

  static Future<List<Map<String, dynamic>>> getAdminLomba({
    required String token,
  }) async => _listData(await _secureJson(token, '/admin/semua-lomba'));
  static Future<Map<String, dynamic>> getAdminLombaDetail({
    required String token,
    required int id,
  }) async {
    final result = await _secureJson(token, '/admin/semua-lomba/$id');
    return Map<String, dynamic>.from(result['data'] as Map);
  }

  static Future<void> cancelAdminLomba({
    required String token,
    required int id,
    required String alasan,
  }) async {
    await _secureJson(
      token,
      '/admin/semua-lomba/$id/batalkan',
      method: 'PATCH',
      body: {'alasan': alasan},
    );
    notifyDataChanged();
  }

  static Future<void> stopAdminLomba({
    required String token,
    required int id,
    required String alasan,
  }) async {
    await _secureJson(
      token,
      '/admin/semua-lomba/$id/hentikan',
      method: 'PATCH',
      body: {'alasan': alasan},
    );
    notifyDataChanged();
  }
}
