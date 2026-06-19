import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'splash_screen.dart';
import 'home_screen.dart';
import 'my_booking_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'cart_provider.dart';

// ─── Background FCM handler (must be top-level) ───────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// ─── Single main() ────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);

  FirebaseMessaging.instance.getToken().then((token) {
    debugPrint('FCM TOKEN: $token');
  });

  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('Foreground: ${message.notification?.title}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('Opened from notification');
  });

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // ✅ CartProvider wraps the entire app here — single source of truth
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const AjoomiApp(),
    ),
  );
}

// ─── Root App ─────────────────────────────────────────────────
class AjoomiApp extends StatelessWidget {
  const AjoomiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ajoomi',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const CustomerBottomNav(),
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06B6D4),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4FCFD),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF06B6D4),
          unselectedItemColor: Color(0xFFB0BEC5),
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
        ),
      ),
    );
  }
}

// ─── Customer Bottom Nav ──────────────────────────────────────
class CustomerBottomNav extends StatefulWidget {
  const CustomerBottomNav({super.key});

  @override
  State<CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<CustomerBottomNav> {
  int _index = 0;

  void switchTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigate: switchTab),
      const MyBookingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
