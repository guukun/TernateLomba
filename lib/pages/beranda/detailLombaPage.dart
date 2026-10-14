import 'package:flutter/material.dart';

class DetailLombaPage extends StatelessWidget {
  final Map<String, String> lomba;

  const DetailLombaPage({super.key, required this.lomba});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      body: SafeArea(
        child: Column(
          children: [
            // HEADER

            Container(
              height: 300,

              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff26364F), Color(0xff53647D)],

                  begin: Alignment.topCenter,

                  end: Alignment.bottomCenter,
                ),
              ),

              child: Stack(
                children: [
                  Positioned(
                    top: 20,

                    left: 20,

                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },

                      child: Container(
                        width: 42,

                        height: 42,

                        decoration: BoxDecoration(
                          color: Colors.white24,

                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.arrow_back,

                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 25,

                    bottom: 35,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,

                            vertical: 5,
                          ),

                          decoration: BoxDecoration(
                            color: const Color(0xff4285F4),

                            borderRadius: BorderRadius.circular(20),
                          ),

                          child: Text(
                            "${lomba["kategori"]} • Nasional",

                            style: const TextStyle(
                              color: Colors.white,

                              fontSize: 11,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          lomba["judul"] ?? "",

                          style: const TextStyle(
                            color: Colors.white,

                            fontSize: 22,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance,

                              size: 16,

                              color: Colors.white70,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              lomba["penyelenggara"] ?? "",

                              style: const TextStyle(
                                color: Colors.white70,

                                fontSize: 14,
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

            Expanded(
              child: Container(
                transform: Matrix4.translationValues(0, -25, 0),

                padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),

                decoration: const BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),

                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // KUOTA

                      Container(
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFD),

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,

                              children: [
                                const Text(
                                  "Status Pendaftar",

                                  style: TextStyle(
                                    color: Color(0xff98A5B8),

                                    fontSize: 13,
                                  ),
                                ),

                                Text(
                                  "${lomba["kuota"]} Kuota Terisi",

                                  style: const TextStyle(
                                    color: Color(0xff1769FF),

                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),

                              child: const LinearProgressIndicator(
                                value: 0.67,

                                minHeight: 8,

                                backgroundColor: Color(0xffDCE5F2),

                                color: Color(0xff1769FF),
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              "Sisa 33 kursi pendaftaran tersedia",

                              style: TextStyle(
                                color: Color(0xff98A5B8),

                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: infoBox(
                              "Biaya Pendaftaran",

                              "Gratis",

                              Colors.green,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: infoBox(
                              "Total Hadiah",

                              "Rp 15.000.000",

                              const Color(0xff263247),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: infoBox(
                              "Batas Pendaftaran",

                              "20 Nov 2026",

                              Colors.red,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: infoBox(
                              "Pelaksanaan",

                              "1 - 3 Des 2026",

                              const Color(0xff263247),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "Deskripsi Singkat",

                        style: TextStyle(
                          fontSize: 17,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        lomba["deskripsi"] ?? "Tidak ada deskripsi lomba.",

                        style: const TextStyle(
                          fontSize: 14,

                          height: 1.6,

                          color: Color(0xff5F6B7A),
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "Persyaratan Lomba",

                        style: TextStyle(
                          fontSize: 17,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        lomba["persyaratan"] ?? "",

                        style: const TextStyle(fontSize: 14, height: 1.7),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),

        child: SizedBox(
          height: 55,

          child: ElevatedButton(
            onPressed: () {},

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1769FF),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),

            child: const Text(
              "Daftar Sekarang →",

              style: TextStyle(
                color: Colors.white,

                fontSize: 16,

                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget infoBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: const Color(0xffF8FAFD),

        borderRadius: BorderRadius.circular(15),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: const TextStyle(color: Color(0xff98A5B8), fontSize: 12),
          ),

          const SizedBox(height: 8),

          Text(
            value,

            style: TextStyle(
              color: color,

              fontSize: 15,

              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}