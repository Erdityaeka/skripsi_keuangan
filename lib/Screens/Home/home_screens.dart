import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:skripsi_keuangan/Screens/transaksi/transaksi_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';

class HomeScreens extends StatefulWidget {
  const HomeScreens({super.key});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  final currency = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  String selectedBank = "semua";
  bool _isPasswordVisible = false;

  List<String> allBanks = ["semua"];

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() {});
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User tidak ditemukan")));
    }

    String displayNama = user.displayName ?? 'User';
    List<String> parts = displayNama.split('|');
    String nama = parts.isNotEmpty ? parts[0] : "User";

    return Scaffold(
      appBar: _buildAppbar(context, nama),

      // ================= STREAM FIRESTORE =================
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .collection('transaksi')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ================= AMBIL DATA =================
          final all = snapshot.data!.docs.map((doc) {
            return TransaksiModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          // ================= AMBIL BANK =================
          final banks = all.map((tx) => tx.bank.toLowerCase()).toSet().toList();

          allBanks = ["semua", ...banks];

          final current = allBanks.contains(selectedBank)
              ? selectedBank
              : "semua";

          // ================= FILTER =================
          final filtered = all.where((tx) {
            final bank = tx.bank.toLowerCase();
            return current == "semua" || bank == current;
          }).toList();

          // ================= SORT =================
          filtered.sort((a, b) => b.tanggal.compareTo(a.tanggal));

          final recent = filtered.take(3).toList();

          // ================= HITUNG =================
          double income = 0;
          double expense = 0;

          for (var tx in filtered) {
            if (tx.tipe == "pemasukan") {
              income += tx.nominal;
            } else {
              expense += tx.nominal;
            }
          }

          final saldo = income - expense;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
                child: Column(
                  children: [
                    cardtransaksi(income, expense, saldo),
                    const SizedBox(height: 20),
                    cardBank(),
                    const SizedBox(height: 30),
                    listTransaksi(recent),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= APPBAR =================
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
    );
  }

  // ================= CARD =================
  Widget cardtransaksi(double income, double expense, double saldo) {
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
            Text(currency.format(income), style: whiteReguler),

            const SizedBox(height: 10),

            Text('Pengeluaran', style: yellowBold15),
            Text(currency.format(expense), style: whiteReguler),

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

  // ================= DROPDOWN =================
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

  // ================= LIST =================
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
        // ===== HEADER =====
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

        // ===== LIST =====
        ...list.map((tx) {
          return Container(
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
                // ===== HEADER =====
                Padding(
                  padding: const EdgeInsets.only(left: 11, right: 11, top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('dd MMM yyyy').format(tx.tanggal), // ✅ FIX
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

                // ===== ITEM =====
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
          );
        }),
      ],
    );
  }
}
