import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  // STATE
  bool _isPasswordVisible = false;
  DateTime _focusedMonth = DateTime.now();

  final currency = NumberFormat.simpleCurrency(locale: 'id', decimalDigits: 0);

  String selectedBank = "semua";
  List<String> allBanks = ["semua"];

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
      appBar: _buildAppbar(context),

      // Menampilkan Data Transaksi
      body: StreamBuilder<List<TransaksiModel>>(
        stream: firestoreService.gettransaksi(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final transactions = snapshot.data!;

          // Menempilkan Data Bank
          return StreamBuilder<List<String>>(
            stream: firestoreService.getBank(),

            builder: (context, bankSnap) {
              if (!bankSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Data Dari Kolekesi Bank
              final bankMaster = bankSnap.data!
                  .map((e) => normalize(e))
                  .where((e) => e.isNotEmpty)
                  .toSet();

              // bank dari transaksi
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
                        cardtransaksi(pemasukan, pengeluaran, saldo),

                        const SizedBox(height: 20),

                        // Dropwodn Bank
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
                                  style: blackBold15,
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

      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // APPBAR
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
      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  // CARD
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

  // DROPDOWN BANK
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

  // BULAN
  Widget cardBulan(int total) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: white),
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
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: whiteBold,
                ),
                SizedBox(height: 10),
                Text("$total Transaksi", style: greyReguler),
              ],
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.chevron_right, color: white),
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

  // LIST
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
          style: blackBold15,
        ),
      );
    }

    return Column(
      children: days.map((day) {
        final list = grouped[day]!;

        return Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: red, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: black.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //HEADER
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
                            style: redReguler12,
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
                          style: greenBold12,
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
                            style: yellowBold12,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),
                  Divider(color: red, thickness: 1),

                  //LIST ITEM
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
                                      ? green
                                      : yellow,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    tx.tipe == "pemasukan"
                                        ? Icons.call_made
                                        : Icons.call_received,
                                    color: white,
                                    size: 18,
                                  ),
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
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      tx.kategori,
                                      style: redReguler12,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      tx.bank,
                                      style: redReguler12,
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
                                    ? greenBold12
                                    : yellowBold12,
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
        );
      }).toList(),
    );
  }

  // Floating Action Button
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
