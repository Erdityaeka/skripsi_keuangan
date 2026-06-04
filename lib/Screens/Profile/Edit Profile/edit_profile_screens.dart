import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skripsi_keuangan/Screens/auth/login_screens.dart';

import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';

class Updatescreen extends StatefulWidget {
  const Updatescreen({super.key});

  @override
  State<Updatescreen> createState() => _UpdatescreenState();
}

class _UpdatescreenState extends State<Updatescreen> {
  // Controller input
  final namaC = TextEditingController();
  final emailC = TextEditingController();
  final passwordC = TextEditingController();

  // Status aplikasi
  bool pickingImage = false;
  bool _isPasswordVisible = false;
  bool loading = false;

  // Posisi foto profile
  double _posisifoto = 0.0;

  // Data user
  User? user = FirebaseAuth.instance.currentUser;
  File? fotoLama;
  XFile? fotoBaru;

  @override
  void initState() {
    super.initState();

    // Ambil nama dari Firebase Auth
    if (user?.displayName != null) {
      final data = user!.displayName!.split('|');
      namaC.text = data[0];
    }

    // Ambil email
    emailC.text = user?.email ?? "";

    // Load foto profile
    loadFoto();
  }

  @override
  void dispose() {
    // Hindari memory leak
    namaC.dispose();
    emailC.dispose();
    passwordC.dispose();
    super.dispose();
  }

  Future<void> loadFoto() async {
    try {
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(user!.uid)
          .get();

      final dataFoto = doc.data()?['foto'];

      if (dataFoto != null && dataFoto.contains('|')) {
        final parts = dataFoto.split('|');

        // Simpan posisi slider
        _posisifoto = double.tryParse(parts[1]) ?? 0.0;

        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/${parts[0]}');

        // Cek file ada
        if (await file.exists() && mounted) {
          setState(() => fotoLama = file);
        }
      }
    } catch (e) {
      notif("Gagal load foto");
    }
  }

