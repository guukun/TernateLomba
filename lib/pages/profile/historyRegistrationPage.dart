import 'package:flutter/material.dart';

class HistoryRegistrationPage extends StatelessWidget {
  const HistoryRegistrationPage({super.key});

  final List<Map<String, String>> history = const [
    {
      "nama": "Lomba UI/UX Nasional",

      "status": "Menunggu Verifikasi",

      "tanggal": "12 Oktober 2026",
    },

    {
      "nama": "Mobile Competition",

      "status": "Diterima",

      "tanggal": "20 September 2026",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Pendaftaran")),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),

        itemCount: history.length,

        itemBuilder: (context, index) {
          final item = history[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 15),

            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: Colors.grey.shade300),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  item["nama"]!,

                  style: const TextStyle(
                    fontSize: 18,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text("Tanggal : ${item["tanggal"]}"),

                const SizedBox(height: 5),

                Text(
                  "Status : ${item["status"]}",

                  style: TextStyle(
                    color: item["status"] == "Diterima"
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}