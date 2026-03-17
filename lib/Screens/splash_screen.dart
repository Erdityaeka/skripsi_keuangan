import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Screens/login_screens.dart';

class Splasscreen extends StatefulWidget {
  const Splasscreen({super.key});

  @override
  State<Splasscreen> createState() => _SplasscreenState();
}

class _SplasscreenState extends State<Splasscreen> {
  void initState() {
    super.initState();
    // Delay 3 detik lalu pindah ke HomePage
    Timer(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreens()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo Splash
            Image.asset(
              'images/Icon.png', // Ganti dengan path logo Anda
              width: 360,
              height: 360,
            ),
          ],
        ),
      ),
    );
  }
}
