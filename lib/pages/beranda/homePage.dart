import 'package:flutter/material.dart';

import 'notificationPage.dart';

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String kategoriAktif = "Semua";

  String keyword = "";

  final TextEditingController searchController = TextEditingController();

  // DATA LOMBA SEMENTARA
  // nanti bisa diganti dari API Laravel

  final List<Map<String, String>> daftarLomba = [
    {
      "kategori": "Pendidikan",
      "judul": "Lomba Karya Tulis Ilmiah",
      "penyelenggara": "Universitas Khairun",
      "kuota": "67/100",
    },

    {
      "kategori": "Seni",
      "judul": "Festival Fotografi Ternate",
      "penyelenggara": "Komunitas Seni Ternate",
      "kuota": "50/100",
    },

    {
      "kategori": "Teknologi",
      "judul": "AI Innovation Competition",
      "penyelenggara": "Tech Indonesia",
      "kuota": "80/100",
    },
  ];

  // FILTER DATA

  List<Map<String, String>> get lombaFilter {
    return daftarLomba.where((item) {
      bool sesuaiKategori =
          kategoriAktif == "Semua" || item["kategori"] == kategoriAktif;

      bool sesuaiPencarian =
          item["judul"]!.toLowerCase().contains(keyword.toLowerCase()) ||
          item["kategori"]!.toLowerCase().contains(keyword.toLowerCase()) ||
          item["penyelenggara"]!.toLowerCase().contains(keyword.toLowerCase());

      return sesuaiKategori && sesuaiPencarian;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      body: SafeArea(
        child: Column(
          children: [
            // HEADER

            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 15),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        "Halo, ${widget.username} 👋",

                        style: const TextStyle(
                          fontSize: 20,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Temukan berbagai lomba menarik di Ternate",

                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),

                  // NOTIFICATION BUTTON
                  Container(
                    height: 45,

                    width: 45,

                    decoration: const BoxDecoration(
                      color: Colors.white,

                      shape: BoxShape.circle,
                    ),

                    child: IconButton(
                      icon: const Icon(Icons.notifications_none),

                      onPressed: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (context) => const NotificationPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // SEARCH
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 25),

              height: 50,

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(30),
              ),

              child: TextField(
                controller: searchController,

                onChanged: (value) {
                  setState(() {
                    keyword = value;
                  });
                },

                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),

                  hintText: "Cari lomba karya tulis, fotografi...",

                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // CATEGORY
            SizedBox(
              height: 40,

              child: ListView(
                scrollDirection: Axis.horizontal,

                padding: const EdgeInsets.symmetric(horizontal: 25),

                children: [
                  category("Semua"),

                  category("Pendidikan"),

                  category("Seni"),

                  category("Teknologi"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),

              child: Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  "Lomba Terbaru",

                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // CARD LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 25),

                itemCount: lombaFilter.length,

                itemBuilder: (context, index) {
                  final lomba = lombaFilter[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),

                    height: 120,

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(18),

                      border: Border.all(color: Colors.grey.shade200),
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 75,

                          height: 90,

                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,

                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: const Icon(Icons.image, color: Colors.grey),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                lomba["kategori"]!,

                                style: const TextStyle(
                                  color: Colors.blue,

                                  fontSize: 12,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                lomba["judul"]!,

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,

                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                lomba["penyelenggara"]!,

                                style: TextStyle(
                                  fontSize: 12,

                                  color: Colors.grey.shade600,
                                ),
                              ),

                              Text(
                                "Kuota : ${lomba["kuota"]}",

                                style: const TextStyle(
                                  fontSize: 12,

                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          height: 38,

                          padding: const EdgeInsets.symmetric(horizontal: 12),

                          decoration: BoxDecoration(
                            color: const Color(0xff1769FF),

                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: const Center(
                            child: Text(
                              "Lihat",

                              style: TextStyle(
                                color: Colors.white,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget category(String text) {
    bool aktif = kategoriAktif == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          kategoriAktif = text;
        });
      },

      child: Container(
        margin: const EdgeInsets.only(right: 10),

        padding: const EdgeInsets.symmetric(horizontal: 18),

        decoration: BoxDecoration(
          color: aktif ? Colors.blue : Colors.white,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(color: Colors.grey.shade300),
        ),

        child: Center(
          child: Text(
            text,

            style: TextStyle(color: aktif ? Colors.white : Colors.grey),
          ),
        ),
      ),
    );
  }
}
