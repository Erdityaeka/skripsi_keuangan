import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Screens/Profile/Bank/bank_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Kategori/kategori_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class ProfileScreens extends StatefulWidget {
  const ProfileScreens({super.key});

  @override
  State<ProfileScreens> createState() => _ProfileScreensState();
}

class _ProfileScreensState extends State<ProfileScreens> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 30,
              bottom: 20,
            ),
            child: Column(
              children: [
                profileimage(),
                SizedBox(height: 30),
                buttonBody(),
                SizedBox(height: 100),
                butonLogout(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Widget untuk menampilkan gambar profil
  Widget profileimage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: red,
          child: Icon(Icons.person, size: 50, color: white),
        ),
        const SizedBox(width: 20),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Erditya', style: blackBold),
            Text('e@mail.com', style: blackReguler12),
          ],
        ),
        Spacer(),
        Icon(Icons.edit_outlined, size: 20, color: black),
      ],
    );
  }

  //Widget untuk menampilkan tombol-tombol pada halaman profil
  Widget buttonBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Button Bank
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BankScreens()),
            );
          },

          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.account_balance, size: 20, color: black),
                const SizedBox(width: 20),
                Text('Tambah Bank', style: blackReguler),
                Spacer(),
                Icon(Icons.arrow_right_rounded, size: 20, color: black),
              ],
            ),
          ),
        ),
        SizedBox(height: 30),

        //Button Kategori
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => KategoriScreens()),
            );
          },

          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.table_chart, size: 20, color: black),
                const SizedBox(width: 20),
                Text('Tambah Kategori', style: blackReguler),
                Spacer(),
                Icon(Icons.arrow_right_rounded, size: 20, color: black),
              ],
            ),
          ),
        ),
        SizedBox(height: 30),

        //Button Laporan
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.download, size: 20, color: black),
              const SizedBox(width: 20),
              Text('Unduh Laporan', style: blackReguler),
              Spacer(),
              Icon(Icons.arrow_right_rounded, size: 20, color: black),
            ],
          ),
        ),
        SizedBox(height: 30),

        //Button Tentang Aplikasi
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.perm_device_info, size: 20, color: black),
              const SizedBox(width: 20),
              Text('Tentang Aplikasi', style: blackReguler),
              Spacer(),
              Icon(Icons.arrow_right_rounded, size: 20, color: black),
            ],
          ),
        ),
        SizedBox(height: 30),

        //Button Tentang Bantuan
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 20, color: black),
              const SizedBox(width: 20),
              Text('Bantuan dan Masukan', style: blackReguler),
              Spacer(),
              Icon(Icons.arrow_right_rounded, size: 20, color: black),
            ],
          ),
        ),
      ],
    );
  }

  Widget butonLogout() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.logout, size: 20, color: white),
          const SizedBox(width: 10),
          Text('Logout', style: whiteBold),
        ],
      ),
    );
  }
}
