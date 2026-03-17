import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({super.key});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context), 
      body: Column(
        
      ));
  }
}

//ui appbar
PreferredSizeWidget _buildAppbar(context) {
  return AppBar(
    backgroundColor: whiteBold.color,
    automaticallyImplyLeading: false,
    title: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Hi,', style: redBold15),
              SizedBox(width: 5),
              Text('User', style: redBold15),
            ],
          ),
          Text('Selamat datang kembali...', style: redReguler15),
        ],
      ),
    ),
    flexibleSpace: Container(decoration: BoxDecoration(color: whiteBold.color)),
  );
}
