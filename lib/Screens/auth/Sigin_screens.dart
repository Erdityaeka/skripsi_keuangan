import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skripsi_keuangan/Screens/auth/login_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';

class SiginScreens extends StatefulWidget {
  const SiginScreens({super.key});

  @override
  State<SiginScreens> createState() => _SiginScreensState();
}

class _SiginScreensState extends State<SiginScreens> {
  bool _isPasswordVisible = false;
  bool _isPicking = false;
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();

  bool _isLoading = false;
  XFile? _pickedImage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  // Notifikasi
  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center, style: whiteBold),
        backgroundColor: success ? greennotif : rednotif,
      ),
    );
  }

  // Fungsi untuk memilih gambar
  Future<void> _pickImage() async {
    if (_isPicking) return;

    _isPicking = true;

    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
      print("ImagePicker error: $e");
    } finally {
      _isPicking = false;
    }
  }

  //REGISTER
  void _handleRegister() async {
    if (_namaController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack("Semua field harus diisi!");
      return;
    }

    if (!_emailController.text.contains("@")) {
      _showSnack("Format email tidak valid!");
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnack("Password minimal 6 karakter!");
      return;
    }

    setState(() => _isLoading = true);

    String? error = await AuthService().register(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      nama: _namaController.text.trim(),
      fotoFileName: _pickedImage?.name,
    );

    setState(() => _isLoading = false);

    if (error == null) {
      _showSnack("Akun berhasil dibuat!", success: true);

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => LoginScreens()),
        );
      });
    } else {
      _showSnack("Gagal mendaftar: $error");
    }
  }

  //wIDGET UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: image()),
                const SizedBox(height: 40),
                input(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreens(),
                          ),
                        );
                      },
                      child: Text('Sudah punya akun?', style: redReguler15),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                button(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget image() {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImage,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: red,
        backgroundImage: _pickedImage != null
            ? FileImage(File(_pickedImage!.path))
            : null,
        child: _pickedImage == null
            ? Icon(Icons.camera_alt_outlined, size: 50, color: white)
            : null,
      ),
    );
  }

  Widget input() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nama', style: blackReguler),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5.0, left: 14.0),
                child: Icon(Icons.person, color: grey),
              ),
              SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: _namaController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Masukan Nama',
                    hintStyle: greyReguler,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5.0, left: 14.0),
                child: Icon(Icons.mark_email_unread_rounded, color: grey),
              ),
              SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Masukan Email',
                    hintStyle: greyReguler,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5.0, left: 14.0),
                child: Icon(Icons.lock_outline_rounded, color: grey),
              ),
              SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  enabled: _isLoading,
                  decoration: InputDecoration(
                    hintText: 'Masukan Password',
                    hintStyle: greyReguler,
                    border: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(width: 5),
              InkWell(
                onTap: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.only(right: 14.0),
                  child: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget button() {
    return Column(
      children: [
        GestureDetector(
          onTap: _handleRegister,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: redBold20.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text('Daftar', style: whiteBold),
            ),
          ),
        ),
      ],
    );
  }
}
