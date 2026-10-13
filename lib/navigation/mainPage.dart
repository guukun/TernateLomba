import 'package:flutter/material.dart';
import '../pages/beranda/homePage.dart';
import '../pages/profile/profilePage.dart';
import '../pages/lombaSaya/lombaSayaPage.dart';
import '../pages/ajukan/ajukanPage.dart';

class MainPage extends StatefulWidget {
  final String username;

  const MainPage({super.key, required this.username});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(username: widget.username),

      const LombaSayaPage(),

      const AjukanPage(),

      ProfilePage(username: widget.username),
    ];

    return Scaffold(
      body: pages[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.blue,

        unselectedItemColor: Colors.grey,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

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
}