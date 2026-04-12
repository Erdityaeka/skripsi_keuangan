import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:skripsi_keuangan/app.dart';
import 'dart:async';

import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

// flag global untuk splash
bool splashActive = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RootApp());
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  late StreamSubscription<List<ConnectivityResult>> subscription;
  bool isConnected = true;
  bool _snackActive = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final results = await Connectivity().checkConnectivity();
      bool nowConnected = !results.contains(ConnectivityResult.none);
      setState(() => isConnected = nowConnected);

      _showSnackBar(
        nowConnected ? "Internet terhubung" : "Tidak ada koneksi internet",
        nowConnected ? Colors.green : Colors.red,
      );
    });

    subscription = Connectivity().onConnectivityChanged.listen((results) {
      bool nowConnected = !results.contains(ConnectivityResult.none);

      if (nowConnected != isConnected) {
        setState(() => isConnected = nowConnected);

        _showSnackBar(
          nowConnected ? "Internet terhubung" : "Tidak ada koneksi internet",
          nowConnected ? Colors.green : Colors.red,
        );
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted || _snackActive) return;
    if (splashActive) return; // jangan tampilkan snackbar saat splash

    _snackActive = true;
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      _snackActive = false;
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: const AppScreen(),
    );
  }
}
