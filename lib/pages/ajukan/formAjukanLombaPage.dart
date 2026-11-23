import '../../design_system/tl_playful.dart';
import '../../widgets/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/appTheme.dart';
import '../../services/api_service.dart';

// FormAjukanLombaPage
class FormAjukanLombaPage extends StatefulWidget {
  final String token;

  const FormAjukanLombaPage({super.key, required this.token});

  @override
  State<FormAjukanLombaPage> createState() => _FormAjukanLombaPageState();
}

class _FormAjukanLombaPageState extends State<FormAjukanLombaPage> {
  Color get _primary => context.tl.primary;
  Color get _cream => context.tl.cream;
  Color get _creamLight => context.tl.creamLight;
  Color get _text => context.tl.navy;
  Color get _muted => context.tl.grey;
  Color get _border => context.tl.fieldBorder;
  Color get _background => context.tl.background;

  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  int _step = 0;
  bool _loadingCategories = true;
  bool _submitting = false;
  String? _categoryError;
  List<Map<String, dynamic>> _categories = [];
  int? _categoryId;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _executionDetailController = TextEditingController();
  final _quotaController = TextEditingController();
  final _feeController = TextEditingController();

  DateTime? _registrationStart;
  DateTime? _registrationEnd;
  DateTime? _eventDate;
  DateTime? _eventEndDate;

  String _executionMethod = 'Offline';
  String _paymentType = 'Gratis';

  XFile? _poster;
  Uint8List? _posterBytes;

  final List<_InfoDraft> _additionalInfo = [];

  // Semua informasi bebas dari penyelenggara disimpan di satu kelompok.
  static const String _additionalInfoGroup = 'Informasi Tambahan';

  final List<_RegistrationFieldDraft> _registrationFields = [
    _RegistrationFieldDraft(
      name: 'Nama',
      type: 'Text',
      placeholder: 'Masukkan nama lengkap',
      requiredField: true,
      isDefault: true,
    ),
  ];

