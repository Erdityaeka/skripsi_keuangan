import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class PanduanPage extends StatefulWidget {
  final bool isFromTentang;

  const PanduanPage({super.key, this.isFromTentang = false});

  @override
  State<PanduanPage> createState() => _PanduanPageState();
}

class _PanduanPageState extends State<PanduanPage> {
  bool _sudahBaca = false; // Status kontrol checkbox

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: abu, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 12),
                      _buildIsiPanduan(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildCheckbox(),

            _buildTombol(),
          ],
        ),
      ),
    );
  }

  // WIDGET APPBAR
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Tata Cara Pakai Aplikasi'),
      titleTextStyle: hitamBold20,
      backgroundColor: putih,
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  //WIDGET TITLE (JUDUL HALAMAN)
  Widget _buildTitle() {
    return Center(
      child: Text('PANDUAN PENGGUNAAN APLIKASI', style: hitamBold20),
    );
  }

  // WIDGET ISI PANDUAN
  Widget _buildIsiPanduan() {
    return Text.rich(
      TextSpan(
        style: hitamReguler15.copyWith(
          height: 1.5,
        ), // Tetap pakai style dasar Anda
        children: [
          TextSpan(text: '1. REGISTER\n', style: hitamBold15),
          TextSpan(
            text:
                'Silakan lakukan registrasi/daftar akun terlebih dahulu menggunakan Email dan Password Anda jika belum memiliki akun.\n\n',
          ),
          TextSpan(text: '2. LOGIN\n', style: hitamBold15),
          TextSpan(
            text:
                'Setelah mendaftar, masuk menggunakan akun yang telah Anda daftarkan.\n\n',
          ),
          TextSpan(
            text: '3. ISI DATA Sumber Dana & KATEGORI\n',
            style: hitamBold15,
          ),
          TextSpan(
            text:
                'Saat pertama kali masuk, Anda wajib mengisi informasi Nama Sumber Dana dan Kategori Transaksi yang akan digunakan.\n\n',
          ),
          TextSpan(text: '4. MULAI TRANSAKSI\n', style: hitamBold15),
          TextSpan(
            text:
                'Jika semua data sudah lengkap, Anda bisa langsung masuk ke menu utama untuk mulai melakukan pencatatan transaksi, Diwajibkan isi PEMASUKAN terlebih dahulu.\n\n',
          ),
          TextSpan(text: '5. PERINGATAN\n', style: merahBold15),
          TextSpan(
            text:
                'Jika transaksi anda minus, Anda tidak bisa melakukan transaksi pengeluaran, sehingga anda harus tambah pemasukan terlebih dahulu.\n\n',
          ),
        ],
      ),
      textAlign: TextAlign.justify,
    );
  }

  //  WIDGET CHECKBOX PERSETUJUAN
  Widget _buildCheckbox() {
    if (widget.isFromTentang) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: _sudahBaca,
              activeColor: biru,
              onChanged: (bool? value) {
                setState(() {
                  _sudahBaca = value ?? false;
                });
              },
            ),
            const Expanded(
              child: Text(
                'Saya sudah membaca dan memahami tata cara penggunaan aplikasi ini.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTombol() {
    return ElevatedButton(
      onPressed: widget.isFromTentang
          ? () {
              Navigator.pop(context);
            }
          : (_sudahBaca
                ? () {
                    Navigator.pop(context, true);
                  }
                : null),
      style: ElevatedButton.styleFrom(
        backgroundColor: hijauSimpan,
        foregroundColor: putih,
        disabledBackgroundColor: abu,
        disabledForegroundColor: abu,
        fixedSize: const Size.fromHeight(55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(
        widget.isFromTentang ? 'Kembali' : 'Lanjutkan',
        style: putihBold15,
      ),
    );
  }
}
