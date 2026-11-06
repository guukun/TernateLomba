import 'dart:typed_data';

import '../../config/appTheme.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';

class FormAjukanLombaPage extends StatefulWidget {
  final String token;

  const FormAjukanLombaPage({super.key, required this.token});

  @override
  State<FormAjukanLombaPage> createState() => _FormAjukanLombaPageState();
}

class _FormAjukanLombaPageState extends State<FormAjukanLombaPage> {
  // Seluruh warna mengambil dari AppTheme.
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

  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _persyaratanController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _biayaController = TextEditingController(text: '0');
  final _hadiahController = TextEditingController();
  final _kuotaController = TextEditingController();
  final _kontakController = TextEditingController();

  final _imagePicker = ImagePicker();

  // Field yang harus diisi peserta.
  final List<Map<String, dynamic>> _formFields = [
    {
      'nama_field': 'Asal sekolah / instansi',
      'tipe_field': 'Text',
      'wajib': true,
    },
  ];

  List<Map<String, dynamic>> _kategori = [];

  int? _idKategori;

  DateTime? _tanggalPelaksanaan;
  DateTime? _batasPendaftaran;

  XFile? _poster;
  Uint8List? _posterPreviewBytes;

  bool _loadingKategori = true;
  bool _mengirim = false;

  String? _errorKategori;

  @override
  void initState() {
    super.initState();
    _muatKategori();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _persyaratanController.dispose();
    _lokasiController.dispose();
    _biayaController.dispose();
    _hadiahController.dispose();
    _kuotaController.dispose();
    _kontakController.dispose();

    super.dispose();
  }

  // ==========================================
  // MEMUAT KATEGORI
  // ==========================================

