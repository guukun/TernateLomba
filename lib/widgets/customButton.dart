import 'package:flutter/material.dart';

/// Global primary action. Feature screens control enabled/loading state only.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !loading && onPressed != null,
      label: text,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(text, key: const ValueKey('label')),
        ),
      ),
    );
  }
}