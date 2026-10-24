import 'package:flutter/material.dart';

class FormulirPesertaPage extends StatefulWidget {
  const FormulirPesertaPage({super.key});

  @override
  State<FormulirPesertaPage> createState() => _FormulirPesertaPageState();
}

class _FormulirPesertaPageState extends State<FormulirPesertaPage> {
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

  void _submitForm() {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Belum terhubung ke API Laravel.
    // Jangan menampilkan pendaftaran berhasil sebelum
    // data benar-benar tersimpan di server.

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Formulir valid. Pengiriman pendaftaran ke server belum diaktifkan.',
          ),
          backgroundColor: _primary,
        ),
      );
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

                      _sectionTitle(
                        'Data Peserta',
                        'Masukkan identitas peserta lomba.',
                      ),

                      _buildField(
                        label: 'Nama Lengkap',
                        hint: 'Masukkan nama lengkap',
                        icon: Icons.person_outline_rounded,
                        controller: _namaController,
                      ),

                      _buildField(
                        label: 'Email',
                        hint: 'nama@email.com',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email wajib diisi';
                          }

                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value.trim())) {
                            return 'Masukkan alamat email yang valid';
                          }

                          return null;
                        },
                      ),

                      _buildField(
                        label: 'Nomor Telepon',
                        hint: 'Contoh: 081234567890',
                        icon: Icons.phone_outlined,
                        controller: _teleponController,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 7),

                      _sectionTitle(
                        'Informasi Pendidikan',
                        'Isi informasi asal peserta.',
                      ),

                      Container(
                        margin: const EdgeInsets.only(bottom: 17),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _jenisPeserta,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Peserta',
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.school_outlined,
                              color: _muted,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Pelajar',
                              child: Text('Pelajar'),
                            ),
                            DropdownMenuItem(
                              value: 'Mahasiswa',
                              child: Text('Mahasiswa'),
                            ),
                            DropdownMenuItem(
                              value: 'Umum',
                              child: Text('Umum'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _jenisPeserta = value;
                              });
                            }
                          },
                        ),
                      ),

                      _buildField(
                        label: 'Asal Kota/Kabupaten',
                        hint: 'Contoh: Kota Ternate',
                        icon: Icons.location_on_outlined,
                        controller: _asalController,
                      ),

                      _buildField(
                        label: 'Sekolah/Universitas/Instansi',
                        hint: 'Masukkan nama institusi',
                        icon: Icons.account_balance_outlined,
                        controller: _institusiController,
                      ),

                      const SizedBox(height: 8),

                      // TOMBOL KIRIM
                      SizedBox(
                        width: double.infinity,
                        height: 53,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
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