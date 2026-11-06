import 'package:flutter/material.dart';
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
  static const Color _primary = AppColors.primary;
  static const Color _primaryDark = AppColors.primaryDark;
  static const Color _cream = AppColors.cream;
  static const Color _creamLight = AppColors.creamLight;
  static const Color _creamDark = AppColors.creamDark;
  static const Color _background = AppColors.background;
  static const Color _surface = AppColors.surface;
  static const Color _text = AppColors.navy;
  static const Color _muted = AppColors.grey;
  static const Color _border = AppColors.fieldBorder;
  static const Color _fieldBg = AppColors.fieldBg;
  static const Color _error = AppColors.error;

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

        final type = (field['tipe_field']?.toString() ?? '')
            .trim()
            .toLowerCase();

        if (type == 'text') {
          _controllers[id] = TextEditingController();
        } else if (type != 'file') {
          throw Exception(
            'Tipe formulir "$type" belum didukung. '
            'Gunakan tipe Text atau File pada database.',
          );
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
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Ukuran berkas maksimal 5 MB.');
      }

      final file = XFile.fromData(bytes, name: picked.name);

      if (!mounted) return;

      setState(() {
        _files[idField] = file;
      });

      _formKey.currentState?.validate();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih berkas: $e'),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),

      labelStyle: const TextStyle(color: _muted, fontSize: 13),

      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _border),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _border),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _error),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _error, width: 1.5),
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
          color: _text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: _inputDecoration(label: label, hint: hint, icon: icon),
        validator:
            validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label wajib diisi';
              }
              return null;
            },
      ),
    );
  }

  // =========================================================
  // JUDUL BAGIAN
  // =========================================================

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
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

    final wajib =
        field['wajib'] == true || field['wajib'] == 1 || field['wajib'] == '1';

    // FIELD BERUPA FILE
    if (tipe == 'file') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 19),
        child: FormField<XFile>(
          validator: (_) {
            if (wajib && !_files.containsKey(id)) {
              return '$nama wajib diunggah';
            }
            return null;
          },
          builder: (state) {
            final selectedFile = _files[id];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wajib ? '$nama *' : nama,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 9),

                Material(
                  color: _creamLight,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _pilihBerkas(id),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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

                          const SizedBox(width: 13),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedFile?.name ?? 'Pilih berkas',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                const Text(
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
                                ? AppColors.green
                                : _primary,
                            size: 23,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (state.hasError) ...[
                  const SizedBox(height: 6),
                  Text(
                    state.errorText!,
                    style: const TextStyle(color: _error, fontSize: 11),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }

    // FIELD BERUPA TEXT
    return _buildField(
      label: wajib ? '$nama *' : nama,
      hint: 'Masukkan $nama',
      icon: Icons.edit_outlined,
      controller: _controllers[id]!,
      validator: (value) {
        if (wajib && (value == null || value.trim().isEmpty)) {
          return '$nama wajib diisi';
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
      padding: const EdgeInsets.all(16),
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
            child: const Icon(
              Icons.info_outline_rounded,
              color: _primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
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
    return const Padding(
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
      padding: const EdgeInsets.all(20),
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
            child: const Icon(Icons.cloud_off_rounded, color: _error, size: 26),
          ),

          const SizedBox(height: 13),

          const Text(
            'Formulir tidak dapat dimuat',
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _loadError ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),

          const SizedBox(height: 17),

          OutlinedButton.icon(
            onPressed: _loadFormFields,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
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
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: _creamLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _creamDark),
      ),
      child: const Column(
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final jawaban = <int, String>{};

      for (final entry in _controllers.entries) {
        final value = entry.value.text.trim();

        if (value.isNotEmpty) {
          jawaban[entry.key] = value;
        }
      }

      final response = await ApiService.kirimPendaftaran(
        idLomba: widget.idLomba,
        token: widget.token,
        jawaban: jawaban,
        berkas: _files,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              response['pesan']?.toString() ?? 'Pendaftaran berhasil dikirim.',
            ),
            backgroundColor: _primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pendaftaran: $e'),
            backgroundColor: _error,
            behavior: SnackBarBehavior.floating,
          ),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 27),
      decoration: const BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(13),
                  child: const SizedBox(
                    width: 43,
                    height: 43,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Text(
                  'Pendaftaran Lomba',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            'Formulir Peserta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Lengkapi informasi yang diperlukan '
            'untuk mengikuti kompetisi.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: 65,
            height: 5,
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

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
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
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
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              _buildHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 23, 20, 35),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INFORMASI
                      _buildInfoCard(),

                      const SizedBox(height: 27),

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
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.035),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
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
                                    child: const Icon(
                                      Icons.assignment_outlined,
                                      color: _primary,
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(width: 11),

                                  const Expanded(
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _creamLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_fields.length} kolom',
                                      style: const TextStyle(
                                        color: _primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              const Divider(color: _border, height: 1),

                              const SizedBox(height: 20),

                              ..._fields.map(_buildDynamicField),
                            ],
                          ),
                        ),

                      const SizedBox(height: 25),

                      // TOMBOL KIRIM
                      _buildSubmitButton(),

                      const SizedBox(height: 15),

                      const Center(
                        child: Text(
                          'Pastikan semua informasi telah sesuai.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ),

                      const SizedBox(height: 10),
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