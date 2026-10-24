import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/api_service.dart';

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
  List<Map<String, dynamic>> _fields = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, XFile> _files = {};

  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadFormFields();
  }

  Future<void> _loadFormFields() async {
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
        if (field['tipe_field'] == 'Text') {
          final id = int.parse(field['id_field'].toString());
          _controllers[id] = TextEditingController();
        }
      }

      setState(() {
        _fields = fields;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pilihBerkas(int idField) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (files.isEmpty) return;

      final picked = files.single;
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDynamicField(Map<String, dynamic> field) {
    final id = int.parse(field['id_field'].toString());
    final nama = field['nama_field']?.toString() ?? 'Pertanyaan';
    final tipe = field['tipe_field']?.toString() ?? 'Text';
    final wajib =
        field['wajib'] == true || field['wajib'] == 1 || field['wajib'] == '1';

    if (tipe == 'File') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 17),
        child: FormField<XFile>(
          validator: (_) {
            if (wajib && !_files.containsKey(id)) {
              return '$nama wajib diunggah';
            }
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pilihBerkas(id),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_files[id]?.name ?? nama),
                ),
                if (state.hasError)
                  Text(
                    state.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            );
          },
        ),
      );
    }

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

  static const Color _primary = Color(0xFF3478E5);
  static const Color _primaryLight = Color(0xFFEAF2FF);
  static const Color _background = Color(0xFFF5F7FB);
  static const Color _text = Color(0xFF202938);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFE5EAF2);

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _teleponController = TextEditingController();
  final _asalController = TextEditingController();
  final _institusiController = TextEditingController();

  String _jenisPeserta = 'Mahasiswa';
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    _controllers.clear();
    _files.clear();

    _namaController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    _asalController.dispose();
    _institusiController.dispose();

    super.dispose();
  }

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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.words,
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

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 17,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['pesan']?.toString() ?? 'Pendaftaran berhasil dikirim.',
          ),
          backgroundColor: _primary,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pendaftaran: $e'),
          backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEAF2FF),
                    Color(0xFFD9E8FF),
                    Color(0xFFF5F7FB),
                  ],
                  stops: [0, 0.65, 1],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_back_rounded, color: _text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Formulir Pendaftaran',
                          style: TextStyle(
                            color: _text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Lengkapi data untuk mengikuti lomba',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // FORM
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: _primaryLight,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: _primary,
                              size: 21,
                            ),
                            SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                'Pastikan data yang Anda masukkan benar sebelum mengirim pendaftaran.',
                                style: TextStyle(
                                  color: _text,
                                  fontSize: 12,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(color: _primary),
                        )
                      else if (_loadError != null)
                        Column(
                          children: [
                            const Text('Gagal mengambil formulir.'),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _loadFormFields,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        )
                      else if (_fields.isEmpty)
                        const Text(
                          'Penyelenggara belum menyediakan pertanyaan pendaftaran.',
                        )
                      else
                        ..._fields.map(_buildDynamicField),

                      const SizedBox(height: 8),

                      // TOMBOL KIRIM
                      SizedBox(
                        width: double.infinity,
                        height: 53,
                        child: ElevatedButton(
                          onPressed:
                              _isSubmitting ||
                                  _isLoading ||
                                  _loadError != null ||
                                  _fields.isEmpty
                              ? null
                              : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _primary.withValues(
                              alpha: 0.6,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 21,
                                  height: 21,
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
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 9),
                                    Icon(Icons.arrow_forward_rounded, size: 19),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Center(
                        child: Text(
                          'Pastikan semua informasi telah sesuai.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
