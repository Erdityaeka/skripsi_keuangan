import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Screens/auth/login_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreens()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.asset('images/Icon.png', width: 360, height: 360),
            ),
          ),

          // 🔥 TEXT DI BAWAH
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text('V.1.0.0', style: greyReguler),
          ),
        ],
      ),
    );
  }
}