  static const List<String> _fieldTypes = [
    'Text',
    'Textarea',
    'Number',
    'Dropdown',
    'Date',
    'File',
    'Email',
    'Phone',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _executionDetailController.dispose();
    _quotaController.dispose();
    _feeController.dispose();
    for (final info in _additionalInfo) {
      info.dispose();
    }
    for (final field in _registrationFields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoryError = null;
    });
    try {
      final result = await ApiService.getKategori();
      if (!mounted) return;
      setState(() {
        _categories = result;
        _loadingCategories = false;
        if (result.isNotEmpty) {
          _categoryId = int.tryParse(result.first['id_kategori'].toString());
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoryError = _cleanError(e);
      });
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');

  String _date(DateTime? value) {
    if (value == null) return '';
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _dateLabel(DateTime? value) =>
      value == null ? 'Pilih tanggal' : _date(value);

  Future<void> _pickDate(String key) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? current;
    DateTime firstDate = today;

    switch (key) {
      case 'start':
        current = _registrationStart;
        break;
      case 'end':
        current = _registrationEnd;
        firstDate = _registrationStart ?? today;
        break;
      case 'event':
        current = _eventDate;
        firstDate = _registrationEnd ?? today;
        break;
      case 'eventEnd':
        current = _eventEndDate;
        firstDate = _eventDate ?? today;
        break;
    }
    if (firstDate.isBefore(today)) firstDate = today;

    final initialDate = current != null && !current.isBefore(firstDate)
        ? current
        : firstDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 10),
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: context.tl.primary,
            onPrimary: Colors.white,
            surface: context.tl.surface,
            onSurface: context.tl.navy,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (key == 'start') {
        _registrationStart = picked;
        if (_registrationEnd != null && _registrationEnd!.isBefore(picked)) {
          _registrationEnd = null;
        }
        if (_eventDate != null && _eventDate!.isBefore(picked)) {
          _eventDate = null;
          _eventEndDate = null;
        }
      } else if (key == 'end') {
        _registrationEnd = picked;
        if (_eventDate != null && _eventDate!.isBefore(picked)) {
          _eventDate = null;
          _eventEndDate = null;
        }
      } else if (key == 'event') {
        _eventDate = picked;
        if (_eventEndDate != null && _eventEndDate!.isBefore(picked)) {
          _eventEndDate = null;
        }
      } else if (key == 'eventEnd') {
        _eventEndDate = picked;
      }
    });
  }

  Future<void> _pickPoster() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (image == null) return;
      final extension = image.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        _message('Poster harus berformat JPG, JPEG, atau PNG.');
        return;
      }
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _message('Ukuran poster maksimal 5 MB.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _poster = image;
        _posterBytes = bytes;
      });
    } catch (e) {
      _message('Gagal memilih poster: ${_cleanError(e)}');
    }
  }

  void _message(String message, {bool success = false}) {
    if (!mounted) return;
    AppNotification.message(
      context,
      message,
      type: success ? NotificationType.success : NotificationType.error,
    );
  }

  InputDecoration _decoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: _primary, size: 19),
      filled: true,
      fillColor: context.tl.fieldBg,
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.tl.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.tl.error, width: 1.4),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final p = context.tl;
    final accent = title.toLowerCase().contains('formulir')
        ? p.mint
        : title.toLowerCase().contains('poster')
        ? p.orange
        : p.lavender;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 20),
      decoration: TLPlayful.card(context, tint: accent, radius: 27),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: p.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: p.grey,
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        enabled: enabled && !_submitting,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        textCapitalization: maxLines > 1
            ? TextCapitalization.sentences
            : TextCapitalization.words,
        validator: validator,
        style: TextStyle(color: _text, fontSize: 14),
        decoration: _decoration(label, hint: hint),
      ),
    );
  }

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: _submitting ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: _decoration(label, icon: Icons.calendar_month_outlined),
          child: Text(
            _dateLabel(value),
            style: TextStyle(
              color: value == null ? _muted : _text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryInput() {
    if (_loadingCategories) {
      return Padding(
        padding: EdgeInsets.only(bottom: 15),
        child: LinearProgressIndicator(color: _primary),
      );
    }
    if (_categoryError != null) {
      return Container(
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.tl.statusBadBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _categoryError!,
                style: TextStyle(color: context.tl.error, fontSize: 12),
              ),
            ),
            TextButton(onPressed: _loadCategories, child: Text('Coba lagi')),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<int>(
        initialValue: _categoryId,
        isExpanded: true,
        decoration: _decoration(
          'Kategori lomba *',
          icon: Icons.category_outlined,
        ),
        items: _categories
            .map((item) {
              final id = int.tryParse(item['id_kategori'].toString());
              return DropdownMenuItem<int>(
                value: id,
                child: Text(
                  item['nama_kategori']?.toString() ?? '-',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            })
            .where((item) => item.value != null)
            .toList(),
        onChanged: _submitting
            ? null
            : (value) => setState(() => _categoryId = value),
        validator: (value) => value == null ? 'Kategori wajib dipilih.' : null,
      ),
    );
  }

  Widget _stageOne() {
    return Column(
      children: [
        _section(
          icon: Icons.emoji_events_outlined,
          title: 'Informasi Umum Lomba',
          subtitle: 'Informasi utama yang diperlukan untuk setiap lomba.',
          children: [
            _categoryInput(),
            _input(
              label: 'Nama lomba *',
              controller: _nameController,
              hint: 'Contoh: Kompetisi Inovasi Teknologi',
              validator: (v) => _required(v, 'Nama lomba'),
            ),
            _input(
              label: 'Deskripsi lomba *',
              controller: _descriptionController,
              hint: 'Jelaskan tujuan dan gambaran umum lomba.',
              maxLines: 4,
              validator: (v) => _required(v, 'Deskripsi lomba'),
            ),
            Text(
              'Periode pendaftaran *',
              style: TextStyle(
                color: _text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 9),
            Row(
              children: [
                _dateButton(
                  'Mulai pendaftaran',
                  _registrationStart,
                  () => _pickDate('start'),
                ),
                SizedBox(width: 10),
                _dateButton(
                  'Batas pendaftaran',
                  _registrationEnd,
                  () => _pickDate('end'),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                _dateButton(
                  'Mulai pelaksanaan *',
                  _eventDate,
                  () => _pickDate('event'),
                ),
                SizedBox(width: 10),
                _dateButton(
                  'Selesai pelaksanaan *',
                  _eventEndDate,
                  () => _pickDate('eventEnd'),
                ),
              ],
            ),
          ],
        ),
        _section(
          icon: Icons.laptop_mac_outlined,
          title: 'Pelaksanaan Lomba',
          subtitle:
              'Pilih metode pelaksanaan dan masukkan lokasi atau platform.',
          children: [
            DropdownButtonFormField<String>(
              initialValue: _executionMethod,
              decoration: _decoration(
                'Metode pelaksanaan *',
                icon: Icons.public,
              ),
              items: [
                DropdownMenuItem(value: 'Online', child: Text('Online')),
                DropdownMenuItem(value: 'Offline', child: Text('Offline')),
              ],
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _executionMethod = value;
                      });
                    },
            ),
            SizedBox(height: 15),
            _input(
              label: _executionMethod == 'Online'
                  ? 'Platform / tautan pelaksanaan *'
                  : 'Tempat pelaksanaan *',
              controller: _executionDetailController,
              hint: _executionMethod == 'Online'
                  ? 'Contoh: Zoom Meeting atau Google Meet'
                  : 'Contoh: Aula Kampus Universitas Khairun',
              validator: (v) => _required(
                v,
                _executionMethod == 'Online'
                    ? 'Platform pelaksanaan'
                    : 'Tempat pelaksanaan',
              ),
            ),
          ],
        ),
        _section(
          icon: Icons.groups_outlined,
          title: 'Kuota dan Biaya',
          subtitle: 'Kuota dapat dikosongkan jika tidak dibatasi.',
          children: [
            _input(
              label: 'Kuota peserta',
              controller: _quotaController,
              hint: 'Contoh: 100 (kosongkan jika tidak dibatasi)',
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            DropdownButtonFormField<String>(
              initialValue: _paymentType,
              decoration: _decoration(
                'Biaya pendaftaran *',
                icon: Icons.payments_outlined,
              ),
              items: [
                DropdownMenuItem(value: 'Gratis', child: Text('Gratis')),
                DropdownMenuItem(value: 'Berbayar', child: Text('Berbayar')),
              ],
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _paymentType = value;
                        if (value == 'Gratis') _feeController.clear();
                      });
                    },
            ),
            if (_paymentType == 'Berbayar') ...[
              SizedBox(height: 15),
              _input(
                label: 'Nominal biaya (Rp) *',
                controller: _feeController,
                hint: 'Contoh: 100.000',
                keyboardType: TextInputType.number,
                formatters: [ThousandsSeparatorInputFormatter()],
                validator: (value) {
                  if (_paymentType == 'Berbayar' &&
                      (value == null || value.isEmpty)) {
                    return 'Nominal biaya wajib diisi.';
                  }
                  if (value != null &&
                      value.isNotEmpty &&
                      int.tryParse(value.replaceAll('.', '')) == null) {
                    return 'Nominal biaya tidak valid.';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
        _posterSection(),
        _additionalInfoSection(),
      ],
    );
  }

  Widget _posterSection() {
    return _section(
      icon: Icons.image_outlined,
      title: 'Poster Lomba',
      subtitle: 'Poster wajib diunggah dalam format JPG, JPEG, atau PNG.',
      children: [
        InkWell(
          onTap: _submitting ? null : _pickPoster,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _creamLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _poster == null ? _border : _primary,
                width: 1.3,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _poster == null
                        ? Icons.cloud_upload_outlined
                        : Icons.check_circle_outline,
                    color: _primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _poster?.name ?? 'Pilih poster lomba',
                        style: TextStyle(
                          color: _text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'JPG / JPEG / PNG • Maksimal 5 MB',
                        style: TextStyle(color: _muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_photo_alternate_outlined, color: _primary),
              ],
            ),
          ),
        ),
        if (_posterBytes != null) ...[
          SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              _posterBytes!,
              height: 210,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _submitting
                  ? null
                  : () => setState(() {
                      _poster = null;
                      _posterBytes = null;
                    }),
              icon: Icon(Icons.delete_outline, color: context.tl.error),
              label: Text(
                'Hapus poster',
                style: TextStyle(color: context.tl.error),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _additionalInfoSection() {
    return _section(
      icon: Icons.add_box_outlined,
      title: 'Informasi Tambahan',
      subtitle: 'Tambahkan informasi lain yang diperlukan. Semua informasi akan ditampilkan dalam satu kelompok Informasi Tambahan.',
      children: [
        if (_additionalInfo.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _creamLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Belum ada informasi tambahan. Bagian ini boleh dikosongkan.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ),
        for (var i = 0; i < _additionalInfo.length; i++)
          Container(
            key: ObjectKey(_additionalInfo[i]),
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _creamLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Informasi ${i + 1}',
                        style: TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              final removed = _additionalInfo.removeAt(i);
                              removed.dispose();
                              setState(() {});
                            },
                      icon: Icon(
                        Icons.delete_outline,
                        color: context.tl.error,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _additionalInfo[i].label,
                  decoration: _decoration(
                    'Nama informasi *',
                    hint: 'Contoh: Tingkat lomba, sertifikat, fasilitas',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: 11),
                TextFormField(
                  controller: _additionalInfo[i].value,
                  maxLines: 2,
                  decoration: _decoration(
                    'Isi informasi *',
                    hint: 'Masukkan detail informasi',
                  ),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: _submitting || _additionalInfo.length >= 30
              ? null
              : () => setState(() => _additionalInfo.add(_InfoDraft())),
          icon: Icon(Icons.add),
          label: Text('Tambah informasi'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: BorderSide(color: _primary),
          ),
        ),
      ],
    );
  }

  Widget _stageTwo() {
    return _section(
      icon: Icons.dynamic_form_rounded,
      title: 'Formulir Pendaftaran Peserta',
      subtitle: 'Buat pertanyaan yang harus dijawab peserta saat mendaftar. Field Nama selalu tersedia dan wajib.',
      children: [
        for (var i = 0; i < _registrationFields.length; i++)
          _registrationFieldCard(i),
        OutlinedButton.icon(
          onPressed: _submitting || _registrationFields.length >= 30
              ? null
              : () => setState(
                  () => _registrationFields.add(_RegistrationFieldDraft()),
                ),
          icon: Icon(Icons.add),
          label: Text('Tambah field formulir'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: BorderSide(color: _primary),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Jenis field: Text, Textarea, Number, Dropdown, Date, File, Email, dan Phone.',
          style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
        ),
      ],
    );
  }

  Widget _registrationFieldCard(int index) {
    final field = _registrationFields[index];
    final isDefault = field.isDefault;
    return Container(
      key: ObjectKey(field),
      margin: EdgeInsets.only(bottom: 13),
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _creamLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault ? _primary.withValues(alpha: 0.35) : _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isDefault ? 'Field bawaan' : 'Field ${index + 1}',
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isDefault)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Wajib',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          final removed = _registrationFields.removeAt(index);
                          removed.dispose();
                          setState(() {});
                        },
                  icon: Icon(
                    Icons.delete_outline,
                    color: context.tl.error,
                    size: 20,
                  ),
                ),
            ],
          ),
          TextFormField(
            controller: field.name,
            enabled: !isDefault && !_submitting,
            decoration: _decoration(
              'Nama field *',
              hint: 'Contoh: Asal sekolah / instansi',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: 11),
          DropdownButtonFormField<String>(
            initialValue: field.type,
            decoration: _decoration('Jenis input'),
            items: _fieldTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: isDefault || _submitting
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        field.type = value;
                        if (value != 'Dropdown') field.options.clear();
                      });
                    }
                  },
          ),
          SizedBox(height: 11),
          TextFormField(
            controller: field.placeholder,
            enabled: !isDefault && !_submitting,
            decoration: _decoration(
              'Petunjuk pengisian (opsional)',
              hint: 'Contoh: Masukkan nomor induk mahasiswa',
            ),
          ),
          if (field.type == 'Dropdown' && !isDefault) ...[
            SizedBox(height: 11),
            TextFormField(
              controller: field.options,
              maxLines: 3,
              decoration: _decoration(
                'Pilihan dropdown *',
                hint: 'Satu pilihan per baris\nSMA\nSMK\nUniversitas',
              ),
            ),
          ],
          if (!isDefault)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: _primary,
              title: Text(
                'Wajib diisi peserta',
                style: TextStyle(
                  color: _text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value: field.requiredField,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => field.requiredField = value),
            ),
        ],
      ),
    );
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label wajib diisi.' : null;

  bool _validateStageOne() {
    if (_categoryId == null) {
      _message('Pilih kategori lomba terlebih dahulu.');
      return false;
    }
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _executionDetailController.text.trim().isEmpty) {
      _message('Lengkapi nama, deskripsi, dan detail pelaksanaan lomba.');
      return false;
    }
    if (_registrationStart == null ||
        _registrationEnd == null ||
        _eventDate == null ||
        _eventEndDate == null) {
      _message('Lengkapi keempat tanggal pendaftaran dan pelaksanaan.');
      return false;
    }
    if (_registrationEnd!.isBefore(_registrationStart!)) {
      _message(
        'Batas pendaftaran tidak boleh sebelum tanggal mulai pendaftaran.',
      );
      return false;
    }
    if (_eventDate!.isBefore(_registrationEnd!)) {
      _message('Tanggal pelaksanaan tidak boleh sebelum batas pendaftaran.');
      return false;
    }
    if (_eventEndDate!.isBefore(_eventDate!)) {
      _message(
        'Tanggal selesai pelaksanaan tidak boleh sebelum mulai pelaksanaan.',
      );
      return false;
    }
    if (_poster == null || _posterBytes == null) {
      _message('Poster lomba wajib diunggah.');
      return false;
    }
    final quota = _quotaController.text.trim();
    if (quota.isNotEmpty &&
        (int.tryParse(quota) == null || int.parse(quota) < 1)) {
      _message('Kuota harus berupa angka minimal 1.');
      return false;
    }
    if (_paymentType == 'Berbayar') {
      final fee = int.tryParse(_feeController.text.replaceAll('.', ''));
      if (fee == null || fee < 1) {
        _message('Masukkan nominal biaya pendaftaran yang valid.');
        return false;
      }
    }
    for (var i = 0; i < _additionalInfo.length; i++) {
      final info = _additionalInfo[i];
      final allEmpty =
          info.label.text.trim().isEmpty && info.value.text.trim().isEmpty;
      if (allEmpty) continue;
      if (info.label.text.trim().isEmpty || info.value.text.trim().isEmpty) {
        _message(
          'Lengkapi nama dan isi informasi tambahan nomor ${i + 1}, atau hapus baris tersebut.',
        );
        return false;
      }
    }
    return true;
  }

  bool _validateStageTwo() {
    if (_registrationFields.isEmpty || !_registrationFields.first.isDefault) {
      _message('Field Nama bawaan wajib tersedia.');
      return false;
    }
    for (var i = 0; i < _registrationFields.length; i++) {
      final field = _registrationFields[i];
      if (field.name.text.trim().isEmpty) {
        _message('Nama field nomor ${i + 1} wajib diisi.');
        return false;
      }
      if (field.type == 'Dropdown' && field.optionsList.isEmpty) {
        _message('Field Dropdown nomor ${i + 1} harus memiliki pilihan.');
        return false;
      }
    }
    return true;
  }

  void _scrollTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_step == 0 && !_validateStageOne()) return;
    if (_step == 1 && !_validateStageTwo()) return;
    if (_step < 2) {
      setState(() => _step++);
      _scrollTop();
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step--);
      _scrollTop();
    }
  }

  String _selectedCategoryName() {
    for (final category in _categories) {
      if (int.tryParse(category['id_kategori'].toString()) == _categoryId) {
        return category['nama_kategori']?.toString() ?? '-';
      }
    }
    return '-';
  }

  String _feeSummary() {
    if (_paymentType == 'Gratis') {
      return 'Gratis';
    }
    return 'Rp ${_feeController.text}';
  }

  List<Map<String, dynamic>> _infoPayload() {
    final result = <Map<String, dynamic>>[];
    for (final info in _additionalInfo) {
      if (info.label.text.trim().isEmpty && info.value.text.trim().isEmpty) {
        continue;
      }
      result.add({
        'kelompok_informasi': _additionalInfoGroup,
        'label_informasi': info.label.text.trim(),
        'nilai_informasi': info.value.text.trim(),
        'urutan': result.length + 1,
      });
    }
    return result;
  }

  List<Map<String, dynamic>> _formPayload() => _registrationFields
      .map(
        (field) => {
          'nama_field': field.isDefault ? 'Nama' : field.name.text.trim(),
          'tipe_field': field.isDefault ? 'Text' : field.type,
          'placeholder': field.placeholder.text.trim(),
          'opsi_field': field.type == 'Dropdown'
              ? field.optionsList
              : <String>[],
          'wajib': field.isDefault ? true : field.requiredField,
        },
      )
      .toList();

  Future<void> _submit() async {
    if (_submitting || !_validateStageOne() || !_validateStageTwo()) return;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Kirim pengajuan lomba?',
      message: 'Pastikan informasi, jadwal, biaya, dan formulir peserta sudah benar. Pengajuan akan diperiksa administrator.',
      confirmText: 'Kirim',
      cancelText: 'Batal',
    );
    if (!mounted || confirmed != true) return;
    setState(() => _submitting = true);
    try {
      final fee = _paymentType == 'Gratis'
          ? '0'
          : _feeController.text.replaceAll('.', '');
      final response = await ApiService.ajukanLomba(
        token: widget.token,
        idKategori: _categoryId!,
        namaLomba: _nameController.text,
        deskripsi: _descriptionController.text,
        tanggalMulaiPendaftaran: _date(_registrationStart),
        batasPendaftaran: _date(_registrationEnd),
        tanggalPelaksanaan: _date(_eventDate),
        tanggalSelesaiPelaksanaan: _date(_eventEndDate),
        metodePelaksanaan: _executionMethod,
        detailPelaksanaan: _executionDetailController.text,
        biaya: fee,
        kuotaPeserta: _quotaController.text,
        poster: _poster!,
        informasiTambahan: _infoPayload(),
        formFields: _formPayload(),
      );
      if (!mounted) return;
      await AppNotification.show(
        context: context,
        title: 'Berhasil!',
        message:
            response['pesan']?.toString() ??
            'Pengajuan berhasil dikirim dan menunggu verifikasi admin.',
        type: NotificationType.success,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _message('Pengajuan gagal: ${_cleanError(e)}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(label, style: TextStyle(color: _muted, fontSize: 12)),
          ),
          Text(': ', style: TextStyle(color: _muted, fontSize: 12)),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(
                color: _text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summarySection(String title, List<Widget> rows) {
    return _section(
      icon: Icons.fact_check_outlined,
      title: title,
      subtitle: 'Ringkasan informasi yang akan dikirim.',
      children: rows,
    );
  }

  Widget _stageThree() {
    final info = _infoPayload();

    return Column(
      children: [
        _summarySection('Informasi Umum Lomba', [
          _summaryRow('Nama lomba', _nameController.text),
          _summaryRow('Kategori', _selectedCategoryName()),
          _summaryRow('Deskripsi', _descriptionController.text),
          _summaryRow('Mulai pendaftaran', _date(_registrationStart)),
          _summaryRow('Batas pendaftaran', _date(_registrationEnd)),
          _summaryRow('Mulai pelaksanaan', _date(_eventDate)),
          _summaryRow('Selesai pelaksanaan', _date(_eventEndDate)),
          _summaryRow('Metode', _executionMethod),
          _summaryRow(
            _executionMethod == 'Online' ? 'Platform' : 'Tempat',
            _executionDetailController.text,
          ),
          _summaryRow(
            'Kuota peserta',
            _quotaController.text.isEmpty
                ? 'Tidak dibatasi'
                : _quotaController.text,
          ),
          _summaryRow('Biaya pendaftaran', _feeSummary()),
        ]),
        if (_posterBytes != null)
          _section(
            icon: Icons.image_outlined,
            title: 'Poster Lomba',
            subtitle: 'Poster yang akan disertakan.',
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.memory(
                  _posterBytes!,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 8),
              _summaryRow('Nama file', _poster?.name ?? '-'),
            ],
          ),
        if (info.isNotEmpty)
          _section(
            icon: Icons.list_alt_outlined,
            title: 'Informasi Tambahan',
            subtitle:
                'Semua informasi tambahan ditampilkan dalam satu kelompok.',
            children: [
              for (final row in info)
                _summaryRow(
                  row['label_informasi'].toString(),
                  row['nilai_informasi'].toString(),
                ),
            ],
          ),
        _section(
          icon: Icons.dynamic_form_rounded,
          title: 'Formulir Pendaftaran',
          subtitle:
              '${_registrationFields.length} field akan ditampilkan kepada peserta.',
          children: [
            for (var i = 0; i < _registrationFields.length; i++)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 9),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _creamLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${_registrationFields[i].isDefault ? 'Nama' : _registrationFields[i].name.text}',
                      style: TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tipe: ${_registrationFields[i].type} • ${_registrationFields[i].isDefault || _registrationFields[i].requiredField ? 'Wajib' : 'Opsional'}',
                      style: TextStyle(color: _muted, fontSize: 10),
                    ),
                    if (_registrationFields[i].type == 'Dropdown')
                      Text(
                        'Pilihan: ${_registrationFields[i].optionsList.join(', ')}',
                        style: TextStyle(color: _muted, fontSize: 10),
                      ),
                  ],
                ),
              ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: _primary),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Pastikan seluruh informasi sudah benar. Pengajuan baru dikirim ke administrator setelah tombol Kirim Pengajuan ditekan.',
                  style: TextStyle(color: _text, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepIndicator() {
    const labels = ['Informasi', 'Formulir', 'Ringkasan'];
    return Container(
      margin: EdgeInsets.only(bottom: 18),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        color: context.tl.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: List.generate(
          3,
          (index) => Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index <= _step ? _primary : _cream,
                          shape: BoxShape.circle,
                        ),
                        child: index < _step
                            ? Icon(Icons.check, color: Colors.white, size: 17)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: index == _step ? Colors.white : _muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: index == _step ? _primary : _muted,
                          fontSize: 10,
                          fontWeight: index == _step
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < 2)
                  Container(
                    width: 17,
                    height: 2,
                    margin: EdgeInsets.only(bottom: 19),
                    color: index < _step ? _primary : _border,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => TLPlayful.pageHeader(
    context,
    eyebrow: 'BUAT KOMPETISI / LANGKAH ${_step + 1} DARI 3',
    title: _step == 0
        ? 'Start with\nthe idea.'
        : _step == 1
        ? 'Define the\nentry form.'
        : 'Review.\nThen submit.',
    description: _step == 0
        ? 'Mulai dari informasi umum dan detail penyelenggaraan.'
        : _step == 1
        ? 'Tentukan data yang harus diisi oleh peserta.'
        : 'Periksa semuanya sekali lagi sebelum mengirim pengajuan.',
    icon: Icons.auto_awesome_rounded,
    accent: context.tl.orange,
    onBack: _previousStep,
  );

  Widget _navigation() {
    final disabled =
        _submitting || _loadingCategories || _categoryError != null;
    return Column(
      children: [
        Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: SizedBox(
                  height: 53,
                  child: OutlinedButton.icon(
                    onPressed: _submitting ? null : _previousStep,
                    icon: Icon(Icons.arrow_back, size: 18),
                    label: Text('Kembali'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: BorderSide(color: _primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
            ],
            Expanded(
              child: SizedBox(
                height: 53,
                child: ElevatedButton(
                  onPressed: disabled
                      ? null
                      : (_step == 2 ? _submit : _nextStep),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primary.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _submitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _step == 2
                                  ? Icons.send_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              _step == 2 ? 'Kirim Pengajuan' : 'Selanjutnya',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          _step == 2 ? 'Pengajuan dikirim setelah konfirmasi pada tahap ini.' : 'Data belum dikirim. Kamu masih dapat memeriksa dan mengubahnya.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        top: false,
        child: ListView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.zero,
          children: [
            _header(),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 22, 18, 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 2, bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 0
                              ? 'Informasi Umum'
                              : _step == 1
                              ? 'Formulir Peserta'
                              : 'Tinjau Pengajuan',
                          style: TextStyle(
                            color: _text,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _step == 0
                              ? 'Field utama sudah disediakan; informasi lainnya dapat ditambahkan.'
                              : _step == 1
                              ? 'Buat formulir pendaftaran yang fleksibel sesuai kebutuhan lomba.'
                              : 'Periksa kembali semua informasi sebelum mengirim.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _stepIndicator(),
                  if (_step == 0)
                    _stageOne()
                  else if (_step == 1)
                    _stageTwo()
                  else
                    _stageThree(),
                  SizedBox(height: 8),
                  _navigation(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoDraft {
  final TextEditingController label = TextEditingController();
  final TextEditingController value = TextEditingController();

  _InfoDraft();

  void dispose() {
    label.dispose();
    value.dispose();
  }
}

class _RegistrationFieldDraft {
  final TextEditingController name;
  final TextEditingController placeholder;
  final TextEditingController options;
  String type;
  bool requiredField;
  final bool isDefault;

  _RegistrationFieldDraft({
    String name = '',
    this.type = 'Text',
    String placeholder = '',
    String options = '',
    this.requiredField = true,
    this.isDefault = false,
  }) : name = TextEditingController(text: name),
       placeholder = TextEditingController(text: placeholder),
       options = TextEditingController(text: options);

  List<String> get optionsList => options.text
      .split(RegExp(r'[\n,]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();

  void dispose() {
    name.dispose();
    placeholder.dispose();
    options.dispose();
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return TextEditingValue(text: '');

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    final cursorDigitsBefore = newValue.text
        .substring(
          0,
          newValue.selection.end.clamp(0, newValue.text.length).toInt(),
        )
        .replaceAll(RegExp(r'\D'), '')
        .length;
    var cursor = 0;
    var counted = 0;
    while (cursor < formatted.length && counted < cursorDigitsBefore) {
      if (RegExp(r'\d').hasMatch(formatted[cursor])) counted++;
      cursor++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }
}