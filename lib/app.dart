import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skripsi_keuangan/Screens/home_screens.dart';
import 'package:skripsi_keuangan/Screens/login_screens.dart';
import 'package:skripsi_keuangan/navigation/bottom_navigation.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: AuthService().userChanges,
          initialData: null,
        ),
      ],
      child: Consumer<User?>(
        builder: (context, user, _) {
          // tampilkan splash dulu
          return FutureBuilder(
            future: Future.delayed(const Duration(seconds: 2)),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SplashScreen();
              } else {
                if (user == null) {
                  return const LoginScreens();
                } else {
                  return const HomeScreens();
                }
              }
            },
          );
        },
      ),
    );
  }
}
