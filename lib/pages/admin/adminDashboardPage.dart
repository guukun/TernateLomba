import '../../widgets/app_feedback.dart';
import '../../widgets/competition_poster_card.dart';
import '../../widgets/competition_card_grid.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/appTheme.dart';
import '../../design_system/tl_playful.dart';
import '../../services/api_service.dart';
import 'adminLombaDetailPage.dart';

class AdminDashboardPage extends StatefulWidget {
  final String token;
  final VoidCallback onOpenPengajuan;
  final bool showHeader;
  final bool embedded;

  const AdminDashboardPage({
    super.key,
    required this.token,
    required this.onOpenPengajuan,
    this.showHeader = true,
    this.embedded = false,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Timer? _timer;
  bool _busy = false;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _overview = {};

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(Duration(seconds: 8), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_busy) return;
    _busy = true;
    try {
      final data = await ApiService.getAdminOverview(token: widget.token);
      if (!mounted) return;
      setState(() {
        _overview = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted && (!silent || _overview.isEmpty)) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      _busy = false;
    }
  }

  Widget _stat(String label, String key, IconData icon, {bool dark = false}) {
    final foreground = dark ? Colors.white : context.tl.navy;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF171717) : context.tl.fieldBg,
        border: Border.all(
          color: dark ? const Color(0xFF171717) : context.tl.fieldBorder,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: .14)
                      : context.tl.surface,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: foreground, size: 19),
              ),
              Icon(
                Icons.north_east_rounded,
                color: foreground.withValues(alpha: .34),
                size: 15,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_overview[key] ?? '-'}',
            maxLines: 1,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: 29,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground.withValues(alpha: dark ? .80 : .66),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortcut(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback callback, {
    bool dark = false,
    bool horizontal = false,
  }) {
    final foreground = dark ? Colors.white : context.tl.navy;
    final secondary = dark
        ? Colors.white.withValues(alpha: .76)
        : context.tl.grey;
    final tileBg = dark ? const Color(0xFF171717) : context.tl.surface;
    final tileBorder = dark ? const Color(0xFF171717) : context.tl.fieldBorder;
    final iconBg = dark
        ? Colors.white.withValues(alpha: .14)
        : context.tl.primary.withValues(alpha: .10);
    final iconColor = dark ? Colors.white : context.tl.primary;
    return Material(
      color: tileBg,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: callback,
        child: Container(
          padding: EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: tileBorder),
          ),
          child: (dark || horizontal)
              ? Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: iconColor, size: 23),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondary,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: foreground.withValues(alpha: .72),
                      size: 22,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: iconColor, size: 23),
                    ),
                    SizedBox(height: 12),
                    Text(
                      title,
                      maxLines: 1,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _open(Widget page) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => page))
          .then((_) => _load(silent: true));

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      shrinkWrap: widget.embedded,
      physics: widget.embedded
          ? NeverScrollableScrollPhysics()
          : AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: widget.embedded ? 125 : 160),
      children: [
        if (widget.showHeader)
          TLPlayful.decoratedHeading(
            context,
            title: 'Admin\nworkspace.',
            subtitle:
                'Pantau aktivitas dan kelola kompetisi dalam satu tempat.',
            accent: context.tl.mint,
            icon: Icons.space_dashboard_rounded,
          ),
        Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading) Center(child: CircularProgressIndicator()),
              if (_error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: context.tl.error),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.tl.primary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Less noise.\nMore control.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              height: 1.17,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Semua yang perlu kamu kelola, dalam satu ruang fokus.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .88),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 72,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 23),
              Text(
                'Ringkasan Sistem',
                style: TextStyle(
                  color: context.tl.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 13),
              // Fixed grid: all metrics are visible without horizontal scrolling.
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 680 ? 4 : 2;
                  final gap = 10.0;
                  final itemWidth =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        height: 134,
                        child: _stat(
                          'Kategori',
                          'jumlah_kategori',
                          Icons.category_outlined,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        height: 134,
                        child: _stat(
                          'Lomba aktif',
                          'lomba_aktif',
                          Icons.emoji_events_outlined,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        height: 134,
                        child: _stat(
                          'Pengajuan baru',
                          'pengajuan_menunggu',
                          Icons.assignment_outlined,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        height: 134,
                        child: _stat(
                          'Pengguna',
                          'jumlah_pengguna',
                          Icons.people_outline,
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 25),
              Text(
                'Kelola Platform',
                style: TextStyle(
                  color: context.tl.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 13),
              LayoutBuilder(
                builder: (context, constraints) {
                  final gap = 11.0;
                  final half = (constraints.maxWidth - gap) / 2;
                  return Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: half,
                            height: 132,
                            child: _shortcut(
                              'Kategori Lomba',
                              'Tambah, edit, dan hapus kategori',
                              Icons.category_rounded,
                              () =>
                                  _open(AdminCategoryPage(token: widget.token)),
                            ),
                          ),
                          SizedBox(width: gap),
                          SizedBox(
                            width: half,
                            height: 132,
                            child: _shortcut(
                              'Seluruh Lomba',
                              'Lihat semua lomba dan statusnya',
                              Icons.emoji_events_outlined,
                              () => _open(
                                AdminListPage(
                                  token: widget.token,
                                  users: false,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      SizedBox(
                        width: double.infinity,
                        height: 112,
                        child: _shortcut(
                          'Pengajuan Lomba',
                          'Tinjau dan verifikasi pengajuan baru',
                          Icons.assignment_turned_in_outlined,
                          widget.onOpenPengajuan,
                          dark: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
    if (widget.embedded) return list;
    return Scaffold(
      backgroundColor: context.tl.background,
      body: SafeArea(
        top: widget.showHeader,
        bottom: false,
        child: RefreshIndicator(onRefresh: _load, child: list),
      ),
    );
  }
}

class AdminCategoryPage extends StatefulWidget {
  final String token;
  const AdminCategoryPage({super.key, required this.token});
  @override
  State<AdminCategoryPage> createState() => _AdminCategoryPageState();
}

class _AdminCategoryPageState extends State<AdminCategoryPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('teknologi')) return Icons.code_rounded;
    if (n.contains('olahraga')) return Icons.sports_basketball_outlined;
    if (n.contains('seni')) return Icons.palette_outlined;
    if (n.contains('akademik')) return Icons.school_outlined;
    return Icons.category_outlined;
  }

  Future<void> _fetch() async {
    try {
      final items = await ApiService.getAdminCategories(token: widget.token);
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? value]) async {
    final name = TextEditingController(
      text: value?['nama_kategori']?.toString() ?? '',
    );
    final description = TextEditingController(
      text: value?['deskripsi_kategori']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final shouldSave = await AppPopup.form(
      context: context,
      title: value == null ? 'Tambah Kategori' : 'Edit Kategori',
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              maxLength: 100,
              decoration: InputDecoration(labelText: 'Nama kategori'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Nama kategori wajib diisi'
                  : null,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: description,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(labelText: 'Deskripsi (opsional)'),
            ),
          ],
        ),
      ),
      validate: () => formKey.currentState?.validate() ?? false,
    );
    final nama = name.text.trim();
    final deskripsi = description.text.trim();
    // Tunggu animasi penutupan dialog selesai sebelum melepas controller.
    await Future<void>.delayed(Duration(milliseconds: 300));
    name.dispose();
    description.dispose();
    if (shouldSave != true || !mounted || _saving) return;
    setState(() => _saving = true);
    try {
      await ApiService.saveAdminCategory(
        token: widget.token,
        id: value == null ? null : int.tryParse('${value['id_kategori']}'),
        nama: nama,
        deskripsi: deskripsi,
      );
      await _fetch();
    } catch (e) {
      if (mounted) {
        AppNotification.message(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          type: NotificationType.info,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await AppConfirmDialog.show(
      context: context,
      title: 'Hapus kategori?',
      message:
          'Kategori "${item['nama_kategori']}" hanya dapat dihapus jika belum digunakan lomba.',
      confirmText: 'Hapus',
      confirmColor: context.tl.error,
    );
    if (ok != true || !mounted || _saving) return;
    final id = int.tryParse('${item['id_kategori']}');
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await ApiService.deleteAdminCategory(token: widget.token, id: id);
      await _fetch();
    } catch (e) {
      if (mounted) {
        AppNotification.message(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          type: NotificationType.info,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Kategori Lomba'),
      backgroundColor: context.tl.background,
      foregroundColor: context.tl.navy,
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _saving ? null : () => _edit(),
      backgroundColor: context.tl.primary,
      foregroundColor: Colors.white,
      icon: Icon(Icons.add),
      label: Text('Tambah Kategori'),
    ),
    body: _loading
        ? Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(child: Text(_error!))
        : RefreshIndicator(
            onRefresh: _fetch,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(17, 12, 17, 120),
              itemCount: _items.length + 1,
              separatorBuilder: (_, _) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _sectionIntro(
                    context,
                    'Kelola Kategori',
                    '${_items.length} kategori tersedia • Tambah dan ubah kategori lomba.',
                    Icons.category_outlined,
                  );
                }
                index--;
                final item = _items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: context.tl.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: context.tl.fieldBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .035),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: Container(
                      padding: EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: context.tl.cream,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _categoryIcon('${item['nama_kategori']}'),
                        color: context.tl.primary,
                      ),
                    ),
                    title: Text(
                      '${item['nama_kategori']}',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${item['deskripsi_kategori'] ?? 'Tanpa deskripsi'}',
                    ),
                    trailing: AppPopup.menu<String>(
                      context: context,
                      tooltip: 'Aksi kategori',
                      position: PopupMenuPosition.under,
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: context.tl.primary,
                      ),
                      onSelected: (action) =>
                          action == 'edit' ? _edit(item) : _delete(item),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: context.tl.primary,
                              ),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: context.tl.error,
                              ),
                              SizedBox(width: 10),
                              Text('Hapus'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
  );
}

class AdminListPage extends StatefulWidget {
  final String token;
  final bool users;
  const AdminListPage({super.key, required this.token, required this.users});
  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = widget.users
          ? await ApiService.getAdminUsers(token: widget.token)
          : await ApiService.getAdminLomba(token: widget.token);
      if (mounted) {
        setState(() {
          _items = data;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Widget _competitionGridCard(Map<String, dynamic> item) {
    final imagePath =
        item['poster_lomba']?.toString() ?? item['poster']?.toString() ?? '';
    return CompetitionPosterCard(
      compact: true,
      height: 278,
      title: '${item['nama_lomba'] ?? 'Lomba tanpa nama'}',
      posterUrl: ApiService.publicStorageUrl(imagePath),
      category:
          '${item['kategori'] is Map ? (item['kategori'] as Map)['nama_kategori'] ?? 'Kompetisi' : 'Kompetisi'}',
      organizer: '${item['penyelenggara'] ?? ''}',
      status: '${item['status_lomba'] ?? ''}',
      date: '${item['tanggal_pelaksanaan'] ?? ''}',
      meta: '${item['biaya'] ?? ''}'.trim().isEmpty
          ? 'Kelola kompetisi'
          : 'Biaya: ${item['biaya']}',
      secondaryMeta: 'Kuota: ${item['kuota_peserta'] ?? '-'} peserta',
      onTap: () async {
        final id = int.tryParse('${item['id_lomba']}');
        if (id == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                AdminLombaDetailPage(token: widget.token, lombaId: id),
          ),
        );
        if (mounted) _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.users ? 'Daftar Pengguna' : 'Seluruh Lomba'),
      backgroundColor: context.tl.background,
      foregroundColor: context.tl.navy,
    ),
    body: _loading
        ? Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(child: Text(_error!))
        : RefreshIndicator(
            onRefresh: _load,
            child: !widget.users
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _sectionIntro(
                        context,
                        'Semua Lomba',
                        '${_items.length} data tersedia • Tarik ke bawah untuk memperbarui.',
                        Icons.emoji_events_outlined,
                      ),
                      const SizedBox(height: 14),
                      CompetitionCardGrid(
                        itemCount: _items.length,
                        itemBuilder: (context, index) =>
                            _competitionGridCard(_items[index]),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 120),
                    itemCount: _items.length + 1,
                    separatorBuilder: (_, _) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _sectionIntro(
                          context,
                          widget.users ? 'Daftar Pengguna' : 'Semua Lomba',
                          '${_items.length} data tersedia • Tarik ke bawah untuk memperbarui.',
                          Icons.emoji_events_outlined,
                        );
                      }
                      index--;
                      final item = _items[index];
                      final title = widget.users
                          ? '${item['username']}'
                          : '${item['nama_lomba']}';
                      final subtitle = widget.users
                          ? '${item['role']}'
                          : '${item['penyelenggara']} • ${item['status_lomba']}';
                      if (!widget.users) {
                        final imagePath =
                            item['poster_lomba']?.toString() ??
                            item['poster']?.toString() ??
                            '';
                        return CompetitionPosterCard(
                          title: title,
                          posterUrl: ApiService.publicStorageUrl(imagePath),
                          category:
                              '${item['kategori'] is Map ? (item['kategori'] as Map)['nama_kategori'] ?? 'Kompetisi' : 'Kompetisi'}',
                          organizer: '${item['penyelenggara'] ?? ''}',
                          status: '${item['status_lomba'] ?? ''}',
                          meta: 'Kelola kompetisi',
                          secondaryMeta: 'Buka detail & tindakan admin',
                          date: '${item['tanggal_pelaksanaan'] ?? ''}',
                          onTap: () async {
                            final id = int.tryParse('${item['id_lomba']}');
                            if (id == null) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AdminLombaDetailPage(
                                  token: widget.token,
                                  lombaId: id,
                                ),
                              ),
                            );
                            if (mounted) _load();
                          },
                        );
                      }
                      return Card(
                        child: ListTile(
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(subtitle),
                          leading: const Icon(Icons.person_outline_rounded),
                        ),
                      );
                    },
                  ),
          ),
  );
}

Widget _sectionIntro(
  BuildContext context,
  String title,
  String subtitle,
  IconData icon,
) {
  final p = context.tl;
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: p.surface,
      border: Border.all(color: p.fieldBorder),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Row(
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: p.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: Colors.white, size: 25),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: p.navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(color: p.grey, fontSize: 12, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}