import '../../design_system/tl_playful.dart';
import '../../widgets/app_feedback.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/api_service.dart';
import '../../config/appTheme.dart';

class FormulirPesertaPage extends StatefulWidget {
  final int idLomba;
  final String token;

  const FormulirPesertaPage({
    super.key,
    required this.idLomba,
    required this.token,
  });

  @override
  State<FormulirPesertaPage> createState() => _FormulirPesertaPageState();
}

class _FormulirPesertaPageState extends State<FormulirPesertaPage> {
  // DATA FORMULIR DINAMIS
  List<Map<String, dynamic>> _fields = [];

  final Map<int, TextEditingController> _controllers = {};
  final Map<int, XFile> _files = {};

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  // WARNA MENGAMBIL DARI APP THEME
  Color get _primary => context.tl.primary;
  Color get _cream => context.tl.cream;
  Color get _creamLight => context.tl.creamLight;
  Color get _creamDark => context.tl.creamDark;
  Color get _background => context.tl.background;
  Color get _surface => context.tl.surface;
  Color get _text => context.tl.navy;
  Color get _muted => context.tl.grey;
  Color get _border => context.tl.fieldBorder;
  Color get _fieldBg => context.tl.fieldBg;
  Color get _error => context.tl.error;

  @override
  void initState() {
    super.initState();
    _loadFormFields();
  }

  // =========================================================
  // MENGAMBIL FORMULIR DARI API
  // =========================================================

  Future<void> _loadFormFields() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final fields = await ApiService.getFormFields(widget.idLomba);

      if (!mounted) return;

      for (final controller in _controllers.values) {
        controller.dispose();
      }

      _controllers.clear();
      _files.clear();

      for (final field in fields) {
        final id = int.tryParse(field['id_field']?.toString() ?? '');

        if (id == null) {
          throw Exception('ID salah satu kolom formulir tidak valid.');
        }

        final type = (field['tipe_field']?.toString() ?? 'Text')
            .trim()
            .toLowerCase();

        const supported = {
          'text',
          'textarea',
          'number',
          'dropdown',
          'date',
          'file',
          'email',
          'phone',
        };
        if (!supported.contains(type)) {
          throw Exception('Tipe formulir "$type" belum didukung.');
        }
        if (type != 'file') {
          _controllers[id] = TextEditingController();
        }
      }

