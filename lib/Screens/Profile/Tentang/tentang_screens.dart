import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Screens/panduan/panduan_screen.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:url_launcher/url_launcher.dart';

class TentangScreens extends StatelessWidget {
  const TentangScreens({super.key});

  // Fungsi internal untuk membuka URL luar secara aman
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 30,
            bottom: 30,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              const SizedBox(height: 15),
              _buildText(),
              const SizedBox(height: 30),

              // TOMBOL UNTUK MEMANGGIL PANDUAN PAGE BAWAAN DENGAN PARAMETER KHUSUS
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Memanggil file panduan lama milikmu dengan mengaktifkan mode khusus tentang
                      builder: (_) => const PanduanPage(isFromTentang: true),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    color: hijauSimpan,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, color: putih, size: 22),
                      const SizedBox(width: 10),
                      Text('Tata Cara Penggunaan Aplikasi', style: putihBold15),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),
              _buildfolow(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: putih,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: hitam),
      ),
      title: Text('Tentang Aplikasi', style: hitamBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  // Widget Gambar UI
  Widget _buildImage() {
    return Center(
      child: Image.asset("Images/Icon.png", width: 200, height: 200),
    );
  }

  // Widget Text UI
  Widget _buildText() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aplikasi Uang Note sebuah aplikasi catatan keuangan yang berbasis AI dengan versi 1.0.0.',
          style: hitamReguler15,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 10),
        Text(
          'Aplikasi ini membantu aktivitas pengguna dalam melakukan pemasukan maupun pengeluaran.',
          style: hitamReguler15,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 10),
        Text(
          'Aplikasi ini dibuat sangat simple dan ringan sehingga pengguna mudah dalam memakainya.',
          style: hitamReguler15,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 15),
        Text(
          'Aplikasi ini dibuat oleh developer atas nama:',
          style: hitamBold15,
        ),
        const SizedBox(height: 5),
        Text('- Erditya Eka Pratama', style: hitamBold15),
      ],
    );
  }

  // Widget Follow Sosial Media
  Widget _buildfolow() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Follow Sosial Media Kami',
            style: hitamBold15,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 15,
            runSpacing: 10,
            children: [
              InkWell(
                onTap: () => _launchUrl(
                  'https://www.tiktok.com/@ekyreee?_t=ZS-8uNjf1zvli6&_r=1',
                ),
                child: Image.asset('Images/tiktok.png', width: 25, height: 25),
              ),
              InkWell(
                onTap: () => _launchUrl(
                  'https://www.instagram.com/erditya04?igsh=MXV1ZDVuMHdvZzk1Ng==',
                ),
                child: Image.asset(
                  'Images/instagram.png',
                  width: 25,
                  height: 25,
                ),
              ),
              InkWell(
                onTap: () => _launchUrl(
                  'https://www.linkedin.com/in/erditya-eka-pratama',
                ),
                child: Image.asset('Images/idn.png', width: 22, height: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
