// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hiwar_marifa/core/themes/app_theme.dart';
import 'package:hiwar_marifa/core/services/firebase_options.dart';
import 'package:hiwar_marifa/presentation/pages/chat/chat_page.dart';
import 'package:hiwar_marifa/presentation/pages/auth/email_verification_page.dart';
import 'package:hiwar_marifa/presentation/pages/home/home_page.dart';
import 'package:hiwar_marifa/presentation/pages/auth/login_page.dart';
import 'package:hiwar_marifa/presentation/pages/home/notifications_page.dart';
import 'package:hiwar_marifa/presentation/pages/auth/register_page.dart';
import 'package:hiwar_marifa/presentation/pages/splash_page.dart';
import 'package:hiwar_marifa/provider/auth_provider.dart';
import 'package:hiwar_marifa/provider/chat_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => Authprovider())],
      child: const HiwarMarifa(),
    ),
  );
}

class HiwarMarifa extends StatelessWidget {
  const HiwarMarifa({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Hiwar Marifa",
      theme: ThemeManager.lightTheme,
      darkTheme: ThemeManager.darkTheme,
      themeMode: ThemeMode.dark,
      routes: {
        LoginPage.id: (context) => LoginPage(),
        RegisterPage.id: (context) => const RegisterPage(),
        HomePage.id: (context) => const HomePage(),
        NotificationsPage.id: (context) => const NotificationsPage(),
        EmailVerificationPage.id: (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, String>?;
          return EmailVerificationPage(
            email: args?['email'] ?? '',
            password: args?['password'] ?? '',
          );
        },
      },
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
      onGenerateRoute: (settings) {
        if (settings.name == ChatPage.id) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => ChatProvider(args['groupId']),
              child: ChatPage(
                groupname: args['groupname'],
                groupId: args['groupId'],
              ),
            ),
          );
        }
        return null;
      },
    );
  }
}
