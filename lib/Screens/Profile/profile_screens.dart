// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skripsi_keuangan/Screens/Profile/Bank/bank_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Edit%20Profile/update.dart';
import 'package:skripsi_keuangan/Screens/Profile/Kategori/kategori_screens.dart';
import 'package:skripsi_keuangan/Screens/auth/login_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';

class ProfileScreens extends StatefulWidget {
  const ProfileScreens({super.key});

  @override
  State<ProfileScreens> createState() => _ProfileScreensState();
}

class _ProfileScreensState extends State<ProfileScreens> {
  // ambil user yang sedang login
  User? user = FirebaseAuth.instance.currentUser;

  // nama file foto
  String? fotoImageName;

  // file foto di HP
  File? fotoImageFile;

  // fungsi buat huruf pertama jadi besar
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // ================= LOGOUT PAKSA =================
  void _forceLogout() {
    FirebaseAuth.instance.signOut(); // logout user

    // pindah ke halaman login dan hapus semua halaman sebelumnya
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreens()),
      (route) => false,
    );

    // tampilkan pesan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sesi habis, silakan login ulang")),
    );
  }

  // ================= AMBIL DATA USER =================
  Future<void> _refreshData() async {
    try {
      // ambil ulang data user dari Firebase Auth
      await user?.reload();

      // update user terbaru
      user = FirebaseAuth.instance.currentUser;

      // kalau user tidak ada → paksa logout
      if (user == null) {
        throw FirebaseAuthException(code: 'user-token-expired');
      }

      // ambil data dari Firestore
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(user!.uid)
          .get();

      // kalau widget sudah tidak ada → hentikan
      if (!mounted) return;

      // kalau data ada
      if (doc.exists) {
        // ambil nama file foto
        fotoImageName = doc.data()?['foto'];

        if (fotoImageName != null) {
          // ambil folder aplikasi
          final appDir = await getApplicationDocumentsDirectory();

          // buat path file
          final file = File('${appDir.path}/$fotoImageName');

          // cek file ada atau tidak
          if (await file.exists()) {
            if (mounted) setState(() => fotoImageFile = file);
          } else {
            if (mounted) setState(() => fotoImageFile = null);
          }
        } else {
          if (mounted) setState(() => fotoImageFile = null);
        }
      }

      // refresh tampilan
      if (mounted) setState(() {});
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-token-expired') {
        _forceLogout();
      }
    } catch (e) {
      // kalau error tampilkan pesan
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal memuat data")));
      }
    }
  }

  // ================= HAPUS AKUN =================
  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    // popup konfirmasi
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: red,
        title: Text("Konfirmasi Hapus Akun", style: whiteBold),
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
            child: Text("HAPUS", style: greenBold12),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // kalau password kosong
      if (passwordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: rednotfif,
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
              backgroundColor: greenblack,
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
            backgroundColor: rednotfif,
            content: Center(child: Text("Gagal hapus akun", style: whiteBold)),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // cek user login atau tidak
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreens()),
        );
      });
    } else {
      _refreshData(); // ambil data saat pertama buka
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayNama = user?.displayName ?? 'User';

    // ambil nama sebelum tanda |
    String nama = displayNama.contains('|')
        ? displayNama.split('|')[0]
        : displayNama;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData, // tarik ke bawah → refresh
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(), // wajib untuk refresh
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
                  butonHapusAkun(),
                  const SizedBox(height: 30),
                  butonLogout(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Gambar
  Widget profileimage(BuildContext context, String nama) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Updatescreen()),
        );
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
        _buildButton(Icons.help_outline, 'Bantuan dan Masukan'),
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

  Widget butonHapusAkun() {
    return GestureDetector(
      onTap: _deleteAccount,
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
            Icon(Icons.delete, size: 20, color: white),
            const SizedBox(width: 10),
            Text('Hapus Akun', style: whiteBold),
          ],
        ),
      ),
    );
  }
}
