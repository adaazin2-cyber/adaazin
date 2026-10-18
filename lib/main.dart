import 'package:flutter/material.dart';
import 'landing_page.dart';      // ← IMPORT LANDING PAGE
import 'login_page.dart';
import 'loader_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'buy_account.dart';
import 'splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'XEXTRO',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'ShareTechMono',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark().copyWith(
          secondary: Colors.purple,
        ),
      ),
      initialRoute: '/', // ← LANDING PAGE sebagai halaman pertama
      onGenerateRoute: (settings) {
        switch (settings.name) {
          // ============ LANDING PAGE (HALAMAN PERTAMA) ============
          case '/':
            return MaterialPageRoute(builder: (_) => const LandingPage());

          // ============ LOGIN PAGE ============
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());

          // ============ SPLASH PAGE ============
          case '/splash':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SplashPage(
                data: args,
              ),
            );

          // ============ BUY ACCOUNT ============
          case '/buy_account':
            return MaterialPageRoute(builder: (_) => const BuyAccountPage());

          // ============ LOADER / DASHBOARD ============
          case '/loader':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: args['username'],
                password: args['password'],
                role: args['role'],
                sessionKey: args['key'],
                expiredDate: args['expiredDate'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                listPayload: List<Map<String, dynamic>>.from(args['listPayload'] ?? []),
                listDDoS: List<Map<String, dynamic>>.from(args['listDDoS'] ?? []),
                news: List<Map<String, dynamic>>.from(args['news'] ?? []),
              ),
            );

          // ============ ATTACK PAGE ============
          case '/attack':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AttackPage(
                username: args['username'],
                password: args['password'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                role: args['role'],
                expiredDate: args['expiredDate'],
                sessionKey: args['sessionKey'],
              ),
            );

          // ============ SELLER PAGE ============
          case '/seller':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SellerPage(
                keyToken: args['keyToken'],
              ),
            );

          // ============ ADMIN PAGE ============
          case '/admin':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AdminPage(
                sessionKey: args['sessionKey'],
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text(
                    "404 - Not Found",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}