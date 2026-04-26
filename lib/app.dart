import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        // Pantau perubahan login Firebase
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
  // Status splash
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // Delay splash agar session Firebase restore
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSplash = false);

        splashActive = false;
      }
    });
  }

  // Cek apakah akun masih ada di Firestore
  Future<bool> _checkUserExists(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(uid)
          .get();

      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    // Splash screen tetap tampil
    if (_showSplash) {
      return const SplashScreen();
    }

    // Jika user benar-benar null
    if (user == null) {
      return const LoginScreens();
    }

    // Cek Firestore apakah akun masih ada
    return FutureBuilder<bool>(
      future: _checkUserExists(user.uid),
      builder: (context, snapshot) {
        // Loading saat cek akun
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Jika akun sudah dihapus
        if (!snapshot.hasData || snapshot.data == false) {
          // Logout paksa
          Future.microtask(() async {
            await FirebaseAuth.instance.signOut();
          });

          return const LoginScreens();
        }

        // Jika akun valid
        return const BottomNavigation();
      },
    );
  }
}
