import 'package:flutter/material.dart';

class ShowSnackBar {
  static void show(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    // استخدام maybeOf بدل of علشان نتجنب الأيرور
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              scaffoldMessenger.hideCurrentSnackBar();
            },
          ),
        ),
      );
    } else {
      // لو مفيش scaffold messenger موجود، نطبع الرسالة في الكونسول
      debugPrint('Snackbar message (no scaffold): $message');
    }
  }
}
