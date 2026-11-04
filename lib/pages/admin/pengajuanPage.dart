import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'detailPengajuanPage.dart'; // Pastikan nama file sesuai

class PengajuanPage extends StatefulWidget {
  final String token;

  const PengajuanPage({super.key, required this.token});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> {
  static const _blue = Color(0xFF3478E5);
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  // Tab & filter state
  int _activeTab = 0; // 0 = Pengajuan Lomba, 1 = Lomba Terpublikasi
  String _activeFilter = 'Semua'; // Semua, Menunggu Verifikasi, Disetujui

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

  // Filter items berdasarkan status
  List<Map<String, dynamic>> get _filteredItems {
    if (_activeFilter == 'Semua') return _items;
    return _items.where((item) {
      final status = (item['status_pengajuan']?.toString() ?? '').toLowerCase();
      if (_activeFilter == 'Menunggu Verifikasi') return status == 'menunggu';
      if (_activeFilter == 'Disetujui') return status == 'disetujui';
      return true;
    }).toList();
  }

  // Format tanggal menjadi "10 Nov 2024"
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Warna logo berdasarkan kategori/jenis lomba
  Color _logoColor(String namaLomba) {
    final name = namaLomba.toLowerCase();
    if (name.contains('web') || name.contains('desain')) return const Color(0xFF1B5E20);
    if (name.contains('hack')) return const Color(0xFF1A237E);
    return const Color(0xFF1B2A4A);
  }

  IconData _logoIcon(String namaLomba) {
    final name = namaLomba.toLowerCase();
    if (name.contains('web') || name.contains('desain')) return Icons.web;
    if (name.contains('hack')) return Icons.code;
    return Icons.menu_book;
  }

  String _logoLabel(String namaLomba) {
    final name = namaLomba.toLowerCase();
    if (name.contains('web')) return 'WEB 2024';
    if (name.contains('hack')) return 'HACK 2024';
    if (name.contains('lk ti') || name.contains('karya tulis')) return 'LKTI 2024';
    return '2024';
  }

  Widget _card(Map<String, dynamic> item) {
    final status = item['status_pengajuan']?.toString() ?? 'Menunggu Verifikasi';
    final statusLower = status.toLowerCase();
    final tanggal = _formatDate(
      item['tanggal_pengajuan']?.toString() ?? item['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
    final penyelenggara = item['penyelenggara'] is Map
        ? (item['penyelenggara'] as Map)['username']?.toString() ??
            (item['penyelenggara'] as Map)['nama']?.toString() ?? '-'
        : item['penyelenggara']?.toString() ?? '-';

    final isMenunggu = statusLower == 'menunggu' || statusLower.contains('menunggu');
    final isDisetujui = statusLower == 'disetujui' || statusLower.contains('disetujui');

    final statusText = isMenunggu ? 'Menunggu Verifikasi' : (isDisetujui ? 'Disetujui' : status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo box
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _logoColor(item['nama_lomba']?.toString() ?? ''),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_logoIcon(item['nama_lomba']?.toString() ?? ''),
                          color: Colors.white, size: 24),
                      const SizedBox(height: 2),
                      Text(
                        _logoLabel(item['nama_lomba']?.toString() ?? ''),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Status + date + title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMenunggu
                                  ? const Color(0xFFFFF9E6)
                                  : isDisetujui
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isMenunggu
                                        ? const Color(0xFFFFA726)
                                        : isDisetujui
                                            ? const Color(0xFF43A047)
                                            : const Color(0xFFE53935),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isMenunggu
                                        ? const Color(0xFFE65100)
                                        : isDisetujui
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFC62828),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            tanggal,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['nama_lomba']?.toString() ?? 'Lomba tanpa nama',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_outlined, size: 14, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              penyelenggara,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Detail Pengajuan button - aligned right
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _blue, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: () async {
                      // ✅ NAVIGASI KE HALAMAN DETAIL
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPengajuanPage(
                            token: widget.token,
                            item: item,
                          ),
                        ),
                      );
                      
                      // Refresh list jika ada perubahan (misal setelah approve/reject)
                      if (result != null) {
                        _load();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Detail Pengajuan',
                            style: TextStyle(
                              color: _blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: _blue, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: const [
                  Text(
                    'Pengajuan',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),

            // Tab switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Pengajuan Lomba',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _activeTab == 0 ? const Color(0xFF1A1A2E) : const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _activeTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Lomba Terpublikasi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _activeTab == 1 ? const Color(0xFF1A1A2E) : const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _filterChip('Semua'),
                  const SizedBox(width: 8),
                  _filterChip('Menunggu Verifikasi'),
                  const SizedBox(width: 8),
                  _filterChip('Disetujui'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Content
            Expanded(
              child: _loading
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
                          child: filtered.isEmpty
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
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, index) => _card(filtered[index]),
                                ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _filterChip(String label) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _blue : const Color(0xFFD0D5DD),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_outlined, 'Beranda', false),
            _navItem(Icons.emoji_events_outlined, 'Lomba Saya', false),
            _navItem(Icons.add_circle_outline, 'Ajukan', false),
            _navItem(Icons.person_outline, 'Profile', false),
            _navItem(Icons.description_outlined, 'Pengajuan', true),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    return GestureDetector(
      onTap: () {
        // Handle navigation
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? _blue : const Color(0xFF9E9E9E), size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _blue : const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}