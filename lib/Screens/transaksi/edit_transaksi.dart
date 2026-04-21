import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';

class EditTransaksi extends StatefulWidget {
  const EditTransaksi({super.key, required TransaksiModel tx});

  @override
  State<EditTransaksi> createState() => _EditTransaksiState();
}

class _EditTransaksiState extends State<EditTransaksi> {
  String? Transaksi;
  String? Kategori;
  String? Bank;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buttonInput(),
              SizedBox(height: 15),
              buttoTipe(),
              SizedBox(height: 15),
              buttonKategori(),
              SizedBox(height: 15),
              buttonBank(),
              SizedBox(height: 100),
              buttonSimpan(),
            ],
          ),
        ),
      ),
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
      title: Text('Edit Transaksi', style: redBold20),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            // Aksi untuk tombol hapus
          },
          icon: Icon(Icons.delete, color: red),
        ),
      ],
      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  Widget buttonInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Judul Transaksi', style: redReguler15),
        SizedBox(height: 15),
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
              decoration: InputDecoration(
                hintText: 'Contoh: Mie Ayam',
                hintStyle: greyReguler,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        SizedBox(height: 15),
        Text('Nominal', style: redReguler15),
        SizedBox(height: 15),
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
              decoration: InputDecoration(
                prefixIcon: Text('Rp.', style: blackReguler),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                hintText: '10.000',
                hintStyle: greyReguler,
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ),
      ],
    );
  }

  Widget buttoTipe() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipe Transaksi', style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: Kategori,
                dropdownColor: white,
                hint: Text('Pemasukan', style: blackReguler),
                icon: Icon(Icons.arrow_drop_down, color: black),
                onChanged: (String? newValue) {
                  setState(() {
                    Kategori = newValue;
                  });
                },
                items: <String>['Pemasukan', 'Pengeluaran']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: blackReguler),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buttonKategori() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: Transaksi,
                dropdownColor: white,
                hint: Text('Pilih Kategori', style: blackReguler),
                icon: Icon(Icons.arrow_drop_down, color: black),
                onChanged: (String? newValue) {
                  setState(() {
                    Transaksi = newValue;
                  });
                },
                items:
                    <String>[
                      'Makanan',
                      'Gadget',
                      'Transportasi',
                      'Pendidikan',
                      'Kesehatan',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: blackReguler),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buttonBank() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank', style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: Bank,
                dropdownColor: white,
                hint: Text('SEMUA', style: blackReguler),
                icon: Icon(Icons.arrow_drop_down, color: black),
                onChanged: (String? newValue) {
                  setState(() {
                    Bank = newValue;
                  });
                },
                items:
                    <String>[
                      'SEMUA',
                      'Bank BCA',
                      'Bank Mandiri',
                      'Bank BNI',
                      'Bank BTN',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: blackReguler),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buttonSimpan() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: red,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(child: Text('Simpan Transaksi', style: whiteBold)),
    );
  }
}
