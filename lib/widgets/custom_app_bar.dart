import 'package:flutter/material.dart';
import '../app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Per cambiare il colore della barra in alto: modifica AppColors.primary
      // in lib/app_theme.dart (non qui).
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'assets/images/logo.png', // il tuo logo - va inserito in pubspec sezione assets
          fit: BoxFit.contain,
        ),
      ),
      title: const SizedBox.shrink(), // niente titolo
    );
  }

  // Questa dimensione serve perché AppBar ha un'altezza fissa
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
