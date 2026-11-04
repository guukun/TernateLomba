
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(
      Map<String, dynamic> json) {

    final rawId = json['id'] ??
        json['id_notifikasi'] ??
        json['notification_id'];

    final rawTitle = json['judul'] ??
        json['title'] ??
        json['nama_notifikasi'] ??
        'Notifikasi';

    final rawMessage = json['isi'] ??
        json['pesan'] ??
        json['message'] ??
        json['deskripsi'] ??
        '';

    final rawDate = json['created_at'] ??
        json['tanggal_dibuat'] ??
        json['waktu'];

    final rawRead = json['is_read'] ??
        json['dibaca'] ??
        json['sudah_dibaca'];

    bool readStatus = false;

    if (rawRead is bool) {
      readStatus = rawRead;
    } else if (rawRead is num) {
      readStatus = rawRead != 0;
    } else if (rawRead != null) {
      readStatus = ['1', 'true', 'yes']
          .contains(rawRead.toString().toLowerCase());
    } else {
      readStatus = json['read_at'] != null;
    }

    return NotificationModel(
      id: int.tryParse(rawId?.toString() ?? '') ?? 0,
      title: rawTitle.toString(),
      message: rawMessage.toString(),
      createdAt: rawDate == null
          ? null
          : DateTime.tryParse(rawDate.toString()),
      isRead: readStatus,
    );
  }

  String get timeLabel {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    }

    if (difference.inDays == 1) {
      return 'Kemarin';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    }

    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }
}
