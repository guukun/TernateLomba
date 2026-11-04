import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class VerifikasiPengajuanPage extends StatefulWidget {
  final String token;

  const VerifikasiPengajuanPage({super.key, required this.token});

  @override
  State<VerifikasiPengajuanPage> createState() => _VerifikasiPengajuanPageState();
}

class _VerifikasiPengajuanPageState extends State<VerifikasiPengajuanPage> {
  static const _blue = Color(0xFF3478E5);
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int? _processingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading && _items.isNotEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getPengajuanLombaAdmin(token: widget.token);
      if (!mounted) return;
      final list = response['data'] as List;
      setState(() {
        _items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _decide(Map<String, dynamic> item, String decision) async {
    final id = int.tryParse(item['id_pengajuan']?.toString() ?? '');
    if (id == null) return;

    final noteController = TextEditingController();
    final approved = decision == 'Disetujui';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approved ? 'Setujui pengajuan?' : 'Tolak pengajuan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pengajuan "${item['nama_lomba'] ?? '-'}" akan ${approved ? 'disetujui' : 'ditolak'}.'),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: approved ? 'Catatan admin (opsional)' : 'Alasan penolakan',
                hintText: 'Tulis catatan untuk pengguna',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: approved ? Colors.green : Colors.red),
            child: Text(approved ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      noteController.dispose();
      return;
    }

    setState(() => _processingId = id);
    try {
      final result = await ApiService.putuskanPengajuanLomba(
        token: widget.token,
        idPengajuan: id,
        keputusan: decision,
        catatanAdmin: noteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['pesan']?.toString() ?? 'Keputusan tersimpan.')),
      );
      await _loadAfterAction();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      noteController.dispose();
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _loadAfterAction() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getPengajuanLombaAdmin(token: widget.token);
      if (!mounted) return;
      setState(() {
        _items = (response['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.orange.shade800;
    }
  }

  Widget _card(Map<String, dynamic> item) {
    final id = int.tryParse(item['id_pengajuan']?.toString() ?? '');
    final status = item['status_pengajuan']?.toString() ?? 'Menunggu';
    final pending = status.toLowerCase() == 'menunggu';
    final kategori = item['kategori'] is Map
        ? (item['kategori'] as Map)['nama_kategori']?.toString() ?? '-'
        : '-';
    final penyelenggara = item['penyelenggara'] is Map
        ? (item['penyelenggara'] as Map)['username']?.toString() ?? '-'
        : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5EAF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item['nama_lomba']?.toString() ?? 'Lomba tanpa nama',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: _statusColor(status),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Pengaju: $penyelenggara  •  Kategori: $kategori'),
            const SizedBox(height: 8),
            Text(item['deskripsi']?.toString() ?? '-', maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text('Pelaksanaan: ${item['tanggal_pelaksanaan'] ?? '-'}'),
            Text('Batas pendaftaran: ${item['batas_pendaftaran'] ?? '-'}'),
            if ((item['catatan_admin']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Catatan admin: ${item['catatan_admin']}', style: const TextStyle(color: Colors.blueGrey)),
            ],
            if (pending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processingId == id ? null : () => _decide(item, 'Ditolak'),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Tolak', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _processingId == id ? null : () => _decide(item, 'Disetujui'),
                      icon: const Icon(Icons.check),
                      label: const Text('Terima'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
              if (_processingId == id)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Verifikasi Pengajuan'),
        backgroundColor: const Color(0xFFEAF2FF),
        foregroundColor: const Color(0xFF202938),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Coba lagi')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 150),
                            Icon(Icons.inbox_outlined, size: 54, color: Colors.blueGrey),
                            SizedBox(height: 12),
                            Center(child: Text('Belum ada pengajuan lomba.')),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _items.length,
                          itemBuilder: (_, index) => _card(_items[index]),
                        ),
                ),
    );
  }
}
