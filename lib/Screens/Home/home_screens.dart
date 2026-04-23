import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Screens/transaksi/edit_transaksi.dart';

import 'package:skripsi_keuangan/Screens/transaksi/transaksi_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';

import 'package:skripsi_keuangan/services/firestore_service.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({super.key});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  // Format Rupiah
  final currency = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );
  final firestoreService = FirestoreService();

  String selectedBank = "semua";
  bool _isPasswordVisible = false;

  List<String> allBanks = ["semua"];

  Future<void> _refreshData() async {
    setState(() {});
  }

  //  Format Text Kosong
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Mengetahui Data Bank Sama
  String normalize(String? val) {
    return (val ?? '').toLowerCase().trim();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User tidak ditemukan")));
    }

    String displayNama = user.displayName ?? 'User';
    String nama = displayNama.split('|').first;

    return Scaffold(
      appBar: _buildAppbar(context, nama),

      // Mengambil Data Transaksi
      body: StreamBuilder<List<TransaksiModel>>(
        stream: firestoreService.gettransaksi(),

        builder: (context, txSnap) {
          if (!txSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = txSnap.data!;

          // Mengambil Data Bank
          return StreamBuilder<List<String>>(
            stream: firestoreService.getBank(),
            builder: (context, bankSnap) {
              if (!bankSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Data Bank
              final bankMaster = bankSnap.data!
                  .map((e) => normalize(e))
                  .where((e) => e.isNotEmpty)
                  .toSet();

              // Data Bank Dari Transaksi
              final bankFromTx = all
                  .map((tx) => normalize(tx.bank))
                  .where((e) => e.isNotEmpty)
                  .toSet();

              // Menggabungkan Data Bank
              allBanks = [
                "semua",
                ...{...bankMaster, ...bankFromTx}.toList()..sort(),
              ];

              // Kondisi Data Bank Tidak Ada Ke Reset
              if (!allBanks.contains(selectedBank)) {
                selectedBank = "semua";
              }

              final current = selectedBank;

              // Filter Data Bank
              final filtered = all.where((tx) {
                final bank = normalize(tx.bank);
                return current == "semua" || bank == current;
              }).toList();

              // Mensort Data Terbaru
              filtered.sort((a, b) => b.tanggal.compareTo(a.tanggal));

              // ambil 3 terbaru
              final recent = filtered.take(3).toList();

              // Hitung Transaksi
              double pemasukan = 0;
              double pengeluaran = 0;

              for (var tx in filtered) {
                if (tx.tipe == "pemasukan") {
                  pemasukan += tx.nominal;
                } else {
                  pengeluaran += tx.nominal;
                }
              }

              final saldo = pemasukan - pengeluaran;

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 30,
                    ),
                    child: Column(
                      children: [
                        // Card Saldo
                        cardSaldo(pemasukan, pengeluaran, saldo),

                        const SizedBox(height: 20),

                        // DROPDOWN BANK
                        cardBank(),

                        const SizedBox(height: 30),

                        // LIST TRANSAKSI
                        listTransaksi(recent),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Appbar
  // ignore: strict_top_level_inference
  PreferredSizeWidget _buildAppbar(context, String nama) {
    return AppBar(
      backgroundColor: whiteBold.color,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Hi,', style: redBold15),
                const SizedBox(width: 5),
                Text(capitalize(nama), style: redBold15),
              ],
            ),
            Text('Selamat datang kembali...', style: redReguler15),
          ],
        ),
      ),
      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  // Card Saldo
  Widget cardSaldo(double pemasukan, double pengeluaran, double saldo) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: redblack,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pemasukan', style: greenBold15),
            Text(currency.format(pemasukan), style: whiteReguler),
            const SizedBox(height: 10),
            Text('Pengeluaran', style: yellowBold15),
            Text(currency.format(pengeluaran), style: whiteReguler),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Total', style: whiteBold),
                IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ],
            ),
            Text(
              _isPasswordVisible ? currency.format(saldo) : '••••••',
              style: whiteReguler,
            ),
          ],
        ),
      ),
    );
  }

  // Dropdown Bank
  Widget cardBank() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: ValueKey(allBanks.length),
            value: selectedBank,
            dropdownColor: red,
            icon: Icon(Icons.arrow_drop_down, color: white),
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedBank = value);
            },
            items: allBanks.map((bank) {
              return DropdownMenuItem(
                value: bank,
                child: Text(bank.toUpperCase(), style: whiteReguler),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // List
  Widget listTransaksi(List<TransaksiModel> list) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          selectedBank == "semua"
              ? "Belum ada transaksi"
              : "Belum ada transaksi di Bank '${selectedBank.toUpperCase()}'",
          style: blackBold15,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Transaksi Terbaru', style: redReguler15),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const TransaksiScreens(showBackButton: true),
                  ),
                );
              },
              child: Text('Lihat Semua', style: blueReguler12),
            ),
          ],
        ),
        const SizedBox(height: 20),

        ...list.map((tx) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditTransaksi(tx: tx)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: red, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 11,
                      right: 11,
                      top: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(tx.tanggal), // ✅ FIX
                            style: redReguler12,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currency.format(tx.nominal),
                          style: tx.tipe == "pemasukan"
                              ? greenBold12
                              : yellowBold12,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),
                  Divider(color: red, thickness: 1),

                  // Item Transaksi
                  Padding(
                    padding: const EdgeInsets.all(11.0),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: tx.tipe == "pemasukan" ? green : yellow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            tx.tipe == "pemasukan"
                                ? Icons.call_made
                                : Icons.call_received,
                            color: white,
                            size: 18,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.judul,
                                style: redBold15,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(tx.kategori, style: redReguler12),
                              const SizedBox(height: 5),
                              Text(tx.bank, style: redReguler12),
                            ],
                          ),
                        ),

                        Text(
                          currency.format(tx.nominal),
                          style: tx.tipe == "pemasukan"
                              ? greenBold12
                              : yellowBold12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