  Future<void> pilihFoto() async {
    // Hindari klik berulang
    if (pickingImage) return;

    pickingImage = true;

    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (img != null && mounted) {
        setState(() {
          fotoBaru = img;
          _posisifoto = 0.0;
        });
      }
    } catch (e) {
      notif("Gagal memilih foto");
    } finally {
      pickingImage = false;
    }
  }

  Future<void> hapusFoto() async {
    try {
      if (user == null) return;

      // Hapus dari Firestore
      await FirebaseFirestore.instance.collection('user').doc(user!.uid).update(
        {'foto': null},
      );

      if (!mounted) return;

      setState(() {
        fotoLama = null;
        fotoBaru = null;
        _posisifoto = 0.0;
      });

      notif("Foto berhasil dihapus", success: true);
    } catch (e) {
      notif("Gagal hapus foto");
    }
  }

  Future<void> simpan() async {
    // Validasi input
    if (namaC.text.trim().isEmpty) {
      return notif("Nama harus diisi");
    }

    if (emailC.text.trim().isEmpty) {
      return notif("Email harus diisi");
    }

    // TAMBAHAN VALIDASI PASSWORD
    if (emailC.text.trim() != user?.email && passwordC.text.trim().isEmpty) {
      return notif("Password wajib diisi untuk ganti email");
    }

    if (user == null) {
      return notif("User tidak ditemukan");
    }

    setState(() => loading = true);

    String? finalFotoString;

    try {
      // Jika foto baru dipilih
      if (fotoBaru != null) {
        final dir = await getApplicationDocumentsDirectory();

        await File(fotoBaru!.path).copy('${dir.path}/${fotoBaru!.name}');

        finalFotoString = "${fotoBaru!.name}|$_posisifoto";
      }
      // Jika pakai foto lama
      else if (fotoLama != null) {
        finalFotoString = "${fotoLama!.path.split('/').last}|$_posisifoto";
      }

      // Simpan ke Firestore
      await FirebaseFirestore.instance.collection('user').doc(user!.uid).set({
        'foto': finalFotoString,
        'nama': namaC.text.trim(),
      }, SetOptions(merge: true));

      // Update Auth
      final res = await AuthService().updateProfile(
        newName: namaC.text.trim(),
        newfotoFileName: finalFotoString,
        newEmail: emailC.text.trim(),
        currentPassword: passwordC.text.trim(),
      );

      const successEmailMessage =
          "Cek email baru di alamat email untuk konfirmasi perubahan";

      // Jika email berubah atau password salah
      if (res != null && res != successEmailMessage) {
        notif(res);
        return;
      }

      // Jika berhasil request ganti email
      if (res == successEmailMessage) {
        notif("Cek email baru untuk verifikasi", success: true);

        // Tunggu snackbar tampil
        await Future.delayed(const Duration(seconds: 2));

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreens()),
          (route) => false,
        );

        return;
      }

      // Jika hanya nama/foto
      notif("Profile berhasil diperbarui", success: true);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      notif("Terjadi kesalahan Update");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void notif(String msg, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Center(
            child: Text(msg, style: putihBold15, textAlign: TextAlign.center),
          ),
          backgroundColor: success ? greennotif : rednotif,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _builAppbar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            image(),
            const SizedBox(height: 20),
            input(),
            const SizedBox(height: 25),
            buttonHapus(),
            const SizedBox(height: 15),
            buttonSimpan(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _builAppbar() {
    return AppBar(
      backgroundColor: putih,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: hitam),
      ),
      title: Text('Edit Profile', style: hitamBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  Widget image() {
    return Column(
      children: [
        GestureDetector(
          onTap: pilihFoto,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: hijauMedium,
            child: ClipOval(
              child: SizedBox.expand(
                child: fotoBaru != null
                    ? Image.file(
                        File(fotoBaru!.path),
                        fit: BoxFit.cover,
                        alignment: Alignment(0, _posisifoto),
                      )
                    : (fotoLama != null
                          ? Image.file(
                              fotoLama!,
                              fit: BoxFit.cover,
                              alignment: Alignment(0, _posisifoto),
                            )
                          : Icon(Icons.person, size: 50, color: hitam)),
              ),
            ),
          ),
        ),

        // Slider posisi foto
        if (fotoBaru != null || fotoLama != null) ...[
          Slider(
            value: _posisifoto,
            min: -1.0,
            max: 1.0,
            activeColor: hijauSimpan,
            inactiveColor: abu,
            onChanged: (val) {
              if (!mounted) return;
              setState(() => _posisifoto = val);
            },
          ),
        ],
      ],
    );
  }

  Widget input() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input Nama
        Text('Nama', style: hitamReguler15),
        const SizedBox(height: 10),
        Container(
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.person, color: abu),
              ),
              Expanded(
                child: TextField(
                  controller: namaC,
                  decoration: InputDecoration(
                    hintText: 'Nama',
                    border: InputBorder.none,
                    hintStyle: abuReguler15,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // Input Email
        Text('Email', style: hitamReguler15),
        const SizedBox(height: 10),
        Container(
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.email, color: abu),
              ),
              Expanded(
                child: TextField(
                  controller: emailC,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: InputBorder.none,
                    hintStyle: abuReguler15,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // Input Password
        Text('Password Lama', style: hitamReguler15),
        const SizedBox(height: 10),
        Container(
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.lock, color: abu),
              ),
              Expanded(
                child: TextField(
                  controller: passwordC,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Masukan Password Lama',
                    border: InputBorder.none,
                    hintStyle: abuReguler15,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (!mounted) return;
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: hitam,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buttonHapus() {
    return ElevatedButton(
      onPressed: (fotoBaru != null || fotoLama != null) ? hapusFoto : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: merahHapus,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text("HAPUS FOTO PROFIL", style: putihBold15),
    );
  }

  Widget buttonSimpan() {
    return ElevatedButton(
      onPressed: loading ? null : simpan,
      style: ElevatedButton.styleFrom(
        backgroundColor: hijauSimpan,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: loading
          ? CircularProgressIndicator(color: putih)
          : Text("SIMPAN", style: putihBold15),
    );
  }
}
