import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class TentangScreens extends StatelessWidget {
  const TentangScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppbar(context));
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
      title: Text('Kategori', style: redBold20),
      centerTitle: true,
    );
  }
}
