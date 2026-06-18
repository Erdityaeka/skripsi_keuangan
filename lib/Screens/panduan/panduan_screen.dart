import 'package:flutter/material.dart';

class PanduanPage extends StatefulWidget {
  // Ditambahkan parameter opsional isFromTentang dengan nilai default false
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tata Cara Aplikasi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Konten Kontainer Teks Panduan
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PANDUAN PENGGUNAAN APLIKASI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. REGISTER\n'
                        'Silakan lakukan registrasi/daftar akun terlebih dahulu menggunakan Email dan Password Anda jika belum memiliki akun.\n\n'
                        '2. LOGIN\n'
                        'Setelah mendaftar, masuk menggunakan akun yang telah Anda daftarkan.\n\n'
                        '3. ISI DATA Sumber Dana & KATEGORI\n'
                        'Saat pertama kali masuk, Anda wajib mengisi informasi Nama Sumber Dana dan Kategori Transaksi yang akan digunakan.\n\n'
                        '4. MULAI TRANSAKSI\n'
                        'Jika semua data sudah lengkap, Anda bisa langsung masuk ke menu utama untuk mulai melakukan pencatatan transaksi.',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Checkbox Persetujuan
            // Logika baru: Jika datang dari halaman Tentang (widget.isFromTentang == true),
            // maka baris Checkbox ini akan disembunyikan (SizedBox.shrink)
            if (!widget.isFromTentang)
              Row(
                children: [
                  Checkbox(
                    value: _sudahBaca,
                    activeColor: Colors.blue,
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
            if (!widget.isFromTentang) const SizedBox(height: 16),

            // 3. Tombol Aksi Dinamis
            ElevatedButton(
              // Jika dari Tentang Aplikasi, tombol selalu aktif. Jika dari Register, harus centang dulu.
              onPressed: widget.isFromTentang
                  ? () {
                      Navigator.pop(
                        context,
                      ); // Langsung kembali tanpa kirim data
                    }
                  : (_sudahBaca
                        ? () {
                            Navigator.pop(
                              context,
                              true,
                            ); // Kirim data true ke register
                          }
                        : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                // Jika dari Tentang Aplikasi teks berubah menjadi 'Kembali'
                widget.isFromTentang ? 'Kembali' : 'Lanjutkan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
