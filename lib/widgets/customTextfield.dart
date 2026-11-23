import 'package:flutter/material.dart';

import '../config/appTheme.dart';

/// Reusable input for login, registration and account forms.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.tl;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: p.navy, fontWeight: FontWeight.w600),
      cursorColor: p.primary,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20, color: p.grey),
        suffixIcon: suffixIcon,
      ),
    );
  }
}