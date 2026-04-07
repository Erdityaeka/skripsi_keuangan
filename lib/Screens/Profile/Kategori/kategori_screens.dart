import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class KategoriScreens extends StatefulWidget {
  const KategoriScreens({super.key});

  @override
  State<KategoriScreens> createState() => _KategoriScreensState();
}

class _KategoriScreensState extends State<KategoriScreens> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: Column(children: [buttonAddBank(), listBank()]),
    );
  }

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('Bank', style: redBold20),
      centerTitle: true,
    );
  }

  Widget buttonAddBank() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: white,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(bottom: BorderSide(color: grey, width: 1)),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Judul Kategori', style: redReguler15),
                  SizedBox(height: 15),
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      border: Border.all(color: red, width: 1.5),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hint: Text(
                            'Masukan nama kategori',
                            style: greyReguler,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10), // jarak antara input dan tombol
            Container(
              width: 90,
              height: 55,
              decoration: BoxDecoration(
                color: red,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(child: Icon(Icons.add, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget listBank() {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 30),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: red, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.table_chart, size: 20, color: black),
              const SizedBox(width: 20),
              Text('Makanan', style: blackBold15),
              Spacer(),
              Icon(Icons.delete, size: 20, color: red),
            ],
          ),
        ),
      ),
    );
  }
}
