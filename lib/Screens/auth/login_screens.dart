import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Screens/auth/Sigin_screens.dart';

import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/navigation/bottom_navigation.dart';
import 'package:skripsi_keuangan/services/auth_services.dart';

class LoginScreens extends StatefulWidget {
  const LoginScreens({super.key});

  @override
  State<LoginScreens> createState() => _LoginScreensState();
}

class _LoginScreensState extends State<LoginScreens> {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //snackbar
  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center, style: putihBold15),
        backgroundColor: success ? greennotif : rednotif,
      ),
    );
  }

  //fungsi login
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack("Email dan Password tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);

    String? error = await AuthService().signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      _showSnack("Login berhasil!", success: true);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => BottomNavigation()),
        (route) => false,
      );
      return;
    }

    // EMAIL / PASSWORD SALAH
    final err = error.toLowerCase();

    if (err.contains("invalid-email")) {
      _showSnack("Format email tidak valid (harus ada @)");
    } else {
      _showSnack("Email atau Password salah");
    }
  }

  //Fungsi  Lupa  Password
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: putih,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Reset Password?", style: hitamBold20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Masukkan email Anda. Kami akan mengirimkan link ke email Anda  lewat spam untuk mengatur ulang password.",
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
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: hitamReguler15,
                  decoration: InputDecoration(
                    hintText: 'Masukan Email',
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
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: dialogBatalBold15),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: hijauSimpan),
            onPressed: () async {
              if (resetEmailController.text.trim().isEmpty) {
                _showSnack("Email tidak boleh kosong");
                return;
              }

              String? error = await AuthService().resetPassword(
                resetEmailController.text.trim(),
              );

              if (!mounted) return;
              Navigator.pop(context);

              if (error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Center(
                      child: Text(
                        "Email reset password berhasil dikirim! Silakan cek Inbox/Spam.",
                        style: putihBold15,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    backgroundColor: greennotif,
                  ),
                );
              } else {
                _showSnack(error);
              }
            },
            child: Text("Kirim", style: putihBold15),
          ),
        ],
      ),
    );
  }

  //Widget UI
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
                    Spacer(),
                    InkWell(
                      onTap: _showForgotPasswordDialog,
                      child: Text('Lupa Password?', style: hitamReguler15),
                    ),
                  ],
                ),
                SizedBox(height: 35),
                button(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget image() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Image(
            image: AssetImage('Images/Icon.png'),
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 20),
          Text(
            'Selamat Datang',
            style: hitamBold20,
            textAlign: TextAlign.center,
          ),
          Text(
            'Silahkan masuk untuk mengelola keuanganmu',
            style: hitamReguler15,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget input() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email Address', style: hitamReguler15),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5.0, left: 14.0),
                child: Icon(Icons.mark_email_unread_rounded, color: abu),
              ),
              SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Masukan Email',
                    hintStyle: abuReguler15,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text('Password', style: hitamReguler15),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 5.0, left: 14.0),
                child: Icon(Icons.lock_outline_rounded, color: abu),
              ),
              SizedBox(width: 5),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Masukan Password',
                    hintStyle: abuReguler15,
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
                    color: hitam,
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
          onTap: _handleLogin,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: hijauSimpan,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: _isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(putih),
                    )
                  : Text('Login', style: putihBold15),
            ),
          ),
        ),

        SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Belum punya akun? ', style: hitamReguler15),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SiginScreens()),
                );
              },
              child: Text('Daftar', style: hijauBold15),
            ),
          ],
        ),
      ],
    );
  }
}