      setState(() {
        _fields = fields;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst(RegExp(r'^Exception: ?'), '');

      debugPrint(
        'Gagal mengambil formulir lomba '
        '${widget.idLomba}: $message',
      );

      setState(() {
        _loadError = message;
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // MEMILIH BERKAS
  // =========================================================

  Future<void> _pilihBerkas(int idField) async {
    try {
      // file_picker 12+ (termasuk 13.2.0) memakai API statis FilePicker.pickFile.
      // pickFile mengembalikan PlatformFile? secara langsung, bukan FilePickerResult.
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (picked == null) return;

      // Pada file_picker 13, bytes dibaca secara asynchronous melalui PlatformFile.
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Berkas tidak dapat dibaca. Silakan pilih ulang.');
      }
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Ukuran berkas maksimal 5 MB.');
      }

      final file = XFile.fromData(bytes, name: picked.name);
      if (!mounted) return;
      setState(() => _files[idField] = file);
      _formKey.currentState?.validate();
    } catch (e) {
      if (!mounted) return;
      AppNotification.message(
        context,
        'Gagal memilih berkas: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<void> _pickDateForField(int id, String label) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
      helpText: label,
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
    if (selected == null || !mounted) return;
    _controllers[id]?.text =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
    _formKey.currentState?.validate();
    setState(() {});
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    _controllers.clear();
    _files.clear();

    super.dispose();
  }

  // =========================================================
  // INPUT DECORATION
  // =========================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _muted, size: 20),
      filled: true,
      fillColor: _fieldBg,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      labelStyle: TextStyle(color: _muted, fontSize: 13),
      hintStyle: TextStyle(color: context.tl.muted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: _error, width: 1.5),
      ),
    );
  }

  // =========================================================
  // MEMBANGUN TEXT FIELD
  // =========================================================

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 19),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        onTap: onTap,
        textCapitalization: maxLines > 1
            ? TextCapitalization.sentences
            : TextCapitalization.words,
        style: TextStyle(
          color: _text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: _inputDecoration(label: label, hint: hint, icon: icon),
        validator: validator,
      ),
    );
  }

  // =========================================================
  // JUDUL BAGIAN
  // =========================================================

  Widget _sectionTitle(String title, String subtitle) {
    final p = context.tl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: p.mint.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(Icons.edit_note_rounded, color: p.mint, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(color: p.grey, fontSize: 12, height: 1.48),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FORMULIR DINAMIS
  // =========================================================

  Widget _buildDynamicField(Map<String, dynamic> field) {
    final id = int.parse(field['id_field'].toString());
    final nama = field['nama_field']?.toString() ?? 'Pertanyaan';
    final tipe = (field['tipe_field']?.toString() ?? 'Text')
        .trim()
        .toLowerCase();
    final placeholder =
        field['placeholder']?.toString().trim().isNotEmpty == true
        ? field['placeholder'].toString()
        : 'Masukkan $nama';
    final wajib =
        field['wajib'] == true || field['wajib'] == 1 || field['wajib'] == '1';
    final controller = _controllers[id];

    if (tipe == 'file') {
      return Padding(
        padding: EdgeInsets.only(bottom: 19),
        child: FormField<XFile>(
          validator: (_) =>
              wajib && !_files.containsKey(id) ? '$nama wajib diunggah' : null,
          builder: (state) {
            final selectedFile = _files[id];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wajib ? '$nama *' : nama,
                  style: TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 9),
                Material(
                  color: _creamLight,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _pilihBerkas(id),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: state.hasError ? _error : _creamDark,
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
                              selectedFile != null
                                  ? Icons.description_rounded
                                  : Icons.cloud_upload_outlined,
                              color: _primary,
                              size: 23,
                            ),
                          ),
                          SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedFile?.name ?? 'Pilih berkas',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'PDF, JPG, JPEG, PNG • Maks. 5 MB',
                                  style: TextStyle(color: _muted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            selectedFile != null
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            color: selectedFile != null
                                ? context.tl.green
                                : _primary,
                            size: 23,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.hasError) ...[
                  SizedBox(height: 6),
                  Text(
                    state.errorText!,
                    style: TextStyle(color: _error, fontSize: 11),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }

    if (tipe == 'dropdown') {
      final rawOptions = field['opsi_field'];
      final options = rawOptions is List
          ? rawOptions
                .map((value) => value.toString())
                .where((value) => value.trim().isNotEmpty)
                .toList()
          : <String>[];
      return Padding(
        padding: EdgeInsets.only(bottom: 19),
        child: DropdownButtonFormField<String>(
          initialValue: options.contains(controller?.text)
              ? controller!.text
              : null,
          isExpanded: true,
          decoration: _inputDecoration(
            label: wajib ? '$nama *' : nama,
            hint: placeholder,
            icon: Icons.list_alt_outlined,
          ),
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              controller?.text = value;
            }
          },
          validator: (value) => wajib && (value == null || value.isEmpty)
              ? '$nama wajib dipilih'
              : null,
        ),
      );
    }

    if (tipe == 'date') {
      return _buildField(
        label: wajib ? '$nama *' : nama,
        hint: placeholder,
        icon: Icons.calendar_month_outlined,
        controller: controller!,
        readOnly: true,
        onTap: () => _pickDateForField(id, nama),
        validator: (value) => wajib && (value == null || value.trim().isEmpty)
            ? '$nama wajib diisi'
            : null,
      );
    }

    TextInputType keyboard = TextInputType.text;
    int maxLines = 1;
    List<TextInputFormatter>? formatters;
    if (tipe == 'textarea') {
      maxLines = 4;
      keyboard = TextInputType.multiline;
    } else if (tipe == 'number') {
      keyboard = TextInputType.number;
      formatters = [_ThousandsSeparatorInputFormatter()];
    } else if (tipe == 'email') {
      keyboard = TextInputType.emailAddress;
    } else if (tipe == 'phone') {
      keyboard = TextInputType.phone;
      formatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]'))];
    }

    return _buildField(
      label: wajib ? '$nama *' : nama,
      hint: placeholder,
      icon: tipe == 'email'
          ? Icons.email_outlined
          : tipe == 'phone'
          ? Icons.phone_outlined
          : tipe == 'number'
          ? Icons.numbers_outlined
          : Icons.edit_outlined,
      controller: controller!,
      keyboardType: keyboard,
      maxLines: maxLines,
      inputFormatters: formatters,
      validator: (value) {
        if (wajib && (value == null || value.trim().isEmpty)) {
          return '$nama wajib diisi';
        }
        if (value == null || value.trim().isEmpty) return null;
        if (tipe == 'email' &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
          return 'Format email tidak valid';
        }
        if (tipe == 'number' &&
            !RegExp(r'^\d{1,3}(\.\d{3})*$|^\d+$').hasMatch(value.trim())) {
          return 'Masukkan angka saja';
        }
        if (tipe == 'phone' && value.replaceAll(RegExp(r'\D'), '').length < 6) {
          return 'Nomor telepon tidak valid';
        }
        return null;
      },
    );
  }

  // =========================================================
  // INFORMASI FORMULIR
  // =========================================================

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _creamLight,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _creamDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.info_outline_rounded, color: _primary, size: 21),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periksa data Anda',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Pastikan seluruh informasi yang Anda '
                  'masukkan sudah benar sebelum mengirim '
                  'pendaftaran. Kolom bertanda (*) wajib diisi.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 45),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: _primary),
            SizedBox(height: 15),
            Text(
              'Memuat formulir pendaftaran...',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _creamLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _creamDark),
      ),
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: _error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_off_rounded, color: _error, size: 26),
          ),
          SizedBox(height: 13),
          Text(
            'Formulir tidak dapat dimuat',
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _loadError ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          SizedBox(height: 17),
          OutlinedButton.icon(
            onPressed: _loadFormFields,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FORMULIR KOSONG
  // =========================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: _creamLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _creamDark),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, color: _primary, size: 42),
          SizedBox(height: 12),
          Text(
            'Formulir belum tersedia',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Penyelenggara belum menyediakan '
            'pertanyaan pendaftaran untuk lomba ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KIRIM PENDAFTARAN
  // =========================================================

  Future<void> _submitForm() async {
    if (_isSubmitting || _isLoading || _loadError != null || _fields.isEmpty) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Kirim pendaftaran?',
      message: 'Periksa kembali seluruh jawaban dan berkas. Pendaftaran akan dikirim kepada penyelenggara lomba.',
      confirmText: 'Daftar',
      cancelText: 'Batal',
    );
    if (!mounted || confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final jawaban = <int, String>{};

      for (final entry in _controllers.entries) {
        final value = entry.value.text.trim();

        if (value.isNotEmpty) {
          final field = _fields.firstWhere(
            (item) => int.tryParse(item['id_field'].toString()) == entry.key,
            orElse: () => <String, dynamic>{},
          );
          final type = (field['tipe_field']?.toString() ?? '').toLowerCase();
          jawaban[entry.key] = type == 'number'
              ? value.replaceAll('.', '')
              : value;
        }
      }

      final response = await ApiService.kirimPendaftaran(
        idLomba: widget.idLomba,
        token: widget.token,
        jawaban: jawaban,
        berkas: _files,
      );

      if (!mounted) return;

      await AppNotification.show(
        context: context,
        title: 'Berhasil!',
        message:
            response['pesan']?.toString() ?? 'Pendaftaran berhasil dikirim.',
        type: NotificationType.success,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppNotification.message(
        context,
        'Gagal mengirim pendaftaran: $e',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() => TLPlayful.pageHeader(
    context,
    title: 'Make your\nnext move.',
    description: 'Isi data dengan teliti. Fokus satu langkah sampai selesai.',
    icon: Icons.edit_note_rounded,
    accent: context.tl.mint,
    onBack: () => Navigator.of(context).pop(),
  );

  // =========================================================
  // TOMBOL KIRIM
  // =========================================================

  Widget _buildSubmitButton() {
    final disabled =
        _isSubmitting || _isLoading || _loadError != null || _fields.isEmpty;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: disabled ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withValues(alpha: 0.35),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Kirim Pendaftaran',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 9),
                  Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              _buildHeader(),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 23, 20, 35),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INFORMASI
                      _buildInfoCard(),
                      SizedBox(height: 27),

                      // JUDUL FORMULIR
                      _sectionTitle(
                        'Data Pendaftaran',
                        'Isi informasi sesuai dengan ketentuan '
                            'yang diminta oleh penyelenggara lomba.',
                      ),

                      // KONTEN FORMULIR
                      if (_isLoading)
                        _buildLoading()
                      else if (_loadError != null)
                        _buildError()
                      else if (_fields.isEmpty)
                        _buildEmpty()
                      else
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.035),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 37,
                                    height: 37,
                                    decoration: BoxDecoration(
                                      color: _cream,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      Icons.assignment_outlined,
                                      color: _primary,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 11),
                                  Expanded(
                                    child: Text(
                                      'Pertanyaan Lomba',
                                      style: TextStyle(
                                        color: _text,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _creamLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_fields.length} kolom',
                                      style: TextStyle(
                                        color: _primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Divider(color: _border, height: 1),
                              SizedBox(height: 20),
                              ..._fields.map(_buildDynamicField),
                            ],
                          ),
                        ),
                      SizedBox(height: 25),

                      // TOMBOL KIRIM
                      _buildSubmitButton(),
                      SizedBox(height: 15),
                      Center(
                        child: Text(
                          'Pastikan semua informasi telah sesuai.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
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
    final text = buffer.toString();
    final before = newValue.text
        .substring(
          0,
          newValue.selection.end.clamp(0, newValue.text.length).toInt(),
        )
        .replaceAll(RegExp(r'\D'), '')
        .length;
    var cursor = 0;
    var counted = 0;
    while (cursor < text.length && counted < before) {
      if (RegExp(r'\d').hasMatch(text[cursor])) counted++;
      cursor++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }
}