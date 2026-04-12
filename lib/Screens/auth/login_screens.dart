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

  //snackbar no
  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        backgroundColor: success ? green : red,
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
        MaterialPageRoute(builder: (context) => const TombolNav()),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Masukkan email Anda. Kami akan mengirimkan link untuk mengatur ulang password.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.isNotEmpty) {
                String? error = await AuthService().resetPassword(
                  resetEmailController.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);

                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Email reset dikirim! Silakan cek Inbox/Spam.",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  _showSnack(error);
                }
              }
            },
            child: const Text("Kirim"),
          ),
        ],
      ),
    );
  }

  //UI
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
                      child: Text('Lupa Password?', style: redReguler15),
                    ),
                  ],
                ),
                SizedBox(height: 35),
                button(),
                SizedBox(height: 120),
                Center(child: Text('V.1.0.0', style: greyReguler)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget image() {
    return const Image(
      image: AssetImage('images/Icon.png'),
      width: 250,
      height: 250,
    );
  }

  Widget input() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                icon: Icon(Icons.mark_email_unread_rounded, color: grey),
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
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                icon: Icon(Icons.lock_outline_rounded, color: grey),
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
                    color: black,
                  ),
                ),
                border: InputBorder.none,
              ),
            ),
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
              color: redBold20.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text('Login', style: whiteBold),
            ),
          ),
        ),

        SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Belum punya akun? ', style: blackReguler),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SiginScreens()),
                );
              },
              child: Text('Daftar', style: redReguler15),
            ),
          ],
        ),
      ],
    );
  }
}
