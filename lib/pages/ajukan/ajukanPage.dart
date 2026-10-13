import 'package:flutter/material.dart';

class AjukanPage extends StatelessWidget {
  const AjukanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Ajukan Lomba",

          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
