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
  static const Color _primary = Color(0xFF3478E5);
  static const Color _background = Color(0xFFF5F7FB);
  static const Color _text = Color(0xFF202938);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFE5EAF2);

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

  List<Map<String, dynamic>> _kategori = [];
  int? _idKategori;
  DateTime? _tanggalPelaksanaan;
  DateTime? _batasPendaftaran;
  XFile? _poster;
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

  String _formatTanggal(DateTime? date) {
    if (date == null) return 'Pilih tanggal';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pilihTanggal({required bool tanggalPelaksanaan}) async {
    final now = DateTime.now();
    final current = tanggalPelaksanaan ? _tanggalPelaksanaan : _batasPendaftaran;
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
      helpText: tanggalPelaksanaan ? 'Tanggal pelaksanaan lomba' : 'Batas pendaftaran',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
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
      setState(() => _poster = image);
    } catch (e) {
      _pesan('Gagal memilih poster: $e');
    }
  }

  void _pesan(String message, {bool sukses = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: sukses ? Colors.green.shade700 : Colors.red.shade700,
      ));
  }

  String? _wajib(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi.';
    return null;
  }

  InputDecoration _dekorasi(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: _muted, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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
    );
  }

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
        textCapitalization: maxLines > 1 ? TextCapitalization.sentences : TextCapitalization.words,
        decoration: _dekorasi(label, hint: hint),
        validator: validator,
      ),
    );
  }

  Widget _tanggal({required String label, required DateTime? value, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _mengirim ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: _dekorasi(label, icon: Icons.calendar_month_outlined),
          child: Text(
            _formatTanggal(value),
            style: TextStyle(color: value == null ? _muted : _text, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Future<void> _kirim() async {
    FocusScope.of(context).unfocus();
    if (_mengirim) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_idKategori == null) {
      _pesan('Pilih kategori lomba terlebih dahulu.');
      return;
    }
    if (_tanggalPelaksanaan == null || _batasPendaftaran == null) {
      _pesan('Tanggal pelaksanaan dan batas pendaftaran wajib dipilih.');
      return;
    }
    final pelaksanaan = DateTime(_tanggalPelaksanaan!.year, _tanggalPelaksanaan!.month, _tanggalPelaksanaan!.day);
    final batas = DateTime(_batasPendaftaran!.year, _batasPendaftaran!.month, _batasPendaftaran!.day);
    if (batas.isAfter(pelaksanaan)) {
      _pesan('Batas pendaftaran tidak boleh setelah tanggal pelaksanaan.');
      return;
    }

    final biaya = _biayaController.text.trim().isEmpty ? '0' : _biayaController.text.trim();
    final parsedBiaya = num.tryParse(biaya);
    if (parsedBiaya == null || parsedBiaya < 0) {
      _pesan('Biaya harus berupa angka nol atau lebih.');
      return;
    }
    final kuota = _kuotaController.text.trim();
    if (kuota.isNotEmpty && (int.tryParse(kuota) == null || int.parse(kuota) < 1)) {
      _pesan('Kuota harus berupa bilangan bulat minimal 1.');
      return;
    }

    setState(() => _mengirim = true);
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
        poster: _poster,
      );
      if (!mounted) return;
      _pesan(
        response['pesan']?.toString() ?? 'Pengajuan lomba berhasil dikirim dan menunggu verifikasi admin.',
        sukses: true,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _pesan('Pengajuan gagal: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Form Pengajuan Lomba'),
        backgroundColor: const Color(0xFFEAF2FF),
        foregroundColor: _text,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              const Text(
                'Informasi lomba',
                style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lengkapi data berikut. Pengajuan akan ditinjau admin sebelum ditampilkan.',
                style: TextStyle(color: _muted, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (_loadingKategori)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ))
              else if (_errorKategori != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_errorKategori!, style: TextStyle(color: Colors.red.shade800)),
                      TextButton.icon(
                        onPressed: _muatKategori,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muat ulang kategori'),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<int>(
                    value: _idKategori,
                    isExpanded: true,
                    decoration: _dekorasi('Kategori lomba'),
                    items: _kategori.map((item) {
                      final id = int.tryParse(item['id_kategori'].toString());
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(item['nama_kategori']?.toString() ?? 'Kategori'),
                      );
                    }).where((item) => item.value != null).toList(),
                    onChanged: _mengirim ? null : (value) => setState(() => _idKategori = value),
                    validator: (value) => value == null ? 'Kategori wajib dipilih.' : null,
                  ),
                ),
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
                validator: (value) => _wajib(value, 'Deskripsi lomba'),
              ),
              _teks(
                label: 'Persyaratan peserta',
                controller: _persyaratanController,
                maxLines: 3,
                hint: 'Tuliskan syarat peserta (opsional)',
              ),
              _tanggal(
                label: 'Tanggal pelaksanaan *',
                value: _tanggalPelaksanaan,
                onTap: () => _pilihTanggal(tanggalPelaksanaan: true),
              ),
              _tanggal(
                label: 'Batas pendaftaran *',
                value: _batasPendaftaran,
                onTap: () => _pilihTanggal(tanggalPelaksanaan: false),
              ),
              _teks(
                label: 'Lokasi / metode pendaftaran *',
                controller: _lokasiController,
                hint: 'Contoh: Online atau Aula Kampus',
                validator: (value) => _wajib(value, 'Lokasi / metode pendaftaran'),
              ),
              _teks(
                label: 'Biaya pendaftaran (Rp)',
                controller: _biayaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final number = num.tryParse(value.trim());
                  if (number == null || number < 0) return 'Masukkan biaya berupa angka nol atau lebih.';
                  return null;
                },
              ),
              _teks(label: 'Hadiah', controller: _hadiahController, maxLines: 2),
              _teks(
                label: 'Kuota peserta',
                controller: _kuotaController,
                keyboardType: TextInputType.number,
                hint: 'Kosongkan jika tidak dibatasi',
              ),
              _teks(
                label: 'Kontak penyelenggara *',
                controller: _kontakController,
                hint: 'Nomor telepon, email, atau nama instansi',
                validator: (value) => _wajib(value, 'Kontak penyelenggara'),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, color: _primary, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _poster?.name ?? 'Poster lomba (opsional, JPG/PNG, maks. 5 MB)',
                        style: const TextStyle(color: _text, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pilih poster',
                      onPressed: _mengirim ? null : _pilihPoster,
                      icon: const Icon(Icons.upload_file_outlined, color: _primary),
                    ),
                    if (_poster != null)
                      IconButton(
                        tooltip: 'Hapus poster',
                        onPressed: _mengirim ? null : () => setState(() => _poster = null),
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _mengirim || _loadingKategori || _errorKategori != null ? null : _kirim,
                  icon: _mengirim
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_mengirim ? 'Mengirim pengajuan...' : 'Kirim Pengajuan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Status awal pengajuan adalah Menunggu verifikasi admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
