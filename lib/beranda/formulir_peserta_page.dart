// Package untuk membuat garis border putus-putus
// pada kotak upload file.
import 'package:dotted_border/dotted_border.dart';

// Package untuk memilih file dari perangkat.
// Pada halaman ini digunakan untuk memilih file PDF.
import 'package:file_picker/file_picker.dart';

// Package utama Flutter Material Design.
import 'package:flutter/material.dart';


// ======================================================
// HALAMAN FORMULIR PESERTA
// ======================================================
// StatefulWidget digunakan karena terdapat data yang
// dapat berubah, misalnya nama file PDF yang dipilih.
class FormulirPesertaPage extends StatefulWidget {
  const FormulirPesertaPage({super.key});

  @override
  State<FormulirPesertaPage> createState() =>
      _FormulirPesertaPageState();
}


// ======================================================
// STATE HALAMAN FORMULIR PESERTA
// ======================================================
class _FormulirPesertaPageState
    extends State<FormulirPesertaPage> {

  // GlobalKey digunakan untuk mengontrol dan
  // melakukan validasi seluruh form.
  final _formKey = GlobalKey<FormState>();

  // Controller untuk membaca isi nama lengkap.
  // Nama dibuat otomatis sebagai contoh data pengguna.
  final _namaController =
      TextEditingController(text: 'Ahmad Fauzan');

  // Controller untuk input asal instansi/sekolah.
  final _asalController = TextEditingController();

  // Controller untuk input motivasi mengikuti lomba.
  final _motivasiController = TextEditingController();

  // Menyimpan nama file PDF yang dipilih.
  // Nilainya null apabila belum ada file yang dipilih.
  String? _selectedFileName;


  // ======================================================
  // DISPOSE
  // ======================================================
  // Dipanggil saat halaman ditutup.
  // Controller perlu di-dispose agar tidak
  // menyebabkan penggunaan memori yang tidak perlu.
  @override
  void dispose() {
    _namaController.dispose();
    _asalController.dispose();
    _motivasiController.dispose();

    super.dispose();
  }


  // ======================================================
  // MEMILIH FILE PDF
  // ======================================================
  Future<void> _pickPdf() async {

    // Membuka file picker dari perangkat pengguna.
    final result = await FilePicker.platform.pickFiles(

      // FileType.custom berarti kita menentukan sendiri
      // jenis ekstensi file yang boleh dipilih.
      type: FileType.custom,

      // Hanya file berekstensi PDF yang diperbolehkan.
      allowedExtensions: ['pdf'],
    );

    // Memastikan pengguna benar-benar memilih file.
    if (result != null && result.files.isNotEmpty) {

      // setState digunakan agar tampilan diperbarui
      // setelah nama file berhasil didapatkan.
      setState(() {

        // Mengambil nama file PDF yang dipilih.
        _selectedFileName = result.files.single.name;
      });
    }
  }


  // ======================================================
  // KIRIM FORMULIR
  // ======================================================
  void _submit() {

    // Menjalankan seluruh validator pada TextFormField.
    // Jika ada data tidak valid, proses dihentikan.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Memastikan peserta sudah memilih file PDF.
    if (_selectedFileName == null) {

      // Menampilkan pesan jika file belum dipilih.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih file PDF terlebih dahulu',
          ),
        ),
      );

      return;
    }

    // Jika seluruh data valid dan file PDF sudah dipilih,
    // tampilkan pesan berhasil.
    //
    // Nanti bagian ini dapat diganti dengan request
    // ke API Laravel.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pendaftaran berhasil dikirim',
        ),
      ),
    );
  }


  // ======================================================
  // WIDGET JUDUL BAGIAN
  // ======================================================
  // Fungsi ini digunakan agar desain judul bagian
  // dapat dipakai berkali-kali tanpa menulis ulang kode.
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF7B879C),
        ),
      ),
    );
  }


  // ======================================================
  // WIDGET LABEL INPUT
  // ======================================================
  // Parameter required digunakan untuk menentukan
  // apakah label perlu menampilkan tanda * merah.
  Widget _label(
    String text, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6E7B91),
            fontWeight: FontWeight.w600,
          ),
          children: [

            // Menampilkan nama label.
            TextSpan(
              text: text,
            ),

            // Jika required = true,
            // tampilkan tanda * berwarna merah.
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }


  // ======================================================
  // DESAIN INPUT FIELD
  // ======================================================
  // Fungsi ini digunakan agar semua input mempunyai
  // tampilan yang konsisten.
  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(

      // Tulisan petunjuk di dalam input.
      hintText: hint,

      hintStyle: const TextStyle(
        color: Color(0xFFA3AEC2),
        fontSize: 14,
      ),

      // Icon di sebelah kanan input jika diperlukan.
      suffixIcon: suffixIcon,

      // Mengaktifkan warna background input.
      filled: true,

      fillColor: const Color(0xFFF7F9FC),

      // Jarak isi input terhadap border.
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),

      // Border default.
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE3E8F0),
        ),
      ),

      // Border saat input tidak aktif.
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE3E8F0),
        ),
      ),

      // Border saat input sedang dipilih.
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2F6FED),
          width: 1.4,
        ),
      ),

      // Border jika terjadi kesalahan validasi.
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),

      // Border saat input error dan sedang dipilih.
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
    );
  }


  // ======================================================
  // TAMPILAN UTAMA
  // ======================================================
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // Warna background halaman.
      backgroundColor:
          const Color(0xFFF9FBFD),

      // ==================================================
      // APP BAR
      // ==================================================
      appBar: AppBar(
        backgroundColor: Colors.white,

        // Menghilangkan bayangan AppBar.
        elevation: 0,

        // Tombol kembali.
        leading: IconButton(
          onPressed: () {

            // Kembali ke halaman sebelumnya.
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF2B3140),
            size: 20,
          ),
        ),

        // Judul halaman.
        title: const Text(
          'Formulir Peserta',
          style: TextStyle(
            color: Color(0xFF2B3140),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),


      // ==================================================
      // BODY
      // ==================================================
      body: SafeArea(

        // Form digunakan agar semua TextFormField
        // dapat divalidasi menggunakan _formKey.
        child: Form(
          key: _formKey,

          // Membuat halaman dapat di-scroll.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [

                // ==================================================
                // CARD INFORMASI LOMBA
                // ==================================================
                Container(
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF7F9FC),

                    borderRadius:
                        BorderRadius.circular(18),

                    border: Border.all(
                      color:
                          const Color(0xFFE4E9F1),
                    ),
                  ),

                  child: Row(
                    children: [

                      // Kotak logo lomba.
                      Container(
                        width: 62,
                        height: 62,

                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF202B3D),

                          borderRadius:
                              BorderRadius.circular(16),
                        ),

                        child: const Center(
                          child: Text(
                            'LKTI\n2024',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Informasi nama lomba dan penyelenggara.
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            // Nama lomba.
                            Text(
                              'LKTI Ternate 2024',

                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w800,
                                color:
                                    Color(0xFF2B3140),
                              ),
                            ),

                            SizedBox(height: 6),

                            // Nama penyelenggara.
                            Row(
                              children: [

                                Icon(
                                  Icons
                                      .location_city_outlined,
                                  size: 16,
                                  color:
                                      Color(0xFF9AA7BC),
                                ),

                                SizedBox(width: 5),

                                Text(
                                  'Universitas Khairun',

                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Color(0xFF9AA7BC),
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 24),


                // ==================================================
                // DATA PENGGUNA
                // ==================================================
                _sectionTitle(
                  'DATA PENGGUNA (OTOMATIS)',
                ),


                // ==================================================
                // NAMA LENGKAP
                // ==================================================
                _label(
                  'Nama Lengkap',
                ),

                TextFormField(

                  // Menggunakan nama dari controller.
                  controller: _namaController,

                  // Nama tidak boleh diedit pengguna.
                  readOnly: true,

                  decoration: _inputDecoration(
                    hint: 'Nama Lengkap',

                    // Icon kunci menandakan data otomatis
                    // dan tidak dapat diubah.
                    suffixIcon: const Padding(
                      padding:
                          EdgeInsets.only(right: 10),

                      child: Icon(
                        Icons.lock_outline,
                        color:
                            Color(0xFF9AA7BC),
                      ),
                    ),
                  ),
                ),


                const SizedBox(height: 16),


                // ==================================================
                // ASAL INSTANSI / SEKOLAH
                // ==================================================
                _label(
                  'Asal Instansi / Sekolah',
                ),

                TextFormField(
                  controller: _asalController,

                  // Validasi input.
                  validator: (value) {

                    // Tidak boleh kosong.
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Asal instansi / sekolah wajib diisi';
                    }

                    return null;
                  },

                  decoration: _inputDecoration(
                    hint:
                        'Masukkan asal instansi / sekolah',
                  ),
                ),


                const SizedBox(height: 24),


                // ==================================================
                // PERSYARATAN KHUSUS
                // ==================================================
                _sectionTitle(
                  'PERSYARATAN KHUSUS LOMBA',
                ),


                // ==================================================
                // MOTIVASI
                // ==================================================
                _label(
                  'Motivasi Mengikuti Lomba',
                  required: true,
                ),

                TextFormField(
                  controller:
                      _motivasiController,

                  // Membuat input lebih tinggi
                  // agar cocok untuk teks panjang.
                  maxLines: 5,

                  validator: (value) {

                    // Motivasi tidak boleh kosong.
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Motivasi wajib diisi';
                    }

                    return null;
                  },

                  decoration: _inputDecoration(
                    hint:
                        'Tuliskan motivasi Anda...',
                  ),
                ),


                const SizedBox(height: 20),


                // ==================================================
                // UPLOAD PDF
                // ==================================================
                _label(
                  'Upload Naskah Karya (PDF)',
                  required: true,
                ),

                GestureDetector(

                  // Saat area upload ditekan,
                  // buka file picker.
                  onTap: _pickPdf,

                  child: DottedBorder(

                    // Warna border putus-putus.
                    color:
                        const Color(0xFFB6D2FF),

                    strokeWidth: 1.5,

                    // Pola garis putus-putus.
                    dashPattern:
                        const [6, 4],

                    // Bentuk border mengikuti rounded rectangle.
                    borderType:
                        BorderType.RRect,

                    radius:
                        const Radius.circular(16),

                    child: Container(
                      width: double.infinity,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 26,
                        horizontal: 16,
                      ),

                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFF9FBFF),

                        borderRadius:
                            BorderRadius.circular(16),
                      ),

                      child: Column(
                        children: [

                          // Lingkaran icon upload.
                          Container(
                            width: 54,
                            height: 54,

                            decoration:
                                const BoxDecoration(
                              color:
                                  Color(0xFFE8F0FF),

                              shape:
                                  BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons
                                  .file_upload_outlined,

                              color:
                                  Color(0xFF3D7AF5),

                              size: 28,
                            ),
                          ),


                          const SizedBox(
                            height: 14,
                          ),


                          // Tulisan pilih file.
                          const Text(
                            'Pilih File Naskah',

                            style: TextStyle(
                              color:
                                  Color(0xFF2F6FED),

                              fontSize: 20,

                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),


                          const SizedBox(
                            height: 6,
                          ),


                          // Jika file belum dipilih,
                          // tampilkan informasi maksimal ukuran.
                          //
                          // Jika file sudah dipilih,
                          // tampilkan nama file tersebut.
                          Text(
                            _selectedFileName ??
                                'PDF maksimal ukuran 10MB',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(

                              // Warna berubah setelah
                              // file berhasil dipilih.
                              color:
                                  _selectedFileName ==
                                          null
                                      ? const Color(
                                          0xFFA4AEC1,
                                        )
                                      : const Color(
                                          0xFF5E6B82,
                                        ),

                              fontSize: 13,

                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


                const SizedBox(height: 20),


                // ==================================================
                // INFORMASI PENDAFTARAN
                // ==================================================
                Container(
                  padding:
                      const EdgeInsets.all(16),

                  decoration: BoxDecoration(

                    // Background hijau muda.
                    color:
                        const Color(0xFFEAF9F1),

                    borderRadius:
                        BorderRadius.circular(14),

                    border: Border.all(
                      color:
                          const Color(0xFFBEE8CD),
                    ),
                  ),

                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      // Icon centang.
                      Icon(
                        Icons.check_circle,
                        color:
                            Color(0xFF20B46A),
                        size: 24,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            // Judul informasi.
                            Text(
                              'Pendaftaran Praktis',

                              style: TextStyle(
                                color:
                                    Color(0xFF3A495F),

                                fontSize: 16,

                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            SizedBox(height: 4),

                            // Penjelasan informasi.
                            Text(
                              'Status pendaftaran otomatis dapat dipantau di menu Lomba Saya.',

                              style: TextStyle(
                                color:
                                    Color(0xFF6B7A90),

                                fontSize: 13,

                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 28),


                // ==================================================
                // TOMBOL KIRIM PENDAFTARAN
                // ==================================================
                SizedBox(
                  height: 54,

                  child: ElevatedButton(

                    // Menjalankan fungsi _submit
                    // ketika tombol ditekan.
                    onPressed: _submit,

                    style:
                        ElevatedButton.styleFrom(

                      // Warna tombol.
                      backgroundColor:
                          const Color(0xFF2F6FED),

                      elevation: 2,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),

                    child: const Text(
                      'Kirim Pendaftaran',

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}