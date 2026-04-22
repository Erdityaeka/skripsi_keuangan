import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:skripsi_keuangan/app.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

//GLOBAL
final messengerKey = GlobalKey<ScaffoldMessengerState>();
bool splashActive = true;

//MAIN
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  bool _snackLock = false;

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

    setState(() => isConnected = nowConnected);

    _showSnackBar(
      nowConnected ? "Internet terhubung" : "Tidak ada koneksi internet",
      nowConnected ? greennotif : rednotif,
    );
  }

  //SNACKBAR
  void _showSnackBar(String msg, Color color) {
    if (!mounted || _snackLock || splashActive) return;

    _snackLock = true;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Center(child: Text(msg, style: whiteBold)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      _snackLock = false;
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
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      builder: (context, child) {
        return Stack(
          children: [
            child!,

            //LOADING SAAT TIDAK ADA INTERNET
            AnimatedOpacity(
              opacity: isConnected ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: isConnected,
                child: Container(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: white),
                        const SizedBox(height: 12),
                        Text(
                          "Menunggu koneksi...",
                          style: whiteReguler.copyWith(
                            decoration: TextDecoration.none,
                          ),
                          // tanpa garis
                        ),
                      ],
                    ),
                  ),
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
