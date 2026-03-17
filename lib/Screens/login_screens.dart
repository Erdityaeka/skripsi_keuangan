import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Screens/Sigin_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/navigation/navbar.dart';

class LoginScreens extends StatefulWidget {
  const LoginScreens({super.key});

  @override
  State<LoginScreens> createState() => _LoginScreensState();
}

class _LoginScreensState extends State<LoginScreens> {
  bool _isPasswordVisible = false; // perbaiki penulisan

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
                    Text('Lupa Password?', style: redReguler15),
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
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: redBold20.color!, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: TextField(
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
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: redBold20.color!, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: TextField(
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
      ],
    );
  }

  Widget button() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TombolNav()),
            );
          },
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: redBold20.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text('Login', style: whiteBold)),
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
