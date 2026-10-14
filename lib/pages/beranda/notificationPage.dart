import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notifikasi = [
      {
        "judul": "Pendaftaran berhasil",

        "isi": "Lomba Karya Tulis Ilmiah berhasil didaftarkan.",

        "waktu": "Baru saja",
      },

      {
        "judul": "Lomba baru tersedia",

        "isi": "AI Innovation Competition 2026 telah tersedia.",

        "waktu": "2 jam lalu",
      },

      {
        "judul": "Status pendaftaran",

        "isi": "Pendaftaran Anda sedang menunggu verifikasi.",

        "waktu": "Kemarin",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,

        elevation: 0,

        centerTitle: true,

        title: const Text(
          "Notifikasi",

          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: ListView.builder(
          itemCount: notifikasi.length,

          itemBuilder: (context, index) {
            final item = notifikasi[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 15),

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(18),

                border: Border.all(color: Colors.grey.shade200),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Container(
                    height: 45,

                    width: 45,

                    decoration: const BoxDecoration(
                      color: Color(0xffE5F0FF),

                      shape: BoxShape.circle,
                    ),

                    child: const Icon(Icons.notifications, color: Colors.blue),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          item["judul"]!,

                          style: const TextStyle(
                            fontSize: 15,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          item["isi"]!,

                          style: TextStyle(
                            fontSize: 13,

                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          item["waktu"]!,

                          style: const TextStyle(
                            fontSize: 11,

                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}