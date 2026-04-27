import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skripsi_keuangan/Screens/auth/login_screens.dart';
import 'package:skripsi_keuangan/navigation/bottom_navigation.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  Future<bool> _checkUserExists(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: AuthService().userChanges,
          initialData: FirebaseAuth.instance.currentUser,
        ),
      ],
      child: Consumer<User?>(
        builder: (context, user, _) {
          if (user == null) {
            return const LoginScreens();
          }

          // Cek Firestore apakah akun masih ada
          return FutureBuilder<bool>(
            future: _checkUserExists(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data == false) {
                // Logout paksa jika akun dihapus
                Future.microtask(() async {
                  await FirebaseAuth.instance.signOut();
                });
                return const LoginScreens();
              }

              // Jika akun valid masuk ke halaman utama
              return const BottomNavigation();
            },
          );
        },
      ),
    );
  }
}
