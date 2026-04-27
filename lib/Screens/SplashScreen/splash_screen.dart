import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay 3 detik lalu pindah ke AppScreen
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return; 
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppScreen()),
      );
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
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text('V.1.0.0', style: greyReguler),
          ),
        ],
      ),
    );
  }
}
