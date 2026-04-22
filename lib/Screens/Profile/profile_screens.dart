// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skripsi_keuangan/Screens/Profile/Bank/bank_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Edit%20Profile/edit_profile_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Kategori/kategori_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Komentar/komentar_screens.dart';
import 'package:skripsi_keuangan/Screens/auth/login_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';

class ProfileScreens extends StatefulWidget {
  const ProfileScreens({super.key});

  @override
  State<ProfileScreens> createState() => _ProfileScreensState();
}

class _ProfileScreensState extends State<ProfileScreens> {
  User? user = FirebaseAuth.instance.currentUser;

  String? fotoImageName;
  File? fotoImageFile;

  // huruf depan jadi besar
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  //logout paksa kalau user hilang
  void _forceLogout() {
    FirebaseAuth.instance.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreens()),
      (route) => false,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Sesi habis, login ulang")));
  }

  // AMBIL DATA
  Future<void> _refreshData() async {
    try {
      await user?.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseAuthException(code: 'user-token-expired');
      }

      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(user!.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        fotoImageName = doc.data()?['foto'];

        if (fotoImageName != null) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$fotoImageName');

          if (await file.exists()) {
            setState(() => fotoImageFile = file);
          } else {
            setState(() => fotoImageFile = null);
          }
        } else {
          setState(() => fotoImageFile = null);
        }
      }

      // PAKSA REFRESH UI
      setState(() {});
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-token-expired') {
        _forceLogout();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: rednotif,
          content: Center(child: Text("Gagal memuat data", style: whiteBold)),
        ),
      );
    }
  }

  // HAPUS AKUN
  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    // popup konfirmasi
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: red,
        title: Text("Konfirmasi Hapus Akun?", style: whiteBold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Masukkan password untuk konfirmasi hapus akun:",
              style: whiteReguler,
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: white, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: TextField(
                  controller: passwordController,
                  style: whiteReguler,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Masukan Password',
                    hintStyle: greyReguler,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("BATAL", style: whiteReguler),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("IYA", style: greenBold12),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // kalau password kosong
      if (passwordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: rednotif,
            content: Center(
              child: Text("Password wajib diisi", style: whiteBold),
            ),
          ),
        );
        return;
      }

      try {
        User? currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null && currentUser.email != null) {
          // login ulang (biar bisa hapus akun)
          AuthCredential credential = EmailAuthProvider.credential(
            email: currentUser.email!,
            password: passwordController.text.trim(),
          );

          await currentUser.reauthenticateWithCredential(credential);

          // hapus data di Firestore
          await FirebaseFirestore.instance
              .collection('user')
              .doc(currentUser.uid)
              .delete();

          // hapus akun di Firebase Auth
          await currentUser.delete();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: greennotif,
              content: Center(
                child: Text("Akun berhasil dihapus", style: whiteBold),
              ),
            ),
          );

          // kembali ke login
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreens()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: rednotif,
            content: Center(child: Text("Gagal hapus akun", style: whiteBold)),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreens()),
        );
      });
    } else {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayNama = user?.displayName ?? 'User';

    String nama = displayNama.contains('|')
        ? displayNama.split('|')[0]
        : displayNama;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 30,
                bottom: 20,
              ),
              child: Column(
                children: [
                  profileimage(context, nama),
                  const SizedBox(height: 30),
                  buttonBody(),
                  const SizedBox(height: 80),
                  butonLogout(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // PROFILE
  Widget profileimage(BuildContext context, String nama) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Updatescreen()),
        );

        //REFRESH LANGSUNG DATA
        await _refreshData();
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: red,
            backgroundImage: fotoImageFile != null
                ? FileImage(fotoImageFile!)
                : null,
            child: fotoImageFile == null
                ? Icon(Icons.person, size: 50, color: white)
                : null,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(capitalize(nama), style: blackBold),
              Text(user?.email ?? 'email', style: blackReguler12),
            ],
          ),
          const Spacer(),
          Icon(Icons.edit_outlined, size: 20, color: black),
        ],
      ),
    );
  }

  // BUTTON
  Widget buttonBody() {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BankScreens()),
            );
          },
          child: _buildButton(Icons.account_balance, 'Tambah Bank'),
        ),
        const SizedBox(height: 30),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => KategoriScreens()),
            );
          },
          child: _buildButton(Icons.table_chart, 'Tambah Kategori'),
        ),
        const SizedBox(height: 30),
        _buildButton(Icons.download, 'Unduh Laporan'),
        const SizedBox(height: 30),
        _buildButton(Icons.perm_device_info, 'Tentang Aplikasi'),
        const SizedBox(height: 30),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => KomentarScreens()),
            );
          },
          child: _buildButton(Icons.help_outline, 'Komentar'),
        ),
        const SizedBox(height: 30),
        InkWell(
          onTap: _deleteAccount,
          child: _buildButton(Icons.delete, 'Hapus Akun'),
        ),
      ],
    );
  }

  Widget _buildButton(IconData icon, String text) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: black),
          const SizedBox(width: 20),
          Text(text, style: blackReguler),
          const Spacer(),
          Icon(Icons.arrow_right_rounded, size: 20, color: black),
        ],
      ),
    );
  }

  // LOGOUT
  Widget butonLogout() {
    return GestureDetector(
      onTap: () async {
        await AuthService().signOut();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreens()),
          (route) => false,
        );
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20, color: white),
            const SizedBox(width: 10),
            Text('Logout', style: whiteBold),
          ],
        ),
      ),
    );
  }
}
