import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String username;

  final Function(String) onSave;

  const EditProfilePage({
    super.key,

    required this.username,

    required this.onSave,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;

  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.username);
  }

  void save() {
    widget.onSave(nameController.text);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),

      body: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          children: [
            TextField(
              controller: nameController,

              decoration: const InputDecoration(labelText: "Nama"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,

              obscureText: true,

              decoration: const InputDecoration(labelText: "Password Baru"),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: save,

                child: const Text("Simpan Perubahan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}