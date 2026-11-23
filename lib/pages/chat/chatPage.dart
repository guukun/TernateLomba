import '../../widgets/app_feedback.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/appTheme.dart';
import '../../design_system/tl_playful.dart';
import '../../design_system/tl_conversation.dart';
import '../../services/api_service.dart';

class ChatPage extends StatefulWidget {
  final String token;
  const ChatPage({super.key, required this.token});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  Timer? _poll;
  bool _loading = true;
  bool _busy = false;
  bool _active = true;
  String? _error;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetch();
    ApiService.dataRevision.addListener(_onRevision);
    _poll = Timer.periodic(Duration(seconds: 6), (_) {
      if (_active) _fetch(silent: true);
    });
  }

  void _onRevision() => _fetch(silent: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) _fetch(silent: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ApiService.dataRevision.removeListener(_onRevision);
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool silent = false}) async {
    if (_busy) return;
    _busy = true;
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final rooms = await ApiService.getChatRooms(token: widget.token);
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted && (!silent || _rooms.isEmpty)) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tl.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: _loading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _chatHeading(context),
                    const SizedBox(height: 70),
                    const Center(child: CircularProgressIndicator()),
                  ],
                )
              : _error != null && _rooms.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _chatHeading(context),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            color: context.tl.grey,
                            size: 40,
                          ),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: () => _fetch(),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : _rooms.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _chatHeading(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(26, 95, 26, 20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 50,
                            color: context.tl.primary,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Belum ada ruang chat',
                            style: TextStyle(
                              color: context.tl.navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Room akan muncul otomatis setelah penyelenggara menerima pendaftaranmu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.tl.grey,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                  itemCount: _rooms.length + 1,
                  separatorBuilder: (_, index) =>
                      SizedBox(height: index == 0 ? 18 : 11),
                  itemBuilder: (context, index) {
                    if (index == 0) return _chatHeading(context);
                    final room = _rooms[index - 1];
                    final id = int.tryParse('${room['id_lomba']}') ?? 0;
                    final active = room['status_lomba']?.toString() == 'Aktif';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildChatRoomCard(context, room, id, active),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _chatHeading(BuildContext context) => TLPlayful.decoratedHeading(
    context,
    title: 'Stay in\nthe loop.',
    subtitle: 'Percakapan penting untuk lomba yang kamu ikuti.',
    accent: context.tl.lavender,
    icon: Icons.forum_rounded,
  );

  Widget _buildChatRoomCard(
    BuildContext context,
    Map<String, dynamic> room,
    int id,
    bool active,
  ) {
    return Material(
      color: context.tl.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: id > 0
            ? () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatRoomPage(token: widget.token, room: room),
                  ),
                );
                if (mounted) _fetch(silent: true);
              }
            : null,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 17, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.tl.fieldBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: context.tl.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.forum_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${room['nama_lomba'] ?? 'Lomba'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.tl.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      room['pesan_terakhir']?.toString().isNotEmpty == true
                          ? '${room['pesan_terakhir']}'
                          : (room['is_penyelenggara'] == true
                                ? 'Ruang untuk peserta lombamu'
                                : 'Kamu sudah diterima sebagai peserta'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.tl.grey, fontSize: 12),
                    ),
                    SizedBox(height: 6),
                    Text(
                      active ? '● Aktif' : '● Selesai · arsip',
                      style: TextStyle(
                        color: active ? context.tl.green : context.tl.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.tl.navy),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> room;
  const ChatRoomPage({super.key, required this.token, required this.room});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage>
    with WidgetsBindingObserver {
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _poll;
  bool _active = true;
  bool _loading = true;
  bool _fetching = false;
  bool _sending = false;
  bool _readOnly = false;
  int? _myUserId;
  String? _error;
  final List<Map<String, dynamic>> _messages = [];

  int get _idLomba => int.tryParse('${widget.room['id_lomba']}') ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetch();
    _loadIdentity();
    _poll = Timer.periodic(Duration(seconds: 3), (_) {
      if (_active) _fetch(silent: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) _fetch(silent: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadIdentity() async {
    try {
      final user = await ApiService.getCurrentUser(token: widget.token);
      if (!mounted) return;
      setState(() {
        _myUserId = int.tryParse('${user['id_user']}');
      });
    } catch (_) {
      /* identitas visual opsional; akses tetap diperiksa server */
    }
  }

  void _goBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _fetch({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;
    final last = _messages.isEmpty
        ? 0
        : int.tryParse('${_messages.last['id_pesan']}') ?? 0;
    try {
      final data = await ApiService.getChatMessages(
        token: widget.token,
        idLomba: _idLomba,
        afterId: last,
      );
      if (!mounted) return;
      final list =
          (data['data'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      var changed = false;
      setState(() {
        _readOnly = data['read_only'] == true;
        _loading = false;
        _error = null;
        final ids = _messages.map((e) => e['id_pesan']).toSet();
        for (final m in list) {
          if (!ids.contains(m['id_pesan'])) {
            _messages.add(m);
            changed = true;
          }
        }
      });
      if (changed) _goBottom();
    } catch (e) {
      if (!mounted) return;
      final reason = e.toString().replaceFirst('Exception: ', '');
      if (reason.contains('HTTP 403') || reason.contains('HTTP 404')) {
        setState(() {
          _messages.clear();
          _readOnly = true;
          _loading = false;
          _error = 'Akses room sudah tidak tersedia.';
        });
      } else if (!silent || _messages.isEmpty) {
        setState(() {
          _loading = false;
          _error = reason;
        });
      }
    } finally {
      _fetching = false;
    }
  }

  Future<void> _send() async {
    final message = _text.text.trim();
    if (message.isEmpty || _sending || _readOnly) return;
    setState(() => _sending = true);
    try {
      await ApiService.sendChatMessage(
        token: widget.token,
        idLomba: _idLomba,
        message: message,
      );
      _text.clear();
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
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(dynamic value) {
    final dt = DateTime.tryParse('${value ?? ''}')?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.room['is_penyelenggara'] == true;
    return Scaffold(
      backgroundColor: context.tl.background,
      appBar: AppBar(
        backgroundColor: context.tl.background,
        foregroundColor: context.tl.navy,
        toolbarHeight: 79,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.tl.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.forum_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.room['nama_lomba'] ?? 'Room Chat'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isOwner ? 'Ruang penyelenggara' : 'Ruang peserta diterima',
                    style: TextStyle(color: context.tl.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_readOnly)
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Lomba selesai · percakapan hanya dapat dibaca',
                  style: TextStyle(color: context.tl.grey, fontSize: 12),
                ),
              ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator())
                  : _error != null && _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada pesan. Mulai percakapan!',
                        style: TextStyle(color: context.tl.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        final ownerText =
                            m['username']?.toString() ?? 'Pengguna';
                        final own =
                            _myUserId != null &&
                            _myUserId == int.tryParse('${m['id_user']}');
                        return TLMessageBubble(
                          own: own,
                          sender: ownerText,
                          avatarUrl: m['foto_profil_url']?.toString(),
                          message: '${m['isi_pesan'] ?? ''}',
                          time: _time(m['created_at']),
                        );
                      },
                    ),
            ),
            if (!_readOnly)
              Container(
                padding: EdgeInsets.fromLTRB(16, 13, 16, 18),
                decoration: BoxDecoration(
                  color: context.tl.background,
                  border: Border(
                    top: BorderSide(color: context.tl.fieldBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        maxLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        maxLength: 2000,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Tulis pesan…',
                          fillColor: context.tl.fieldBg,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(19),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      style: IconButton.styleFrom(
                        backgroundColor: context.tl.primary,
                      ),
                      icon: _sending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
