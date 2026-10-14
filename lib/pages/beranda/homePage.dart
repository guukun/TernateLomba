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

  // DATA SEMENTARA
  // Nanti diganti dari API Laravel

  final List<Map<String, String>> daftarLomba = [
    {
      "kategori": "Pendidikan",
      "judul": "Lomba Karya Tulis Ilmiah",
      "penyelenggara": "Universitas Khairun",
      "kuota": "67/100",
      "poster": "",
    },

    {
      "kategori": "Seni",
      "judul": "Festival Fotografi Ternate",
      "penyelenggara": "Dispar Kota Ternate",
      "kuota": "50/100",
      "poster": "",
    },

    {
      "kategori": "Teknologi",
      "judul": "AI Innovation Competition",
      "penyelenggara": "Tech Indonesia",
      "kuota": "80/100",
      "poster": "",
    },
  ];

  List<Map<String, String>> get lombaFilter {
    return daftarLomba.where((item) {
      bool sesuaiKategori =
          kategoriAktif == "Semua" || item["kategori"] == kategoriAktif;

      bool sesuaiSearch =
          item["judul"]!.toLowerCase().contains(keyword.toLowerCase()) ||
          item["kategori"]!.toLowerCase().contains(keyword.toLowerCase()) ||
          item["penyelenggara"]!.toLowerCase().contains(keyword.toLowerCase());

      return sesuaiKategori && sesuaiSearch;
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

                          color: Color(0xff263247),
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "Temukan berbagai lomba menarik di Ternate!",

                        style: TextStyle(
                          fontSize: 13,

                          color: Color(0xff98A5B8),
                        ),
                      ),
                    ],
                  ),

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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    "Lomba Terbaru",

                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  Text(
                    "Lihat Semua",

                    style: TextStyle(
                      color: Colors.blue.shade600,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 25),

                itemCount: lombaFilter.length,

                itemBuilder: (context, index) {
                  final lomba = lombaFilter[index];

                  return buildCardLomba(lomba);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCardLomba(Map<String, String> lomba) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      padding: const EdgeInsets.all(12),

      height: 140,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 85,

            height: 110,

            decoration: BoxDecoration(
              color: const Color(0xffEEF4FF),

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.image_outlined,

              size: 40,

              color: Colors.grey,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xffE8F1FF),

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    lomba["kategori"]!,

                    style: const TextStyle(
                      color: Color(0xff1769FF),

                      fontSize: 11,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  lomba["judul"]!,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 16,

                    fontWeight: FontWeight.bold,

                    color: Color(0xff263247),
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.account_balance,

                      size: 14,

                      color: Color(0xff98A5B8),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        lomba["penyelenggara"]!,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 12,

                          color: Color(0xff98A5B8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  "Kuota : ${lomba["kuota"]}",

                  style: const TextStyle(
                    fontSize: 12,

                    color: Color(0xff1769FF),

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 40,

            padding: const EdgeInsets.symmetric(horizontal: 14),

            decoration: BoxDecoration(
              color: const Color(0xff1769FF),

              borderRadius: BorderRadius.circular(12),
            ),

            child: const Center(
              child: Text(
                "Lihat Detail",

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 12,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
