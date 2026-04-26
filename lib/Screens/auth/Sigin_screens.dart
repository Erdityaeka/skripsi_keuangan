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
  // Status password
  bool _isPasswordVisible = false;

  // Proteksi double klik pilih gambar
  bool _isPicking = false;

  // Status loading register
  bool _isLoading = false;

  // Controller input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();

  // Foto profile
  XFile? _pickedImage;

  // Posisi slider foto
  double _yAlignment = 0.0;

  @override
  void dispose() {
    // Hindari memory leak
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  // Notifikasi aman
  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Center(
            child: Text(msg, style: whiteBold, textAlign: TextAlign.center),
          ),
          backgroundColor: success ? greennotif : rednotif,
        ),
      );
  }

  // Pilih gambar gallery
  Future<void> _pickImage() async {
    if (_isPicking || _isLoading) return;

    _isPicking = true;

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (image != null && mounted) {
        setState(() {
          _pickedImage = image;

          // Reset posisi slider
          _yAlignment = 0.0;
        });
      }
    } catch (e) {
      _showSnack("Gagal memilih foto");
    } finally {
      _isPicking = false;
    }
  }

  // Validasi input
  bool _validateInput() {
    if (_namaController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnack("Semua field harus diisi!");
      return false;
    }

    if (!_emailController.text.contains("@")) {
      _showSnack("Format email tidak valid!");
      return false;
    }

    if (_passwordController.text.length < 6) {
      _showSnack("Password minimal 6 karakter!");
      return false;
    }

    return true;
  }

  // Register akun
  Future<void> _handleRegister() async {
    if (!_validateInput()) return;

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Format foto + posisi slider
      String? finalFotoString;

      if (_pickedImage != null) {
        finalFotoString = "${_pickedImage!.name}|$_yAlignment";
      }

      final error = await AuthService().register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nama: _namaController.text.trim(),
        fotoFileName: finalFotoString,
      );

      if (!mounted) return;

      if (error == null) {
        _showSnack("Akun berhasil dibuat!", success: true);

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreens()),
          );
        });
      } else {
        _showSnack("Gagal mendaftar: $error");
      }
    } catch (e) {
      _showSnack("Terjadi kesalahan");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Widget input reusable
  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: blackReguler),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5, left: 14),
                child: Icon(icon, color: grey),
              ),

              const SizedBox(width: 5),

              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !_isLoading,
                  keyboardType: keyboardType,
                  obscureText: isPassword ? !_isPasswordVisible : false,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: hint,
                    hintStyle: greyReguler,
                    border: InputBorder.none,
                  ),
                ),
              ),

              if (isPassword)
                InkWell(
                  onTap: () {
                    if (!mounted) return;

                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
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

  // Widget foto profile
  Widget image() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: red,
            child: ClipOval(
              child: SizedBox.expand(
                child: _pickedImage != null
                    ? Image.file(
                        File(_pickedImage!.path),
                        fit: BoxFit.cover,
                        alignment: Alignment(0, _yAlignment),
                      )
                    : Icon(Icons.camera_alt_outlined, size: 50, color: white),
              ),
            ),
          ),
        ),

        if (_pickedImage != null) ...[
          const SizedBox(height: 10),

          Slider(
            value: _yAlignment,
            min: -1.0,
            max: 1.0,
            activeColor: red,
            onChanged: (val) {
              if (!mounted) return;

              setState(() {
                _yAlignment = val;
              });
            },
          ),

          Text(
            "Geser posisi foto profil",
            style: TextStyle(fontSize: 12, color: grey),
          ),
        ],
      ],
    );
  }

  // Widget semua input
  Widget input() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: 'Nama',
          hint: 'Masukan Nama',
          icon: Icons.person,
          controller: _namaController,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: 'Email Address',
          hint: 'Masukan Email',
          icon: Icons.mark_email_unread_rounded,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 20),

        _buildInputField(
          label: 'Password',
          hint: 'Masukan Password',
          icon: Icons.lock_outline_rounded,
          controller: _passwordController,
          isPassword: true,
        ),
      ],
    );
  }

  // Tombol daftar
  Widget button() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleRegister,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: redBold20.color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('Daftar', style: whiteBold),
        ),
      ),
    );
  }

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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
}
