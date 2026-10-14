import 'package:flutter/material.dart';

// import 'detailLombaPage.dart';
// import 'notificationPage.dart';

// class HomePage extends StatefulWidget {
//   final String username;

//   const HomePage({super.key, required this.username});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   String kategoriAktif = "Semua";

//   String keyword = "";

//   final TextEditingController searchController = TextEditingController();

//   final List<Map<String, String>> daftarLomba = [
//     {
//       "kategori": "Pendidikan",

//       "judul": "Lomba Karya Tulis Ilmiah",

//       "penyelenggara": "Universitas Khairun",

//       "kuota": "67/100",

//       "deskripsi": "Lomba karya tulis ilmiah tingkat pelajar dan mahasiswa dalam rangka meningkatkan inovasi dan kreativitas generasi muda.",

//       "persyaratan":
//           "• Peserta aktif pelajar atau mahasiswa\n"
//           "• Karya original\n"
//           "• Belum pernah dipublikasikan",
//     },

//     {
//       "kategori": "Seni",

//       "judul": "Festival Fotografi Pesona Bahari",

//       "penyelenggara": "Dispar Kota Ternate",

//       "kuota": "50/100",

//       "deskripsi":
//           "Kompetisi fotografi dengan tema budaya dan keindahan Ternate.",

//       "persyaratan":
//           "• Foto karya sendiri\n"
//           "• Tidak melanggar hak cipta",
//     },
//   ];

//   List<Map<String, String>> get lombaFilter {
//     return daftarLomba.where((item) {
//       bool kategori =
//           kategoriAktif == "Semua" || item["kategori"] == kategoriAktif;

//       bool cari =
//           item["judul"]!.toLowerCase().contains(keyword.toLowerCase()) ||
//           item["penyelenggara"]!.toLowerCase().contains(keyword.toLowerCase());

//       return kategori && cari;
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffF8FAFC),

//       body: SafeArea(
//         child: Column(
//           children: [
//             // HEADER

//             Padding(
//               padding: const EdgeInsets.fromLTRB(25, 20, 25, 15),

//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,

//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,

//                     children: [
//                       Text(
//                         "Halo, ${widget.username} 👋",

//                         style: const TextStyle(
//                           fontSize: 20,

//                           fontWeight: FontWeight.bold,

//                           color: Color(0xff263247),
//                         ),
//                       ),

//                       const SizedBox(height: 5),

//                       const Text(
//                         "Temukan berbagai lomba menarik di Ternate!",

//                         style: TextStyle(
//                           fontSize: 13,

//                           color: Color(0xff98A5B8),
//                         ),
//                       ),
//                     ],
//                   ),

//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,

//                         MaterialPageRoute(
//                           builder: (context) => const NotificationPage(),
//                         ),
//                       );
//                     },

//                     child: Container(
//                       width: 45,

//                       height: 45,

//                       decoration: const BoxDecoration(
//                         color: Colors.white,

//                         shape: BoxShape.circle,
//                       ),

//                       child: const Icon(Icons.notifications_none),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // SEARCH
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 25),

//               height: 50,

//               decoration: BoxDecoration(
//                 color: Colors.white,

//                 borderRadius: BorderRadius.circular(30),
//               ),

//               child: TextField(
//                 controller: searchController,

//                 onChanged: (value) {
//                   setState(() {
//                     keyword = value;
//                   });
//                 },

//                 decoration: const InputDecoration(
//                   hintText: "Cari lomba karya tulis, fotografi...",

//                   prefixIcon: Icon(Icons.search),

//                   border: InputBorder.none,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             SizedBox(
//               height: 40,

//               child: ListView(
//                 scrollDirection: Axis.horizontal,

//                 padding: const EdgeInsets.symmetric(horizontal: 25),

//                 children: [
//                   kategori("Semua"),

//                   kategori("Pendidikan"),

//                   kategori("Seni"),

//                   kategori("Teknologi"),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 25),

//               child: Align(
//                 alignment: Alignment.centerLeft,

//                 child: Text(
//                   "Lomba Terbaru",

//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 15),

//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.symmetric(horizontal: 25),

//                 itemCount: lombaFilter.length,

//                 itemBuilder: (context, index) {
//                   return cardLomba(lombaFilter[index]);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget cardLomba(Map<String, String> lomba) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 15),

//       height: 120,

//       padding: const EdgeInsets.all(12),

//       decoration: BoxDecoration(
//         color: Colors.white,

//         borderRadius: BorderRadius.circular(18),

//         border: Border.all(color: const Color(0xffE7EDF5)),
//       ),

//       child: Row(
//         children: [
//           // POSTER

//           Container(
//             width: 78,

//             height: 90,

//             decoration: BoxDecoration(
//               color: const Color(0xff15295B),

//               borderRadius: BorderRadius.circular(12),
//             ),

//             child: const Center(
//               child: Text(
//                 "LKTI\n2026",

//                 textAlign: TextAlign.center,

//                 style: TextStyle(
//                   color: Colors.white,

//                   fontSize: 11,

//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(width: 12),

//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,

//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 9,

//                     vertical: 3,
//                   ),

//                   decoration: BoxDecoration(
//                     color: const Color(0xffE8F1FF),

//                     borderRadius: BorderRadius.circular(20),
//                   ),

//                   child: Text(
//                     lomba["kategori"]!,

//                     style: const TextStyle(
//                       color: Color(0xff1769FF),

//                       fontSize: 11,
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 5),

//                 Text(
//                   lomba["judul"]!,

//                   maxLines: 1,

//                   overflow: TextOverflow.ellipsis,

//                   style: const TextStyle(
//                     fontSize: 15,

//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),

//                 const SizedBox(height: 4),

//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.account_balance,

//                       size: 13,

//                       color: Color(0xff98A5B8),
//                     ),

//                     const SizedBox(width: 5),

//                     Expanded(
//                       child: Text(
//                         lomba["penyelenggara"]!,

//                         maxLines: 1,

//                         overflow: TextOverflow.ellipsis,

//                         style: const TextStyle(
//                           fontSize: 12,

//                           color: Color(0xff98A5B8),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 Text(
//                   "Kuota : ${lomba["kuota"]}",

//                   style: const TextStyle(
//                     fontSize: 12,

//                     color: Color(0xff1769FF),

//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,

//                 MaterialPageRoute(
//                   builder: (context) => DetailLombaPage(lomba: lomba),
//                 ),
//               );
//             },

//             child: Container(
//               height: 36,

//               padding: const EdgeInsets.symmetric(horizontal: 12),

//               decoration: BoxDecoration(
//                 color: const Color(0xff1769FF),

//                 borderRadius: BorderRadius.circular(12),
//               ),

//               child: const Center(
//                 child: Text(
//                   "Lihat Detail",

//                   style: TextStyle(
//                     color: Colors.white,

//                     fontSize: 11,

//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget kategori(String text) {
//     bool aktif = kategoriAktif == text;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           kategoriAktif = text;
//         });
//       },

//       child: Container(
//         margin: const EdgeInsets.only(right: 10),

//         padding: const EdgeInsets.symmetric(horizontal: 18),

//         decoration: BoxDecoration(
//           color: aktif ? const Color(0xff1769FF) : Colors.white,

//           borderRadius: BorderRadius.circular(20),

//           border: Border.all(color: Colors.grey.shade300),
//         ),

//         child: Center(
//           child: Text(
//             text,

//             style: TextStyle(color: aktif ? Colors.white : Colors.grey),
//           ),
//         ),
//       ),
//     );
//   }
// }
