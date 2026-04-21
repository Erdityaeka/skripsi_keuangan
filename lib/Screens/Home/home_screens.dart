import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:skripsi_keuangan/Screens/transaksi/transaksi_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';

class HomeScreens extends StatefulWidget {
  final List<TransaksiModel> transactions;

  const HomeScreens({super.key, this.transactions = const []});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  final currency = NumberFormat.simpleCurrency(locale: 'id', decimalDigits: 0);

  String selectedBank = "semua";
  bool _isPasswordVisible = false;

  // SIMPAN BANK DI STATE
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

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .collection('bank')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          //BANK
          final banks =
              snapshot.data?.docs
                  .map((doc) => (doc['nama'] ?? '').toString().toLowerCase())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              [];

          //SIMPAN KE STATE
          allBanks = ["semua", ...banks];

          final current = allBanks.contains(selectedBank)
              ? selectedBank
              : "semua";

          //FILTER
          final filtered = widget.transactions.where((tx) {
            final bank = (tx.bank).toLowerCase();
            return current == "semua" || bank == current;
          }).toList();

          //SORT
          filtered.sort((a, b) => b.tanggal.compareTo(a.tanggal));

          final recent = filtered.take(3).toList();

          //HITUNG
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
                    cardBank(), // ✅ tetap tanpa parameter
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

  //APPBAR
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
    );
  }

  //CARD
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

  //DROPDOWN
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

  //LIST
  Widget listTransaksi(List<TransaksiModel> list) {
    if (list.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(20),
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
                    builder: (_) => TransaksiScreens(showBackButton: true),
                  ),
                );
              },
              child: Text('Lihat Semua', style: blueReguler12),
            ),
          ],
        ),
        const SizedBox(height: 20),

        ...list.map((tx) {
          return ListTile(
            title: Text(tx.judul),
            subtitle: Text(tx.bank),
            trailing: Text(
              currency.format(tx.nominal),
              style: TextStyle(
                color: tx.tipe == "pemasukan" ? Colors.green : Colors.orange,
              ),
            ),
          );
        }),
      ],
    );
  }
}
