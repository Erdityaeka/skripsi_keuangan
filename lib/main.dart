import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:skripsi_keuangan/app.dart';
import 'package:skripsi_keuangan/services/gemini_service.dart';
import 'firebase_options.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

//GLOBAL
final messengerKey = GlobalKey<ScaffoldMessengerState>();
bool splashActive = true;

//MAIN
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GeminiService.initialize();
  runApp(const RootApp());
}

//ROOT APP
class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  late StreamSubscription<List<ConnectivityResult>> _sub;
  bool isConnected = true;

  bool _showOnlineAnim = false;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  //CEK KONEKSI
  void _initConnection() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnection(result);

    _sub = Connectivity().onConnectivityChanged.listen(_updateConnection);
  }

  void _updateConnection(List<ConnectivityResult> result) {
    final nowConnected = !result.contains(ConnectivityResult.none);

    if (nowConnected == isConnected) return;

    setState(() {
      isConnected = nowConnected;

      // Memberi Waktu Animasi Terhubung
      if (nowConnected) {
        _showOnlineAnim = true;

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _showOnlineAnim = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  //WIDGET UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,

      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(scaffoldBackgroundColor: white),

      builder: (context, child) {
        return Stack(
          children: [
            child!,

            // ================= OFFLINE =================
            AnimatedOpacity(
              opacity: isConnected ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: isConnected,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          "images/animasiinternet.json",
                          width: 350,
                          height: 350,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ================= ONLINE =================
            if (_showOnlineAnim)
              Positioned(
                top: 300,
                left: 0,
                right: 0,
                child: Center(
                  child: Lottie.asset(
                    "images/internet.json",
                    width: 350,
                    height: 350,
                  ),
                ),
              ),
          ],
        );
      },

      home: const AppScreen(),
    );
  }
}
