import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lottie/lottie.dart';
import 'package:skripsi_keuangan/Screens/SplashScreen/splash_screen.dart';
import 'package:skripsi_keuangan/services/gemini_service.dart';
import 'package:skripsi_keuangan/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// GLOBAL
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  runZonedGuarded(
    () async {
      // WAJIB DALAM ZONA YANG SAMA
      WidgetsFlutterBinding.ensureInitialized();

      // GLOBAL FLUTTER ERROR HANDLER
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint("Flutter Error: ${details.exception}");
      };

      // FORMAT TANGGAL INDONESIA
      await initializeDateFormatting('id_ID', null);

      // FIREBASE
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // GEMINI AI
      await GeminiService.initialize();

      // NOTIFIKASI
      await NotificationService.init();

      // JALANKAN APP
      runApp(const RootApp());
    },
    (error, stack) {
      // GLOBAL ASYNC ERROR HANDLER
      debugPrint("Global Error: $error");
      debugPrint("Stack Trace: $stack");
    },
  );
}

// ROOT APP
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

  // ==========================
  // INIT CONNECTION
  // ==========================
  void _initConnection() async {
    final result = await Connectivity().checkConnectivity();

    await _updateConnection(result);

    _sub = Connectivity().onConnectivityChanged.listen((result) async {
      await _updateConnection(result);
    });
  }

  // ==========================
  // UPDATE INTERNET STATUS
  // ==========================
  Future<void> _updateConnection(List<ConnectivityResult> result) async {
    bool hasInternet = false;

    // Tidak ada jaringan
    if (result.contains(ConnectivityResult.none)) {
      hasInternet = false;
    } else {
      // Ada jaringan → cek internet asli
      hasInternet = await InternetConnectionChecker().hasConnection;
    }

    // Jika status sama, abaikan
    if (hasInternet == isConnected) return;

    if (!mounted) return;

    setState(() {
      isConnected = hasInternet;

      if (hasInternet) {
        _showOnlineAnim = true;
      }
    });

    // Sembunyikan animasi online
    if (hasInternet) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showOnlineAnim = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Global snackbar
      scaffoldMessengerKey: messengerKey,

      // Navigator notifikasi
      navigatorKey: NotificationService.navigatorKey,

      // Bahasa
      locale: const Locale('id', 'ID'),

      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Theme
      theme: ThemeData(scaffoldBackgroundColor: white),

      // BUILDER INTERNET OVERLAY
      builder: (context, child) {
        return Stack(
          children: [
            child!,

            // OFFLINE SCREEN
            AnimatedOpacity(
              opacity: isConnected ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: isConnected,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Lottie.asset(
                      "Images/animasiinternet.json",
                      width: 350,
                      height: 350,
                      repeat: true,
                    ),
                  ),
                ),
              ),
            ),

            // ONLINE SCREEN
            if (_showOnlineAnim)
              Positioned(
                top: 300,
                left: 0,
                right: 0,
                child: Center(
                  child: Lottie.asset(
                    "Images/internet.json",
                    width: 350,
                    height: 350,
                    repeat: false,
                  ),
                ),
              ),
          ],
        );
      },

      // HOME
      home: const SplashScreen(),
    );
  }
}
