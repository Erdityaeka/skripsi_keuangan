import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';

class GrafikScreens extends StatefulWidget {
  const GrafikScreens({super.key});

  @override
  State<GrafikScreens> createState() => _GrafikScreensState();
}

class _GrafikScreensState extends State<GrafikScreens> {

  // Menyimpan bulan saat dipilih
  DateTime _focusedMonth = DateTime.now();
  String _viewMode = "Bulanan";
  int _selectedWeek = 1;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: white,
      appBar: _buidAppbar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(user!.uid)
            .collection('transaksi')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!.docs.map((doc) {
            return TransaksiModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          // Filter Bulan
          List<TransaksiModel> month = all.where((tx) {
            return tx.tanggal.month == _focusedMonth.month &&
                tx.tanggal.year == _focusedMonth.year;
          }).toList();

          List<TransaksiModel> finalFiltered = month;

          if (_viewMode == "Mingguan") {
            finalFiltered = month.where((tx) {
              int d = tx.tanggal.day;

              if (_selectedWeek == 1) return d >= 1 && d <= 7;
              if (_selectedWeek == 2) return d >= 8 && d <= 14;
              if (_selectedWeek == 3) return d >= 15 && d <= 21;
              return d >= 22 && d <= 31;
            }).toList();
          }

          finalFiltered.sort((a, b) => b.tanggal.compareTo(a.tanggal));
          final displayData = finalFiltered.take(3).toList();

          double pemasukan = 0;
          double pengeluaran = 0;

          for (var tx in finalFiltered) {
            if (tx.tipe == "pemasukan") {
              pemasukan += tx.nominal;
            } else {
              pengeluaran += tx.nominal;
            }
          }

          double total = pemasukan + pengeluaran;

          final currencyFormatter = NumberFormat.currency(
            locale: 'id',
            symbol: 'Rp',
            decimalDigits: 0,
          );

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildFilterBulanan(),
                  const SizedBox(height: 15),
                  if (_viewMode == "Mingguan") _buildFilterMingguan(),
                  const SizedBox(height: 25),

                  if (total == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Column(
                        children: [
                          Icon(
                            Icons.leaderboard,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Tidak ada data pada periode ini",
                            style: greyReguler,
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: red,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 8,
                              centerSpaceRadius: 75,
                              sections: [
                                PieChartSectionData(
                                  value: pemasukan,
                                  color: green,
                                  title: "",
                                  radius: 20,
                                  badgeWidget: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: green.withOpacity(0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: green.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      "Masuk",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: green,
                                      ),
                                    ),
                                  ),
                                  badgePositionPercentageOffset: 1.5,
                                ),
                                PieChartSectionData(
                                  value: pengeluaran,
                                  color: yellow,
                                  title: "",
                                  radius: 20,
                                  badgeWidget: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: yellow.withOpacity(0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: yellow.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      "Keluar",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: yellow,
                                      ),
                                    ),
                                  ),
                                  badgePositionPercentageOffset: 1.5,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("SELISIH", style: whiteBold),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(
                                  pemasukan - pengeluaran,
                                ),
                                style: whiteBold,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    Row(
                      children: [
                        _dataTotalTransaksi(
                          "Pemasukan",
                          pemasukan,
                          green,
                          Icons.call_made,
                        ),
                        const SizedBox(width: 16),
                        _dataTotalTransaksi(
                          "Pengeluaran",
                          pengeluaran,
                          yellow,
                          Icons.call_received,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Daftar Transaksi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    _dataTransaksiList(displayData, currencyFormatter),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buidAppbar() {
    return AppBar(
      backgroundColor: white,
      centerTitle: true,
      title: Text("Grafik", style: redBold20),
      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  Widget _buildFilterBulanan() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: red,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: white),
            onPressed: () => setState(
              () => _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month - 1,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: whiteBold,
              ),
              DropdownButton<String>(
                value: _viewMode,
                isDense: true,
                dropdownColor: red,
                underline: const SizedBox(),
                iconEnabledColor: grey,
                style: greyReguler,

                items: ["Mingguan", "Bulanan"]
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: whiteReguler),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _viewMode = val!),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: white),
            onPressed: () => setState(
              () => _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMingguan() {
    return Row(
      children: [1, 2, 3, 4].map((w) {
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedWeek = w),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedWeek == w ? red : Colors.transparent,
                  border: Border.all(color: red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      "Minggu $w",
                      style: _selectedWeek == w ? whiteReguler : blackReguler12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dataTotalTransaksi(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: red, width: 3),
          boxShadow: [
            BoxShadow(
              color: black.withOpacity(0.5), // biar tidak terlalu pekat
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: white),
            ),
            const SizedBox(height: 12),
            Text(label, style: blackReguler),
            SizedBox(height: 5),
            Text(
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp. ',
                decimalDigits: 0,
              ).format(amount),
              style: label == "Pemasukan" ? greenBold15 : yellowBold15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataTransaksiList(List<TransaksiModel> list, NumberFormat fmt) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final tx = list[index];
            final isPemasukan = tx.tipe == "pemasukan";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: red, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: black.withOpacity(0.5), // biar tidak terlalu pekat
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                            DateFormat('dd MMMM yyyy').format(tx.tanggal),
                            style: redReguler12,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          flex: 2,
                          child: Text(
                            fmt.format(tx.nominal),
                            style: isPemasukan ? greenBold12 : yellowBold12,
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
                  Padding(
                    padding: const EdgeInsets.all(11.0),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isPemasukan ? green : yellow,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isPemasukan
                                  ? Icons.call_made
                                  : Icons.call_received,
                              color: white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
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
                              tx.kategori.toUpperCase(),
                              style: redReguler12,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              tx.bank.toUpperCase(),
                              style: redReguler12,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          fmt.format(tx.nominal),
                          style: isPemasukan ? greenBold12 : yellowBold12,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
