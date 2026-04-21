import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:skripsi_keuangan/Screens/transaksi/edit_transaksi.dart';
import 'package:skripsi_keuangan/Screens/transaksi/tambah_transaksi.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';

class TransaksiScreens extends StatefulWidget {
  final bool showBackButton;

  // ✅ TIDAK WAJIB LAGI (INI YANG BIKIN NAVIGATION JADI AMAN)
  final List<TransaksiModel> transactions;

  const TransaksiScreens({
    super.key,
    required this.showBackButton,
    this.transactions = const [], // ✅ default kosong
  });

  @override
  State<TransaksiScreens> createState() => _TransaksiScreensState();
}

class _TransaksiScreensState extends State<TransaksiScreens> {
  bool _isPasswordVisible = false;
  DateTime _focusedMonth = DateTime.now();

  final currency = NumberFormat.simpleCurrency(locale: 'id', decimalDigits: 0);

  String selectedBank = "semua";

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User tidak ditemukan")));
    }

    return Scaffold(
      appBar: _buildAppbar(context),

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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada data bank"));
          }

          // ================= BANK =================
          final banks = snapshot.data!.docs
              .map((doc) => (doc['nama'] ?? '').toString().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toList();

          final allBanks = ["semua", ...banks];

          final currentBank = allBanks.contains(selectedBank)
              ? selectedBank
              : "semua";

          // ================= FILTER =================
          final filtered = widget.transactions.where((tx) {
            final sameMonth =
                tx.tanggal.month == _focusedMonth.month &&
                tx.tanggal.year == _focusedMonth.year;

            final bank = (tx.bank).toLowerCase();

            final sameBank = currentBank == "semua" || bank == currentBank;

            return sameMonth && sameBank;
          }).toList();

          // ================= HITUNG =================
          final pemasukan = filtered
              .where((tx) => tx.tipe == "pemasukan")
              .fold(0.0, (sum, tx) => sum + tx.nominal);

          final pengeluaran = filtered
              .where((tx) => tx.tipe == "[pengeluaran]")
              .fold(0.0, (sum, tx) => sum + tx.nominal);

          final saldo = pemasukan - pengeluaran;

          // ================= GROUP =================
          final Map<DateTime, List<TransaksiModel>> grouped = {};

          for (var tx in filtered) {
            final day = DateTime(
              tx.tanggal.year,
              tx.tanggal.month,
              tx.tanggal.day,
            );
            grouped.putIfAbsent(day, () => []).add(tx);
          }

          final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
                child: Column(
                  children: [
                    cardtransaksi(pemasukan, pengeluaran, saldo),
                    const SizedBox(height: 20),
                    cardBank(allBanks),
                    const SizedBox(height: 30),

                    // DATA KALAU KOSONG
                    days.isEmpty
                        ? Text(
                            currentBank == "semua"
                                ? "Belum ada transaksi"
                                : "Belum ada transaksi di Bank '${currentBank.toUpperCase()}'",
                            style: blackBold15,
                          )
                        : listTransaksi(days, grouped),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ================= APPBAR =================
  PreferredSizeWidget _buildAppbar(context) {
    return AppBar(
      backgroundColor: whiteBold.color,
      automaticallyImplyLeading: false,
      leading: widget.showBackButton
          ? IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: red),
            )
          : null,
      title: Text('Transaksi', style: redBold20),
      centerTitle: true,
    );
  }

  // ================= CARD =================
  Widget cardtransaksi(double pemasukan, double pengeluaran, double saldo) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: redblack,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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

  // ================= DROPDOWN =================
  Widget cardBank(List<String> banks) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: red,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedBank,
          dropdownColor: red,
          icon: Icon(Icons.arrow_drop_down, color: white),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedBank = value);
          },
          items: banks.map((bank) {
            return DropdownMenuItem(
              value: bank,
              child: Text(bank.toUpperCase(), style: whiteReguler),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ================= LIST =================
  Widget listTransaksi(
    List<DateTime> days,
    Map<DateTime, List<TransaksiModel>> grouped,
  ) {
    return Column(
      children: days.map((day) {
        final list = grouped[day]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd MMM yyyy').format(day), style: redReguler12),
            ...list.map((tx) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditTransaksi()),
                  );
                },
                child: ListTile(
                  title: Text(tx.judul),
                  subtitle: Text(tx.bank),
                  trailing: Text(
                    currency.format(tx.nominal),
                    style: TextStyle(
                      color: tx.tipe == "pemasukan"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  // ================= FAB =================
  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: red,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TambahTransaksi()),
        );
      },
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
