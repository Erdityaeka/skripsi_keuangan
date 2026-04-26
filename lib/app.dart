import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skripsi_keuangan/Screens/SplashScreen/splash_screen.dart';
import 'package:skripsi_keuangan/Screens/auth/login_screens.dart';
import 'package:skripsi_keuangan/navigation/bottom_navigation.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';
import '../main.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: AuthService().userChanges,
          initialData: FirebaseAuth.instance.currentUser,
        ),
      ],
      child: const SplashWrapper(),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // Tambah waktu agar Firebase sempat restore session
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSplash = false);
        splashActive = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Splash tetap tampil
    if (_showSplash) {
      return const SplashScreen();
    }

    // Jika benar-benar belum login
    if (user == null && firebaseUser == null) {
      return const LoginScreens();
    }

    // Jika session masih tersimpan
    return const BottomNavigation();
  }
}