  Future<void> _muatKategori() async {
    setState(() {
      _loadingKategori = true;
      _errorKategori = null;
    });

    try {
      final items = await ApiService.getKategori();

      if (!mounted) return;

      setState(() {
        _kategori = items;
        _loadingKategori = false;

        if (_kategori.isNotEmpty) {
          _idKategori = int.tryParse(_kategori.first['id_kategori'].toString());
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingKategori = false;
        _errorKategori = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==========================================
  // FORMAT TANGGAL
  // ==========================================

  String _formatTanggal(DateTime? date) {
    if (date == null) return 'Pilih tanggal';

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pilihTanggal({required bool tanggalPelaksanaan}) async {
    final now = DateTime.now();

    final current = tanggalPelaksanaan
        ? _tanggalPelaksanaan
        : _batasPendaftaran;

    final today = DateTime(now.year, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isBefore(today)
          ? current
          : today,
      firstDate: today,
      lastDate: DateTime(now.year + 10),
      helpText: tanggalPelaksanaan
          ? 'Tanggal pelaksanaan lomba'
          : 'Batas pendaftaran',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: _creamLight,
              onSurface: _text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    setState(() {
      if (tanggalPelaksanaan) {
        _tanggalPelaksanaan = date;
      } else {
        _batasPendaftaran = date;
      }
    });
  }

  // ==========================================
  // PILIH POSTER
  // ==========================================

  Future<void> _pilihPoster() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      final extension = image.name.split('.').last.toLowerCase();

      if (!{'jpg', 'jpeg', 'png'}.contains(extension)) {
        _pesan('Poster harus berformat JPG, JPEG, atau PNG.');
        return;
      }

      final bytes = await image.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        _pesan('Ukuran poster maksimal 5 MB.');
        return;
      }

      setState(() {
        _poster = image;
        _posterPreviewBytes = bytes;
      });
    } catch (e) {
      _pesan('Gagal memilih poster: $e');
    }
  }

  // ==========================================
  // SNACKBAR
  // ==========================================

  void _pesan(String message, {bool sukses = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: sukses ? AppColors.green : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ==========================================
  // VALIDASI
  // ==========================================

  String? _wajib(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi.';
    }

    return null;
  }

  // ==========================================
  // DEKORASI INPUT
  // ==========================================

  InputDecoration _dekorasi(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: _primary, size: 20),
      filled: true,
      fillColor: _creamLight,
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
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  // ==========================================
  // KOMPONEN INPUT TEKS
  // ==========================================

  Widget _teks({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: maxLines > 1
            ? TextCapitalization.sentences
            : TextCapitalization.words,
        decoration: _dekorasi(label, hint: hint),
        validator: validator,
        style: const TextStyle(
          color: _text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ==========================================
  // KOMPONEN TANGGAL
  // ==========================================

  Widget _tanggal({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _mengirim ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: InputDecorator(
          decoration: _dekorasi(label, icon: Icons.calendar_month_rounded),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatTanggal(value),
                  style: TextStyle(
                    color: value == null ? _muted : _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // KOMPONEN JUDUL SECTION
  // ==========================================

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _primary, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // KARTU SECTION
  // ==========================================

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _primaryDeepShadow,
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(icon: icon, title: title, subtitle: subtitle),
          ...children,
        ],
      ),
    );
  }

  static const Color _primaryDeepShadow = Color(0x120D3262);

  // ==========================================
  // FORMULIR PENDAFTARAN PESERTA
  // ==========================================

  Widget _pembuatFormulir() {
    return _sectionCard(
      icon: Icons.dynamic_form_rounded,
      title: 'Formulir Pendaftaran',
      subtitle: 'Atur informasi yang harus diisi peserta.',
      children: [
        const Text(
          'Field Pendaftaran Peserta',
          style: TextStyle(
            color: _text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Peserta akan mengisi informasi berikut ketika mendaftar.',
          style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 16),

        for (var index = 0; index < _formFields.length; index++)
          Container(
            key: ObjectKey(_formFields[index]),
            margin: const EdgeInsets.only(bottom: 13),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _creamLight,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                TextFormField(
                  initialValue: _formFields[index]['nama_field'].toString(),
                  maxLength: 150,
                  decoration: _dekorasi(
                    'Nama field',
                    hint: 'Contoh: Nama peserta',
                  ),
                  onChanged: (value) {
                    _formFields[index]['nama_field'] = value;
                  },
                  validator: (value) => _wajib(value, 'Nama field'),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: _formFields[index]['tipe_field'] as String,
                  decoration: _dekorasi('Tipe input'),
                  items: const [
                    DropdownMenuItem(value: 'Text', child: Text('Teks')),
                    DropdownMenuItem(value: 'File', child: Text('Unggah file')),
                  ],
                  onChanged: _mengirim
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _formFields[index]['tipe_field'] = value;
                            });
                          }
                        },
                ),

                const SizedBox(height: 5),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: _primary,
                  activeTrackColor: _creamDark,
                  title: const Text(
                    'Wajib diisi peserta',
                    style: TextStyle(
                      color: _text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _formFields[index]['wajib'] == true,
                  onChanged: _mengirim
                      ? null
                      : (value) {
                          setState(() {
                            _formFields[index]['wajib'] = value;
                          });
                        },
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _mengirim
                        ? null
                        : () {
                            setState(() {
                              _formFields.removeAt(index);
                            });
                          },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Hapus field'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        OutlinedButton.icon(
          onPressed: _mengirim || _formFields.length >= 30
              ? null
              : () {
                  setState(() {
                    _formFields.add({
                      'nama_field': '',
                      'tipe_field': 'Text',
                      'wajib': true,
                    });
                  });
                },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah field pendaftaran'),
        ),
      ],
    );
  }

  // ==========================================
  // KATEGORI LOMBA
  // ==========================================

  Widget _kategoriInput() {
    if (_loadingKategori) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (_errorKategori != null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _errorKategori!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
            TextButton.icon(
              onPressed: _muatKategori,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat ulang kategori'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _idKategori,
      isExpanded: true,
      decoration: _dekorasi('Kategori lomba', icon: Icons.category_outlined),
      items: _kategori
          .map((item) {
            final id = int.tryParse(item['id_kategori'].toString());

            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                item['nama_kategori']?.toString() ?? 'Kategori',
                overflow: TextOverflow.ellipsis,
              ),
            );
          })
          .where((item) => item.value != null)
          .toList(),
      onChanged: _mengirim
          ? null
          : (value) {
              setState(() {
                _idKategori = value;
              });
            },
      validator: (value) {
        if (value == null) {
          return 'Kategori wajib dipilih.';
        }
        return null;
      },
    );
  }

  // ==========================================
  // UPLOAD POSTER
  // ==========================================

  Widget _posterSection() {
    return _sectionCard(
      icon: Icons.image_outlined,
      title: 'Poster Lomba',
      subtitle: 'Unggah poster untuk memberikan informasi visual.',
      children: [
        InkWell(
          onTap: _mengirim ? null : _pilihPoster,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _creamLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _poster == null ? _creamDark : _primary,
                width: 1.4,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Icon(
                    _poster == null
                        ? Icons.cloud_upload_outlined
                        : Icons.check_circle_outline_rounded,
                    color: _primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  _poster == null
                      ? 'Pilih Poster Lomba'
                      : 'Poster Berhasil Dipilih',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _poster?.name ?? 'Ketuk untuk memilih gambar dari galeri',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'JPG / JPEG / PNG • Maksimal 5 MB',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_posterPreviewBytes != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: double.infinity,
              height: 210,
              color: _cream,
              child: Image.memory(
                _posterPreviewBytes!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: _muted,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _mengirim
                ? null
                : () {
                    setState(() {
                      _poster = null;
                      _posterPreviewBytes = null;
                    });
                  },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            label: const Text(
              'Hapus poster',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // PROSES PENGAJUAN
  // ==========================================

  Future<void> _kirim() async {
    FocusScope.of(context).unfocus();

    if (_mengirim) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_idKategori == null) {
      _pesan('Pilih kategori lomba terlebih dahulu.');
      return;
    }

    if (_tanggalPelaksanaan == null || _batasPendaftaran == null) {
      _pesan('Tanggal pelaksanaan dan batas pendaftaran wajib dipilih.');
      return;
    }

    if (_poster == null || _posterPreviewBytes == null) {
      _pesan('Poster lomba wajib diunggah.');
      return;
    }

    final pelaksanaan = DateTime(
      _tanggalPelaksanaan!.year,
      _tanggalPelaksanaan!.month,
      _tanggalPelaksanaan!.day,
    );

    final batas = DateTime(
      _batasPendaftaran!.year,
      _batasPendaftaran!.month,
      _batasPendaftaran!.day,
    );

    if (batas.isAfter(pelaksanaan)) {
      _pesan('Batas pendaftaran tidak boleh setelah tanggal pelaksanaan.');
      return;
    }

    final biaya = _biayaController.text.trim().isEmpty
        ? '0'
        : _biayaController.text.trim();

    final parsedBiaya = num.tryParse(biaya);

    if (parsedBiaya == null || parsedBiaya < 0) {
      _pesan('Biaya harus berupa angka nol atau lebih.');
      return;
    }

    final kuota = _kuotaController.text.trim();

    if (kuota.isNotEmpty &&
        (int.tryParse(kuota) == null || int.parse(kuota) < 1)) {
      _pesan('Kuota harus berupa bilangan bulat minimal 1.');
      return;
    }

    if (_formFields.isEmpty) {
      _pesan('Tambahkan minimal satu field pendaftaran peserta.');
      return;
    }

    for (final field in _formFields) {
      if (field['nama_field'].toString().trim().isEmpty) {
        _pesan('Nama field pendaftaran tidak boleh kosong.');
        return;
      }
    }

    setState(() {
      _mengirim = true;
    });

    try {
      final response = await ApiService.ajukanLomba(
        token: widget.token,
        idKategori: _idKategori!,
        namaLomba: _namaController.text,
        deskripsi: _deskripsiController.text,
        persyaratan: _persyaratanController.text,
        tanggalPelaksanaan: _formatTanggal(_tanggalPelaksanaan),
        batasPendaftaran: _formatTanggal(_batasPendaftaran),
        lokasiPendaftaran: _lokasiController.text,
        biaya: parsedBiaya.toString(),
        hadiah: _hadiahController.text,
        kuotaPeserta: kuota,
        kontakPenyelenggara: _kontakController.text,
        poster: _poster!,
        formFields: _formFields,
      );

      if (!mounted) return;

      _pesan(
        response['pesan']?.toString() ??
            'Pengajuan lomba berhasil dikirim dan menunggu verifikasi admin.',
        sukses: true,
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      _pesan(
        'Pengajuan gagal: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _mengirim = false;
        });
      }
    }
  }

  // ==========================================
  // HEADER HALAMAN
  // ==========================================

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
      decoration: const BoxDecoration(
        color: _primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              const Text(
                'TERNATELOMBA',
                style: TextStyle(
                  color: _cream,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: _cream, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'Penyelenggara',
                      style: TextStyle(
                        color: _cream,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            'Publikasikan\nLomba Kamu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Lengkapi informasi lomba dan ajukan kepada admin untuk proses verifikasi.',
            style: TextStyle(
              color: Color(0xFFD9E3EF),
              fontSize: 13,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 21),

          Container(
            width: 58,
            height: 4,
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // INFORMASI LOMBA
  // ==========================================

  Widget _informasiLomba() {
    return _sectionCard(
      icon: Icons.emoji_events_outlined,
      title: 'Informasi Lomba',
      subtitle: 'Masukkan informasi dasar mengenai kompetisi.',
      children: [
        _kategoriInput(),

        const SizedBox(height: 16),

        _teks(
          label: 'Nama lomba *',
          controller: _namaController,
          hint: 'Contoh: Lomba Karya Tulis Ilmiah',
          validator: (value) => _wajib(value, 'Nama lomba'),
        ),

        _teks(
          label: 'Deskripsi lomba *',
          controller: _deskripsiController,
          maxLines: 4,
          hint: 'Jelaskan tujuan dan gambaran umum lomba.',
          validator: (value) => _wajib(value, 'Deskripsi lomba'),
        ),

        _teks(
          label: 'Persyaratan peserta',
          controller: _persyaratanController,
          maxLines: 3,
          hint: 'Tuliskan persyaratan peserta (opsional).',
        ),
      ],
    );
  }

  // ==========================================
  // JADWAL DAN LOKASI
  // ==========================================

  Widget _jadwalLomba() {
    return _sectionCard(
      icon: Icons.calendar_month_rounded,
      title: 'Jadwal & Lokasi',
      subtitle: 'Tentukan waktu dan metode pelaksanaan lomba.',
      children: [
        _tanggal(
          label: 'Tanggal pelaksanaan *',
          value: _tanggalPelaksanaan,
          onTap: () {
            _pilihTanggal(tanggalPelaksanaan: true);
          },
        ),

        _tanggal(
          label: 'Batas pendaftaran *',
          value: _batasPendaftaran,
          onTap: () {
            _pilihTanggal(tanggalPelaksanaan: false);
          },
        ),

        _teks(
          label: 'Lokasi / metode pendaftaran *',
          controller: _lokasiController,
          hint: 'Contoh: Online atau Aula Kampus',
          validator: (value) => _wajib(value, 'Lokasi / metode pendaftaran'),
        ),
      ],
    );
  }

  // ==========================================
  // BIAYA DAN HADIAH
  // ==========================================

  Widget _biayaHadiah() {
    return _sectionCard(
      icon: Icons.card_giftcard_rounded,
      title: 'Biaya & Hadiah',
      subtitle: 'Informasikan biaya pendaftaran dan penghargaan.',
      children: [
        _teks(
          label: 'Biaya pendaftaran (Rp)',
          controller: _biayaController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          hint: 'Masukkan 0 jika gratis.',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null;
            }

            final number = num.tryParse(value.trim());

            if (number == null || number < 0) {
              return 'Masukkan biaya berupa angka nol atau lebih.';
            }

            return null;
          },
        ),

        _teks(
          label: 'Hadiah',
          controller: _hadiahController,
          maxLines: 2,
          hint: 'Contoh: Uang tunai, trofi, sertifikat.',
        ),

        _teks(
          label: 'Kuota peserta',
          controller: _kuotaController,
          keyboardType: TextInputType.number,
          hint: 'Kosongkan jika tidak dibatasi.',
        ),
      ],
    );
  }

  // ==========================================
  // KONTAK PENYELENGGARA
  // ==========================================

  Widget _kontakPenyelenggara() {
    return _sectionCard(
      icon: Icons.support_agent_rounded,
      title: 'Kontak Penyelenggara',
      subtitle: 'Berikan informasi yang dapat dihubungi peserta.',
      children: [
        _teks(
          label: 'Kontak penyelenggara *',
          controller: _kontakController,
          hint: 'Nomor telepon, email, atau nama instansi.',
          validator: (value) => _wajib(value, 'Kontak penyelenggara'),
        ),
      ],
    );
  }

  // ==========================================
  // TOMBOL KIRIM
  // ==========================================

  Widget _tombolKirim() {
    final disabled = _mengirim || _loadingKategori || _errorKategori != null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: disabled ? null : _kirim,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primary.withValues(alpha: 0.45),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: _mengirim
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Mengirim pengajuan...',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 19),
                      SizedBox(width: 10),
                      Text(
                        'Kirim Pengajuan Lomba',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 15),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 15, color: _muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Pengajuan akan diverifikasi oleh admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // BUILD UTAMA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _header(),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 23, 18, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 3, bottom: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lengkapi Data Lomba',
                            style: TextStyle(
                              color: _text,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Pastikan seluruh informasi sudah benar sebelum dikirim.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _informasiLomba(),

                    _jadwalLomba(),

                    _biayaHadiah(),

                    _kontakPenyelenggara(),

                    _posterSection(),

                    _pembuatFormulir(),

                    _tombolKirim(),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
