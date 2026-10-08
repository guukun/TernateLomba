// Mengubah Map Dart ke JSON dan membaca JSON dari Laravel.
import 'dart:convert';
// Mengirim permintaan HTTP dari Flutter.
import 'package:http/http.dart' as http;

// Semua permintaan ke API Laravel diletakkan dalam satu kelas.
class ApiService {
  // Alamat Laravel pada komputer yang menjalankan Flutter Web.
  static const baseUrl = 'http://127.0.0.1:8000/api';

  // Memastikan Flutter dapat menghubungi endpoint tes-koneksi.
  static Future<String> tesKoneksi() async {
    final response = await http.get(Uri.parse('$baseUrl/tes-koneksi'));
    if (response.statusCode != 200) {
      throw Exception('Server merespons ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['pesan'] as String;
  }


  // Mengirim username dan password; berhasil jika server memberi status 200.
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['pesan'] ?? data['message'] ?? 'Login gagal');
    }
    return data;
  }

  // Mengirim nama, password, dan konfirmasi; status 201 berarti akun dibuat.
  static Future<Map<String, dynamic>> register(
    String username, String password, String confirmation,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      // Laravel membandingkan password_confirmation dengan password.
      body: jsonEncode({
        'username': username,
        'password': password,
        'password_confirmation': confirmation,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? data['pesan'] ?? 'Pendaftaran gagal');
    }
    return data;
  }
}
