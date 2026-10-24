import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  // Alamat Laravel.
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  // static const String baseUrl = 'http://10.245.39.67:8000/api';

  // MEMBACA RESPONSE JSON
  // Fungsi ini mencegah error ketika Laravel
  // mengembalikan response yang bukan JSON.
  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Server mengembalikan respons yang tidak valid '
        '(HTTP ${response.statusCode}). '
        'Periksa terminal Laravel.',
      );
    }
  }

  // TES KONEKSI
  static Future<String> tesKoneksi() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tes-koneksi'),
      headers: {'Accept': 'application/json'},
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['pesan'] ??
            data['message'] ??
            'Server merespons ${response.statusCode}',
      );
    }

    return data['pesan']?.toString() ?? 'Koneksi berhasil';
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = _decodeResponse(response);

    // Laravel mengembalikan 200 jika login berhasil.
    if (response.statusCode != 200) {
      throw Exception(data['pesan'] ?? data['message'] ?? 'Login gagal');
    }

    return data;
  }

  // REGISTER
  static Future<Map<String, dynamic>> register(
    String username,
    String password,
    String confirmation,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      body: jsonEncode({
        'username': username,
        'password': password,

        // Laravel membutuhkan field ini
        // karena menggunakan validator "confirmed".
        'password_confirmation': confirmation,
      }),
    );

    final data = _decodeResponse(response);

    // Laravel mengembalikan 201
    // ketika akun berhasil dibuat.
    if (response.statusCode != 201) {
      throw Exception(data['pesan'] ?? data['message'] ?? 'Pendaftaran gagal');
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

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),

      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',

        // Token Sanctum dari hasil login.
        'Authorization': 'Bearer $token',
      },

      body: jsonEncode(body),
    );

    final data = _decodeResponse(response);

    // Laravel mengembalikan 200
    // ketika profil berhasil diperbarui.
    if (response.statusCode != 200) {
      throw Exception(
        data['pesan'] ?? data['message'] ?? 'Gagal memperbarui profil',
      );
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
      throw Exception(
        data['pesan'] ?? data['message'] ?? 'Gagal mengunggah foto profil',
      );
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
      throw Exception(
        data['pesan'] ?? data['message'] ?? 'Gagal mengambil profil pengguna',
      );
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
}
