import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class TentangScreens extends StatelessWidget {
  const TentangScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 30,
          bottom: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildImage(), SizedBox(height: 15), _buildText()],
        ),
      ),
    );
  }

  // ignore: strict_top_level_inference
  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('Tentang Aplikasi', style: redBold20),
      centerTitle: true,
    );
  }

  // Widget Gambar UI
  Widget _buildImage() {
    return Center(
      child: Image.asset("images/Icon.png", width: 200, height: 200),
    );
  }

  // Widget Text UI
  Widget _buildText() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aplikasi  Uang Note  sebuah  aplikasi catatan keuangan yang  berbasis AI degan versi 1.0.0.',
          style: blackReguler,
          textAlign: TextAlign.justify,
        ),
        SizedBox(height: 10),
        Text(
          'Aplikasi ini membantu  aktivitas pengguna dalam  melalukan pemasukan maupun pengeluaran.',
          style: blackReguler,
          textAlign: TextAlign.justify,
        ),
        SizedBox(height: 10),
        Text(
          'Aplikasi ini dibuat sangat simple dan ringan sehingga pengguna mudah dalam memakainya.',
          style: blackReguler,
          textAlign: TextAlign.justify,
        ),
        SizedBox(height: 15),
        Text(
          'Aplikasi ini dibuat oleh developer atas nama:',
          style: blackBold15,
          textAlign: TextAlign.justify,
        ),
        SizedBox(height: 5),
        Text(
          '-Erditya Eka Pratama',
          style: blackBold15,
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}
