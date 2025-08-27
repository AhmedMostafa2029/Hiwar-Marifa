import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/constants/constants.dart';
import 'package:hiwar_marifa/presentation/pages/start_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    // الانتقال بعد ثانيتين
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const StartPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor, // يمكن تغيير اللون حسب تصميمك
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // شعار التطبيق
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(kLogo),
            ),
            const SizedBox(height: 30),
            // اسم التطبيق
            const Text(
              "Hiwar Marifa",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pacifico',
              ),
            ),
            const SizedBox(height: 20),
            // جملة ترحيبية
            const Text(
              'Welcome to our app',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
