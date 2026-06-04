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
import 'package:skripsi_keuangan/Screens/Profile/Scan/scan_struk_screeen.dart';
import 'package:skripsi_keuangan/Screens/Profile/Tagihan/tagihan_screens.dart';
import 'package:skripsi_keuangan/Screens/auth/login_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class ProfileScreens extends StatefulWidget {
  const ProfileScreens({super.key});

  @override
  State<ProfileScreens> createState() => _ProfileScreensState();
}

class _ProfileScreensState extends State<ProfileScreens> {
  User? user = FirebaseAuth.instance.currentUser;
  final FirestoreService firestore = FirestoreService();

  String? fotoImageName;
  File? fotoImageFile;
  double _yPosisi = 0.0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: success ? greennotif : rednotif,
          content: Center(
            child: Text(msg, style: putihBold15, textAlign: TextAlign.center),
          ),
        ),
      );
  }

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

        if (dataFoto != null && dataFoto.contains('|')) {
          final parts = dataFoto.split('|');
          fotoImageName = parts[0];
          _yPosisi = double.tryParse(parts[1]) ?? 0.0;

          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/$fotoImageName');
          fotoImageFile = await file.exists() ? file : null;
        } else {
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

  // FUNGSI HAPUS AKUN
  Future<void> _deleteAccount() async {
    bool? confirm = false;
    String inputPassword = '';

    try {
      confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          // Solusi utama: Jadikan controller ini lokal di dalam builder dialog
          final localController = TextEditingController();

          return AlertDialog(
            backgroundColor: putih,
            title: Text("Konfirmasi Hapus Akun?", style: hitamBold15),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Masukkan password untuk konfirmasi hapus akun:",
                  style: teksdialogBold15,
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    border: Border.all(color: hijauSimpan, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: TextField(
                      controller: localController,
                      style: hitamReguler15,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Masukan Password',
                        hintStyle: abuReguler15,
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
                child: Text("BATAL", style: dialogBatalBold15),
              ),
              Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  color: merahHapus,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    if (localController.text.trim().isEmpty) {
                      _showSnack("Password wajib diisi");
                      return;
                    }
                    // Ambil nilainya ke variabel String sebelum dialog ditutup
                    inputPassword = localController.text.trim();
                    Navigator.pop(ctx, true);
                  },
                  child: Text("Hapus", style: putihBold15),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.email == null) {
        _showSnack("User tidak ditemukan");
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: inputPassword,
      );

      await currentUser.reauthenticateWithCredential(credential);

      await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUser.uid)
          .delete();

      await currentUser.delete();

      if (!mounted) return;

      _showSnack("Akun berhasil dihapus", success: true);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreens()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showSnack("Password salah");
      } else {
        _showSnack("Gagal hapus akun");
      }
    } catch (e) {
      _showSnack("Gagal hapus akun");
    }
  }

  Widget _buildButton(IconData icon, String text, {int badgeCount = 0}) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: putih,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 20, color: hitam),
              if (badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: rednotif,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text('$badgeCount', style: putihBold10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Text(text, style: hitamReguler15),
          const Spacer(),
          Icon(Icons.arrow_right_rounded, size: 20, color: hitam),
        ],
      ),
    );
  }

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
            backgroundColor: hijauMedium,
            child: ClipOval(
              child: SizedBox.expand(
                child: fotoImageFile != null
                    ? Image.file(
                        fotoImageFile!,
                        fit: BoxFit.cover,
                        alignment: Alignment(0, _yPosisi),
                      )
                    : Icon(Icons.person, size: 50, color: hitam),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capitalize(nama),
                  style: hitamBold15,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  user?.email ?? 'email',
                  style: hitamReguler12,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.edit_outlined, size: 20, color: hitam),
        ],
      ),
    );
  }

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
        StreamBuilder<int>(
          stream: firestore.getJumlahTagihanPenting(),
          builder: (context, snapshot) {
            final jumlah = snapshot.data ?? 0;
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TagihanScreens()),
              ),
              child: _buildButton(
                Icons.receipt_long,
                'Tagihan',
                badgeCount: jumlah,
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanStrukScreen()),
          ),
          child: _buildButton(Icons.qr_code_scanner, 'Scan Struk'),
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

  Widget butonLogout() {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: putih,
            title: Text("Logout?", style: hitamBold20),
            content: Text(
              "Apakah yakin ingin log out?",
              style: teksdialogBold15,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("BATAL", style: dialogBatalBold15),
              ),
              Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  color: merahHapus,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("IYA", style: putihBold15),
                ),
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
          color: hijauSimpan,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20, color: putih),
            const SizedBox(width: 10),
            Text('Logout', style: putihBold15),
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
