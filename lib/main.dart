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
import 'package:skripsi_keuangan/ui.dart';

import 'firebase_options.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// GLOBAL
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GLOBAL FLUTTER ERROR HANDLER
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("Flutter Error: ${details.exception}");
  };

  await initializeDateFormatting('id_ID', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await GeminiService.initialize();

  // NOTIFICATION ONLY
  await NotificationService.init();

  // GLOBAL ASYNC ERROR HANDLER
  runZonedGuarded(
    () {
      runApp(const RootApp());
    },
    (error, stack) {
      debugPrint("Global Error: $error");
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

  // INIT CONNECTION
  void _initConnection() async {
    final result = await Connectivity().checkConnectivity();
    await _updateConnection(result);

    _sub = Connectivity().onConnectivityChanged.listen((result) async {
      await _updateConnection(result);
    });
  }

  // UPDATE CONNECTION (REAL INTERNET CHECK)
  Future<void> _updateConnection(List<ConnectivityResult> result) async {
    bool hasInternet = false;

    // Jika tidak ada jaringan sama sekali
    if (result.contains(ConnectivityResult.none)) {
      hasInternet = false;
    } else {
      // Jika ada jaringan, cek internet asli
      hasInternet = await InternetConnectionChecker().hasConnection;
    }

    if (hasInternet == isConnected) return;

    if (!mounted) return;

    setState(() {
      isConnected = hasInternet;

      if (hasInternet) {
        _showOnlineAnim = true;
      }
    });

    // Hilangkan animasi online setelah 3 detik
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

      scaffoldMessengerKey: messengerKey,

      navigatorKey: NotificationService.navigatorKey,

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
                      "images/animasiinternet.json",
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
                    "images/internet.json",
                    width: 350,
                    height: 350,
                    repeat: false,
                  ),
                ),
              ),
          ],
        );
      },

      home: const SplashScreen(),
    );
  }
}
