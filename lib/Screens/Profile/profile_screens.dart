import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skripsi_keuangan/Screens/Profile/Bank/bank_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Edit%20Profile/edit_profile_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Kategori/kategori_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Komentar/komentar_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Laporan/unduh_laporan_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Tentang/tentang_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/scan/scan_struk_screeen.dart';
import 'package:skripsi_keuangan/Screens/auth/login_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';

class ProfileScreens extends StatefulWidget {
  const ProfileScreens({super.key});

  @override
  State<ProfileScreens> createState() => _ProfileScreensState();
}

class _ProfileScreensState extends State<ProfileScreens> {
  // User aktif
  User? user = FirebaseAuth.instance.currentUser;

  // Foto profile
  String? fotoImageName;
  File? fotoImageFile;

  // Posisi foto
  double _yPosisi = 0.0;

  @override
  void initState() {
    super.initState();

    // Load data awal
    _refreshData();
  }

  // Huruf awal kapital
  String capitalize(String text) {
    if (text.isEmpty) return text;

    return text[0].toUpperCase() + text.substring(1);
  }

  // Notifikasi aman
  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: success ? greennotif : rednotif,
          content: Center(
            child: Text(msg, style: whiteBold, textAlign: TextAlign.center),
          ),
        ),
      );
  }

  // Refresh data user
  Future<void> _refreshData() async {
    try {
      user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(user!.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final dataFoto = doc.data()?['foto'];

        // Format baru foto|posisi
        if (dataFoto != null && dataFoto.contains('|')) {
          final parts = dataFoto.split('|');

          fotoImageName = parts[0];

          _yPosisi = double.tryParse(parts[1]) ?? 0.0;

          final dir = await getApplicationDocumentsDirectory();

          final file = File('${dir.path}/$fotoImageName');

          fotoImageFile = await file.exists() ? file : null;
        } else {
          // Format lama
          fotoImageName = dataFoto;
          _yPosisi = 0.0;
          fotoImageFile = null;
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showSnack("Gagal memuat data");
    }
  }

  // Hapus akun
  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    try {
      final confirm = await showDialog<bool>(
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
                  padding: const EdgeInsets.all(14),
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

      if (confirm != true) return;

      if (passwordController.text.trim().isEmpty) {
        _showSnack("Password wajib diisi");
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null || currentUser.email == null) {
        _showSnack("User tidak ditemukan");
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: passwordController.text.trim(),
      );

      // Re-auth
      await currentUser.reauthenticateWithCredential(credential);

      // Hapus Firestore
      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUser.uid)
          .delete();

      // Hapus Auth
      await currentUser.delete();

      if (!mounted) return;

      _showSnack("Akun berhasil dihapus", success: true);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreens()),
        (route) => false,
      );
    } catch (e) {
      _showSnack("Gagal hapus akun");
    } finally {
      passwordController.dispose();
    }
  }

  // Build tombol menu reusable
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

  // Profile section
  Widget profileimage(BuildContext context, String nama) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Updatescreen()),
        );

        await _refreshData();
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: red,
            child: ClipOval(
              child: SizedBox.expand(
                child: fotoImageFile != null
                    ? Image.file(
                        fotoImageFile!,
                        fit: BoxFit.cover,
                        alignment: Alignment(0, _yPosisi),
                      )
                    : Icon(Icons.person, size: 50, color: white),
              ),
            ),
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

  // Menu body
  Widget buttonBody() {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BankScreens()),
          ),
          child: _buildButton(Icons.account_balance, 'Tambah Bank'),
        ),

        const SizedBox(height: 30),

        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const KategoriScreens()),
          ),
          child: _buildButton(Icons.table_chart, 'Tambah Kategori'),
        ),

        const SizedBox(height: 30),

        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UnduhLaporanScreens(),
            ),
          ),
          child: _buildButton(Icons.download, 'Unduh Laporan'),
        ),

        const SizedBox(height: 30),

        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanStrukScreen()),
          ),
          child: _buildButton(Icons.qr_code_scanner, 'Scan'),
        ),

        const SizedBox(height: 30),

        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TentangScreens()),
          ),
          child: _buildButton(Icons.perm_device_info, 'Tentang Aplikasi'),
        ),

        const SizedBox(height: 30),

        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const KomentarScreens()),
          ),
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

  // Logout button
  Widget butonLogout() {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: red,
            title: Text("Logout", style: whiteBold),
            content: Text("Apakah yakin ingin logout?", style: whiteReguler),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("BATAL", style: whiteBold),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("IYA", style: greenBold15),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        try {
          await AuthService().signOut();

          if (!mounted) return;

          _showSnack("Berhasil logout", success: true);

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreens()),
            (route) => false,
          );
        } catch (e) {
          _showSnack("Gagal logout");
        }
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
}
