
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/notification_model.dart';

class NotificationService {
  final String baseApiUrl;

  const NotificationService({
    required this.baseApiUrl,
  });

  Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  dynamic _decode(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(
        response.body.isEmpty ? '{}' : response.body,
      );
    } catch (_) {
      throw Exception('Respons server bukan JSON.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['message'] ?? 'Permintaan gagal'
          : 'Permintaan gagal';

      throw Exception(
        '$message (HTTP ${response.statusCode})',
      );
    }

    return decoded;
  }

  List<NotificationModel> _parseList(dynamic decoded) {
    dynamic rows = decoded;

    if (decoded is Map) {
      rows = decoded['data'] ??
          decoded['notifikasi'] ??
          decoded['notifications'] ??
          [];

      if (rows is Map) {
        rows = rows['data'] ?? rows['items'] ?? [];
      }
    }

    if (rows is! List) {
      throw Exception('Format data notifikasi tidak sesuai.');
    }

    return rows
        .whereType<Map>()
        .map((item) => NotificationModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  // Mengambil semua notifikasi
  Future<List<NotificationModel>> getNotifications({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseApiUrl/notifikasi'),
      headers: _headers(token),
    );

    return _parseList(_decode(response));
  }

  // Mengambil jumlah notifikasi belum dibaca
  Future<int> getUnreadCount({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseApiUrl/notifikasi/unread-count'),
      headers: _headers(token),
    );

    final decoded = _decode(response);

    if (decoded is Map) {
      final value = decoded['unread_count'] ??
          decoded['count'] ??
          decoded['jumlah'] ??
          decoded['total'] ??
          decoded['data'];

      if (value is Map) {
        return int.tryParse(
          (value['unread_count'] ?? value['count'] ?? 0)
              .toString(),
        ) ?? 0;
      }

      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return int.tryParse(decoded.toString()) ?? 0;
  }

  // Menandai satu notifikasi sudah dibaca
  Future<void> markAsRead({
    required String token,
    required int id,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseApiUrl/notifikasi/$id/read'),
      headers: _headers(token),
    );

    _decode(response);
  }

  // Menandai semua notifikasi sudah dibaca
  Future<void> markAllAsRead({
    required String token,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseApiUrl/notifikasi/read-all'),
      headers: _headers(token),
    );

    _decode(response);
  }

  // Menghapus notifikasi
  Future<void> deleteNotification({
    required String token,
    required int id,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseApiUrl/notifikasi/$id'),
      headers: _headers(token),
    );

    _decode(response);
  }
}
