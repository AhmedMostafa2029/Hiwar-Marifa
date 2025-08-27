// // lib/core/theme/app_theme.dart

// import 'package:flutter/material.dart';
// import 'package:hiwar_marifa/core/constants/constants.dart';

// class AppTheme {
//   // Theme الفاتح
//   static ThemeData lightTheme = ThemeData(
//     primaryColor: kPrimaryColor,
//     colorScheme:
//         ColorScheme.fromSwatch(
//           primarySwatch: _createMaterialColor(kPrimaryColor),
//         ).copyWith(
//           secondary: kSecondaryColor,
//           background: kBackgroundColor,
//           surface: kSurfaceColor,
//           error: kErrorColor,
//         ),
//     scaffoldBackgroundColor: kBackgroundColor,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: kPrimaryColor,
//       elevation: 0,
//       iconTheme: IconThemeData(color: Colors.white),
//       titleTextStyle: TextStyle(
//         color: Colors.white,
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//       ),
//     ),
//     visualDensity: VisualDensity.adaptivePlatformDensity,
//   );

//   // Theme الداكن
//   static ThemeData darkTheme = ThemeData.dark().copyWith(
//     primaryColor: kPrimaryColor,
//     colorScheme: ColorScheme.dark().copyWith(
//       primary: kPrimaryColor,
//       secondary: kSecondaryColor,
//     ),
//     appBarTheme: const AppBarTheme(
//       backgroundColor: kPrimaryColor,
//       elevation: 0,
//     ),
//   );

//   // دالة لتحويل اللون إلى MaterialColor (مهمة لاستخدامه كـ primarySwatch)
//   static MaterialColor _createMaterialColor(Color color) {
//     List strengths = <double>[.05];
//     Map<int, Color> swatch = {};
//     final int r = color.red, g = color.green, b = color.blue;

//     for (int i = 1; i < 10; i++) {
//       strengths.add(0.1 * i);
//     }
//     for (var strength in strengths) {
//       final double ds = 0.5 - strength;
//       swatch[(strength * 1000).round()] = Color.fromRGBO(
//         r + ((ds < 0 ? r : (255 - r)) * ds).round(),
//         g + ((ds < 0 ? g : (255 - g)) * ds).round(),
//         b + ((ds < 0 ? b : (255 - b)) * ds).round(),
//         1,
//       );
//     }
//     return MaterialColor(color.value, swatch);
//   }
// }

import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';

class ThemeManager {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: Colors.grey[200],
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: kPrimaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[400],
    ),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: Colors.grey[850],
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: kPrimaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[400],
    ),
    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
  );

  static ThemeData getTheme(bool isDarkMode) {
    return isDarkMode ? darkTheme : lightTheme;
  }
}
