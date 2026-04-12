import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Screens/login_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        // pastikan widget masih aktif
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Image.asset('images/Icon.png', width: 360, height: 360)],
        ),
      ),
    );
  }
}
