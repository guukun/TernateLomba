import 'package:flutter/material.dart';

import 'detailLombaPage.dart';
import 'notificationPage.dart';

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();

  String keyword = "";

  String kategoriAktif = "Semua";

  final List<Map<String, String>> daftarLomba = [
    {
      "kategori": "Pendidikan",
      "judul": "Lomba Karya Tulis Ilmiah Nasional 2026",
      "penyelenggara": "Universitas Khairun",
      "kuota": "67/100",
      "poster": "LKTI",
      "tanggal": "Nov 2026",
      "deskripsi": "Kompetisi karya tulis ilmiah tingkat nasional untuk mahasiswa dan pelajar.",
      "persyaratan": "Peserta aktif mahasiswa atau pelajar.\nKarya belum pernah dipublikasikan.",
      "biaya": "Gratis",
      "hadiah": "Sertifikat dan uang pembinaan",
    },

    {
      "kategori": "Seni",
      "judul": "Festival Fotografi Pesona Ternate 2026",
      "penyelenggara": "Dispar Kota Ternate",
      "kuota": "50/100",
      "poster": "FOTO",
      "tanggal": "Des 2026",
      "deskripsi": "Kompetisi fotografi budaya dan alam Ternate.",
      "persyaratan": "Foto merupakan karya sendiri.",
      "biaya": "Rp25.000",
      "hadiah": "Trofi dan sertifikat",
    },

    {
      "kategori": "Teknologi",
      "judul": "AI Innovation Competition 2026",
      "penyelenggara": "Tech Indonesia",
      "kuota": "80/100",
      "poster": "AI",
      "tanggal": "Des 2026",
      "deskripsi": "Kompetisi inovasi teknologi dan digital.",
      "persyaratan": "Proposal inovasi teknologi.",
      "biaya": "Gratis",
      "hadiah": "Uang pembinaan",
    },
  ];

  List<Map<String, String>> get lombaTampil {
    return daftarLomba.where((lomba) {
      final cocokKategori =
          kategoriAktif == "Semua" || lomba["kategori"] == kategoriAktif;

      final cocokSearch =
          lomba["judul"]!.toLowerCase().contains(keyword.toLowerCase()) ||
          lomba["kategori"]!.toLowerCase().contains(keyword.toLowerCase()) ||
          lomba["penyelenggara"]!.toLowerCase().contains(keyword.toLowerCase());

      return cocokKategori && cocokSearch;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 15),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        "Halo, ${widget.username} 👋",

                        style: const TextStyle(
                          fontSize: 23,

                          fontWeight: FontWeight.bold,

                          color: Color(0xff263247),
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        "Temukan berbagai lomba menarik di Ternate!",

                        style: TextStyle(
                          fontSize: 13,

                          color: Color(0xff98A5B8),
                        ),
                      ),
                    ],
                  ),

                  MouseRegion(
                    cursor: SystemMouseCursors.click,

                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (context) => const NotificationPage(),
                          ),
                        );
                      },

                      child: Container(
                        width: 45,

                        height: 45,

                        decoration: BoxDecoration(
                          color: Colors.white,

                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),

                              blurRadius: 8,
                            ),
                          ],
                        ),

                        child: const Icon(
                          Icons.notifications_none,

                          color: Color(0xff263247),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // SEARCH BAR

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),

              height: 52,

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
                  border: InputBorder.none,

                  hintText: "Cari lomba karya tulis, fotografi...",

                  prefixIcon: Icon(Icons.search, color: Color(0xff9AA8BD)),

                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // CATEGORY
            SizedBox(
              height: 45,

              child: ListView(
                scrollDirection: Axis.horizontal,

                padding: const EdgeInsets.symmetric(horizontal: 22),

                children: [
                  kategoriButton("Semua"),

                  kategoriButton("Pendidikan"),

                  kategoriButton("Seni"),

                  kategoriButton("Teknologi"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),

              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),

                child: Align(
                  alignment: Alignment.centerLeft,

                  child: Text(
                    "Lomba Terbaru",

                    style: TextStyle(
                      fontSize: 18,

                      fontWeight: FontWeight.bold,

                      color: Color(0xff263247),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 22),

                itemCount: lombaTampil.length,

                itemBuilder: (context, index) {
                  return cardLomba(context, lombaTampil[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget kategoriButton(String text) {
    final bool aktif = kategoriAktif == text;

    return MouseRegion(
      cursor: SystemMouseCursors.click,

      child: GestureDetector(
        onTap: () {
          setState(() {
            kategoriAktif = text;
          });
        },

        child: Container(
          margin: const EdgeInsets.only(right: 10),

          padding: const EdgeInsets.symmetric(horizontal: 20),

          decoration: BoxDecoration(
            color: aktif ? const Color(0xff2878FF) : Colors.white,

            borderRadius: BorderRadius.circular(25),
          ),

          child: Center(
            child: Text(
              text,

              style: TextStyle(
                color: aktif ? Colors.white : const Color(0xff98A5B8),

                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget cardLomba(BuildContext context, Map<String, String> lomba) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,

      child: Container(
        margin: const EdgeInsets.only(bottom: 18),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(18),
        ),

        child: Row(
          children: [
            Container(
              width: 82,

              height: 90,

              decoration: BoxDecoration(
                color: lomba["kategori"] == "Seni"
                    ? const Color(0xff075E49)
                    : const Color(0xff172B59),

                borderRadius: BorderRadius.circular(15),
              ),

              child: Center(
                child: Text(
                  "${lomba["poster"]}\n${lomba["tanggal"]}",

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 12,

                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                        color: Color(0xff2878FF),

                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    lomba["judul"]!,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 15,

                      fontWeight: FontWeight.bold,

                      color: Color(0xff263247),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "🏛 ${lomba["penyelenggara"]}",

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 12,

                      color: Color(0xff98A5B8),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Kuota : ${lomba["kuota"]}",

                    style: const TextStyle(
                      fontSize: 12,

                      color: Color(0xff2878FF),

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            MouseRegion(
              cursor: SystemMouseCursors.click,

              child: SizedBox(
                width: 95,

                height: 38,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2878FF),

                    padding: EdgeInsets.zero,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (context) => DetailLombaPage(lomba: lomba),
                      ),
                    );
                  },

                  child: const Text(
                    "Lihat Detail",

                    style: TextStyle(color: Colors.white, fontSize: 11),
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
