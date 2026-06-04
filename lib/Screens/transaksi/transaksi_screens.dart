import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/models/bank_model.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/Screens/transaksi/edit_transaksi.dart';
import 'package:skripsi_keuangan/Screens/transaksi/tambah_transaksi.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class TransaksiScreens extends StatefulWidget {
  final bool showBackButton;

  const TransaksiScreens({super.key, required this.showBackButton});

  @override
  State<TransaksiScreens> createState() => _TransaksiScreensState();
}

class _TransaksiScreensState extends State<TransaksiScreens> {
  bool _isPasswordVisible = false;
  DateTime _focusedMonth = DateTime.now();

  final currency = NumberFormat.simpleCurrency(
    locale: 'id',
    name: 'Rp.',
    decimalDigits: 0,
  );

  String selectedBank = "semua";
  List<String> allBanks = ["semua"];

  //  Format Text Kapital
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  final firestoreService = FirestoreService();

  Future<void> _refreshData() async {
    setState(() {});
  }

  // Mengetahui Data Bank Sama
  String normalize(String? val) {
    return (val ?? '').toLowerCase().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menampilkan Data Transaksi
      body: SafeArea(
        child: StreamBuilder<List<TransaksiModel>>(
          stream: firestoreService.gettransaksi(),

          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final transactions = snapshot.data!;

            // Menampilkan Data Bank
            return StreamBuilder<List<BankModel>>(
              stream: firestoreService.getBankModels(),

              builder: (context, bankSnap) {
                if (!bankSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Data Dari Kolekesi Bank
                final bankMaster = bankSnap.data!
                    .map((e) => normalize(e.nama))
                    .where((e) => e.isNotEmpty)
                    .toSet();

                // Bank dari transaksi
                final bankFromTx = transactions
                    .map((tx) => normalize(tx.bank))
                    .where((e) => e.isNotEmpty)
                    .toSet();

                allBanks = [
                  "semua",
                  ...{...bankMaster, ...bankFromTx}.toList()..sort(),
                ];

                // Kondisi Bank Tidak Ada
                if (!allBanks.contains(selectedBank)) {
                  selectedBank = "semua";
                }

                // Filter
                final filtered = transactions.where((tx) {
                  // Filter Bulan
                  final sameMonth =
                      tx.tanggal.month == _focusedMonth.month &&
                      tx.tanggal.year == _focusedMonth.year;

                  // Filter Bank
                  final bank = normalize(tx.bank);
                  final sameBank =
                      selectedBank == "semua" || bank == selectedBank;

                  return sameMonth && sameBank;
                }).toList();

                // Hitung Transaksi
                final pemasukan = filtered
                    .where((tx) => tx.tipe == "pemasukan")
                    .fold(0.0, (sum, tx) => sum + tx.nominal);

                final pengeluaran = filtered
                    .where((tx) => tx.tipe == "pengeluaran")
                    .fold(0.0, (sum, tx) => sum + tx.nominal);

                final saldo = pemasukan - pengeluaran;

                final Map<DateTime, List<TransaksiModel>> grouped = {};

                for (var tx in filtered) {
                  final day = DateTime(
                    tx.tanggal.year,
                    tx.tanggal.month,
                    tx.tanggal.day,
                  );
                  grouped.putIfAbsent(day, () => []).add(tx);
                }

                final days = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Card Saldo
                          cardSaldo(pemasukan, pengeluaran, saldo),

                          const SizedBox(height: 20),

                          // Dropdown Bank
                          cardBank(allBanks),

                          const SizedBox(height: 30),

                          // Filter Bulan
                          cardBulan(filtered.length),

                          const SizedBox(height: 30),

                          filtered.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    selectedBank == "semua"
                                        ? "Belum ada transaksi"
                                        : "Belum ada transaksi di Bank '${selectedBank.toUpperCase()}'",
                                    style: abuReguler15,
                                  ),
                                )
                              : listTransaksi(days, grouped),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),

      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Card Saldo
  Widget cardSaldo(double pemasukan, double pengeluaran, double saldo) {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hijauTerang, hijauMedium],
        ),
        boxShadow: [
          BoxShadow(
            color: hitam.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pemasukan', style: hitamBold15),
            const SizedBox(height: 10),
            Text(currency.format(pemasukan), style: hijauBold15),
            const SizedBox(height: 10),
            Text('Pengeluaran', style: hitamBold15),
            const SizedBox(height: 10),
            Text(currency.format(pengeluaran), style: merahBold15),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Total', style: hitamBold15),
                IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: hitam,
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
              style: hitamBold15,
            ),
          ],
        ),
      ),
    );
  }

  // Dropdown Bank
  Widget cardBank(List<String> banks) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: hijauSimpan,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedBank,
          dropdownColor: hijauSimpan,
          icon: Icon(Icons.arrow_drop_down, color: putih),
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedBank = value);
          },
          items: banks.map((bank) {
            return DropdownMenuItem(
              value: bank,
              child: Text(bank.toUpperCase(), style: putihReguler15),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Card Bulan
  Widget cardBulan(int total) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: hijauSimpan,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: putih),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  );
                });
              },
            ),
            Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: putihReguler15,
                ),
                const SizedBox(height: 5),
                Text("$total Transaksi", style: abuReguler15),
              ],
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.chevron_right, color: putih),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // List Transaksi
  Widget listTransaksi(
    List<DateTime> days,
    Map<DateTime, List<TransaksiModel>> grouped,
  ) {
    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          selectedBank == "semua"
              ? "Belum ada transaksi"
              : "Belum ada transaksi di Bank '${selectedBank.toUpperCase()}'",
          style: abuReguler15,
        ),
      );
    }

    return Column(
      children: days.map((day) {
        final list = grouped[day]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: putih,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardstroke, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 11,
                        right: 11,
                        top: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              DateFormat('dd MMM yyyy').format(day),
                              style: hitamReguler12,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            currency.format(
                              list
                                  .where((e) => e.tipe == "pemasukan")
                                  .fold(0.0, (s, e) => s + e.nominal),
                            ),
                            style: hijauBold12,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Text(
                              currency.format(
                                list
                                    .where((e) => e.tipe == "pengeluaran")
                                    .fold(0.0, (s, e) => s + e.nominal),
                              ),
                              style: merahBold12,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),
                    Divider(color: cardstroke, thickness: 1),
                    Column(
                      children: list.map((tx) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditTransaksi(tx: tx),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(11.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: tx.tipe == "pemasukan"
                                        ? hijauPemasukan
                                        : merahPengeluaran,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      tx.tipe == "pemasukan"
                                          ? Icons.call_made
                                          : Icons.call_received,
                                      color: putih,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        capitalize(tx.judul),
                                        style: hitamBold15,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        capitalize(tx.kategori),
                                        style: hitamReguler12,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        tx.bank.toUpperCase(),
                                        style: hitamReguler12,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  currency.format(tx.nominal),
                                  style: tx.tipe == "pemasukan"
                                      ? hijauBold12
                                      : merahBold12,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Floating Action Button
  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: hijauSimpan,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TambahTransaksi()),
        );
      },
      child: Icon(Icons.add, color: putih),
    );
  }
}
