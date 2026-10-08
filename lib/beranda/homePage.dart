import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String kategoriAktif = "Semua";

  final lomba = {
    "kategori": "Pendidikan",

    "judul": "Lomba Karya Tulis Ilmiah",

    "penyelenggara": "Universitas Khairun",

    "kuota": "67/100",
  };

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
                      const Text(
                        "Halo, Valdo Backend 👋",

                        style: TextStyle(
                          fontSize: 20,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Temukan berbagai lomba menarik di Ternate",

                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),

                  Container(
                    height: 45,

                    width: 45,

                    decoration: BoxDecoration(
                      color: Colors.white,

                      shape: BoxShape.circle,
                    ),

                    child: const Icon(Icons.notifications_none),
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

              child: const TextField(
                decoration: InputDecoration(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    "Lomba Terbaru",

                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const Text(
                    "Lihat Semua",

                    style: TextStyle(
                      color: Colors.blue,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // CARD LOMBA
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 25),

              height: 120,

              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(18),

                border: Border.all(color: Colors.grey.shade200),
              ),

              child: Row(
                children: [
                  // TEMPAT GAMBAR

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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,

                            vertical: 4,
                          ),

                          decoration: BoxDecoration(
                            color: const Color(0xffE5F0FF),

                            borderRadius: BorderRadius.circular(8),
                          ),

                          child: Text(
                            lomba["kategori"]!,

                            style: const TextStyle(
                              fontSize: 11,

                              color: Colors.blue,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          lomba["judul"]!,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

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

                  // BUTTON
                  Container(
                    height: 38,

                    decoration: BoxDecoration(
                      color: const Color(0xff1769FF),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),

                      child: Row(
                        children: [
                          Text(
                            "Lihat",

                            style: TextStyle(
                              color: Colors.white,

                              fontSize: 12,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(width: 5),

                          Icon(
                            Icons.arrow_forward_ios,

                            size: 10,

                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),

      // BOTTOM MENU
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.blue,

        unselectedItemColor: Colors.grey,

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),

          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),

            label: "Lomba Saya",
          ),

          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Ajukan"),

          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
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

            style: TextStyle(
              color: aktif ? Colors.white : Colors.grey,

              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}