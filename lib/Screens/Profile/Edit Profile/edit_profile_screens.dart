import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skripsi_keuangan/Screens/auth/login_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';

class Updatescreen extends StatefulWidget {
  const Updatescreen({super.key});

  @override
  State<Updatescreen> createState() => _UpdatescreenState();
}

class _UpdatescreenState extends State<Updatescreen> {
  final namaC = TextEditingController();
  final emailC = TextEditingController();
  final passwordC = TextEditingController();
  bool pickingImage = false;
  bool _isPasswordVisible = false;

  bool loading = false;

  User? user = FirebaseAuth.instance.currentUser;

  File? fotoLama;
  XFile? fotoBaru;

  @override
  void initState() {
    super.initState();

    if (user?.displayName != null) {
      final data = user!.displayName!.split('|');
      namaC.text = data[0];
    }

    emailC.text = user?.email ?? "";
    loadFoto();
  }

  // ================= LOAD FOTO =================
  Future<void> loadFoto() async {
    try {
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user') // ✅ FIX DI SINI
          .doc(user!.uid)
          .get();

      if (!mounted) return;

      final namaFile = doc.data()?['foto'];

      if (namaFile != null) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$namaFile');

        if (await file.exists()) {
          setState(() => fotoLama = file);
        }
      }
    } catch (e) {
      notif("Gagal load foto");
    }
  }

  // ================= PILIH FOTO =================
  Future<void> pilihFoto() async {
    // 🔥 cegah double klik
    if (pickingImage) return;

    pickingImage = true;

    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (img != null && mounted) {
        setState(() => fotoBaru = img);
      }
    } catch (e) {
      print("Error picker: $e");
    } finally {
      pickingImage = false; // 🔓 buka lagi
    }
  }

  // ================= SIMPAN =================
  Future<void> simpan() async {
    if (namaC.text.trim().isEmpty) {
      notif("Nama harus diisi");
      return;
    }

    if (emailC.text.trim() != user?.email && passwordC.text.trim().isEmpty) {
      notif("Masukkan password untuk mengganti email");
      return;
    }

    setState(() => loading = true);

    String? namaFile;

    try {
      // ================= SIMPAN FOTO =================
      if (fotoBaru != null) {
        final dir = await getApplicationDocumentsDirectory();
        final pathBaru = '${dir.path}/${fotoBaru!.name}';

        final file = File(fotoBaru!.path);

        if (await file.exists()) {
          await file.copy(pathBaru);
          namaFile = fotoBaru!.name;

          await FirebaseFirestore.instance
              .collection('user') // ✅ FIX
              .doc(user!.uid)
              .set({'foto': namaFile}, SetOptions(merge: true));
        }
      }

      // ================= UPDATE AUTH =================
      final res = await AuthService().updateProfile(
        newName: namaC.text.trim(),
        newfotoFileName: namaFile,
        newEmail: emailC.text.trim(),
        currentPassword: passwordC.text.trim(),
      );

      setState(() => loading = false);

      // ================= JIKA EMAIL BERUBAH =================
      if (emailC.text.trim() != user?.email) {
        notif("Cek email baru untuk verifikasi");

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreens()),
          (route) => false,
        );
        return;
      }

      // ================= NORMAL =================
      if (res == null) {
        notif("Profile berhasil diperbarui", success: true);
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } else {
        notif(res);
      }
    } catch (e) {
      setState(() => loading = false);
      notif("Terjadi kesalahan Update");
    }
  }

  // ================= HAPUS FOTO =================
  Future<void> hapusFoto() async {
    try {
      await FirebaseFirestore.instance.collection('user').doc(user!.uid).set({
        'foto': null,
      }, SetOptions(merge: true));

      if (fotoLama != null && await fotoLama!.exists()) {
        await fotoLama!.delete();
      }

      setState(() {
        fotoLama = null;
        fotoBaru = null;
      });

      notif("Foto berhasil dihapus", success: true);
    } catch (e) {
      notif("Gagal hapus foto");
    }
  }

  // ================= NOTIF =================
  void notif(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(msg, style: whiteBold)),
        backgroundColor: success ? greenblack : redblack,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: red),
        ),
        title: Text('Edit Profile', style: redBold20),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: pilihFoto,
              child: Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: red,
                  backgroundImage: fotoBaru != null
                      ? FileImage(File(fotoBaru!.path))
                      : (fotoLama != null ? FileImage(fotoLama!) : null),
                  child: (fotoBaru == null && fotoLama == null)
                      ? Icon(Icons.person, size: 50, color: white)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text('Nama', style: blackReguler),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: red, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: TextField(
                  controller: namaC,

                  decoration: InputDecoration(
                    icon: Icon(Icons.person_outline, color: greyReguler.color),
                    hintText: 'Masukan Nama',
                    hintStyle: greyReguler,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text('Email Address', style: blackReguler),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: red, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: TextField(
                  controller: emailC,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    icon: Icon(
                      Icons.mark_email_unread_rounded,
                      color: greyReguler.color,
                    ),
                    hintText: 'Masukan Email',
                    hintStyle: greyReguler,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Password', style: blackReguler),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: red, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: TextField(
                  controller: passwordC,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    icon: Icon(
                      Icons.lock_outline_rounded,
                      color: greyReguler.color,
                    ),
                    hintText: 'Masukan Password',
                    hintStyle: greyReguler,
                    suffixIcon: InkWell(
                      onTap: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      child: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: blackReguler.color,
                      ),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: hapusFoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text("HAPUS FOTO PROFIL", style: whiteBold),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: loading ? null : simpan,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: greenblack,
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("SIMPAN", style: whiteBold),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
