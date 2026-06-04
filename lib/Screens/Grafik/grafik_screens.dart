import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class GrafikScreens extends StatefulWidget {
  const GrafikScreens({super.key});

  @override
  State<GrafikScreens> createState() => _GrafikScreensState();
}

class _GrafikScreensState extends State<GrafikScreens> {
  // PROPERTI DAN INISIALISASI STATE
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _focusedMonth = DateTime.now();
  String _viewMode = "Bulanan";
  int _selectedWeek = 1;
  DateTime _selectedDay = DateTime.now();

  late ScrollController _hariController;

  @override
  void initState() {
    super.initState();
    _hariController = ScrollController();
    _selectedDay = DateTime.now();
    _focusedMonth = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDay();
    });
  }

  @override
  void dispose() {
    _hariController.dispose();
    super.dispose();
  }

  // FUNGSI ANIMASI SCROLL UNTUK FILTER HARIAN
  void _scrollToSelectedDay() {
    if (!mounted) return;

    double itemWidth = 78;
    double screenWidth = MediaQuery.of(context).size.width;

    double targetOffset =
        ((_selectedDay.day - 1) * itemWidth) -
        (screenWidth / 2) +
        (itemWidth / 2);

    if (targetOffset < 0) targetOffset = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_hariController.hasClients) {
        final maxExtent = _hariController.position.maxScrollExtent;

        if (targetOffset > maxExtent) {
          targetOffset = maxExtent;
        }

        if (_hariController.hasClients) {
          _hariController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  // FUNGSI HELPER UTILITY
  String capitalize(String? text) {
    if (text == null || text.trim().isEmpty) {
      return '';
    }

    return text[0].toUpperCase() + text.substring(1);
  }

  // WIDGET UTAMA (BUILD METHOD)
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: putih,
        body: const Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return Scaffold(
      backgroundColor: putih,
      body: SafeArea(
        child: StreamBuilder<List<TransaksiModel>>(
          stream: _firestoreService.gettransaksi(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Terjadi kesalahan'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = snapshot.data ?? [];

            // Filter Primer: Berdasarkan Bulan dan Tahun Berjalan
            List<TransaksiModel> month = all.where((tx) {
              return tx.tanggal.month == _focusedMonth.month &&
                  tx.tanggal.year == _focusedMonth.year;
            }).toList();

            List<TransaksiModel> finalFiltered = month;

            // Filter Sekunder: Berdasarkan View Mode Harian
            if (_viewMode == "Harian") {
              finalFiltered = month.where((tx) {
                return tx.tanggal.day == _selectedDay.day &&
                    tx.tanggal.month == _selectedDay.month &&
                    tx.tanggal.year == _selectedDay.year;
              }).toList();
            }

            // Filter Sekunder: Berdasarkan View Mode Mingguan
            if (_viewMode == "Mingguan") {
              finalFiltered = month.where((tx) {
                final d = tx.tanggal.day;
                if (_selectedWeek == 1) return d >= 1 && d <= 7;
                if (_selectedWeek == 2) return d >= 8 && d <= 14;
                if (_selectedWeek == 3) return d >= 15 && d <= 21;
                return d >= 22 && d <= 31;
              }).toList();
            }

            // Pengurutan Data Transaksi Terbaru
            finalFiltered.sort((a, b) => b.tanggal.compareTo(a.tanggal));

            // Batasi tampilan maksimal hanya 3 item transaksi terbaru
            final displayData = finalFiltered.take(3).toList();

            double pemasukan = 0;
            double pengeluaran = 0;

            // Perhitungan saldo dibersihkan dari duplikasi (loop ganda)
            // dan nominal pengeluaran diproteksi dengan check .isFinite
            for (final tx in finalFiltered) {
              final tipe = (tx.tipe).trim().toLowerCase();
              final nominalValid = tx.nominal.isFinite ? tx.nominal : 0.0;

              if (tipe == "pemasukan") {
                pemasukan += nominalValid;
              } else if (tipe == "pengeluaran") {
                pengeluaran += nominalValid;
              }
            }

            final total = pemasukan + pengeluaran;

            final currencyFormatter = NumberFormat.currency(
              locale: 'id',
              symbol: 'Rp.',
              decimalDigits: 0,
            );

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterBulanan(),
                    const SizedBox(height: 15),
                    if (_viewMode == "Harian") _buildFilterHarian(),
                    if (_viewMode == "Mingguan") _buildFilterMingguan(),
                    Center(
                      child: _buildGrafikContent(
                        total,
                        pemasukan,
                        pengeluaran,
                        currencyFormatter,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _datasaldo(pemasukan, pengeluaran),
                    const SizedBox(height: 15),
                    _dataTransaksiList(displayData, currencyFormatter),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // FILTER BULANAN (DROPDOWN & CHEVRON)
  Widget _buildFilterBulanan() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: hijauSimpan,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: putih),
            onPressed: () => setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month - 1,
              );

              final daysInMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
                0,
              ).day;

              if (_selectedDay.day > daysInMonth) {
                _selectedDay = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  daysInMonth,
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToSelectedDay();
              });
            }),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: putihReguler15,
              ),
              DropdownButton<String>(
                value: _viewMode,
                isDense: true,
                dropdownColor: hijauSimpan,
                underline: const SizedBox(),
                iconEnabledColor: putih,
                style: abuReguler15,
                items: ["Harian", "Mingguan", "Bulanan"]
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: putihReguler15),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val == null || !mounted) return;

                  setState(() {
                    _viewMode = val;
                    if (_viewMode == "Harian") {
                      _selectedDay = DateTime.now();
                      _focusedMonth = DateTime.now();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToSelectedDay();
                      });
                    }
                  });
                },
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: putih),
            onPressed: () => setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
              );

              final daysInMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
                0,
              ).day;

              if (_selectedDay.day > daysInMonth) {
                _selectedDay = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  daysInMonth,
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToSelectedDay();
              });
            }),
          ),
        ],
      ),
    );
  }

  // FILTER HARIAN HORIZONTAL SCROLL
  Widget _buildFilterHarian() {
    final int daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;

    return SizedBox(
      height: 75,
      child: ListView(
        controller: _hariController,
        scrollDirection: Axis.horizontal,
        children: List.generate(daysInMonth, (index) {
          final int day = index + 1;
          final DateTime currentDate = DateTime(
            _focusedMonth.year,
            _focusedMonth.month,
            day,
          );

          final bool isSelected =
              _selectedDay.day == currentDate.day &&
              _selectedDay.month == currentDate.month &&
              _selectedDay.year == currentDate.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = currentDate;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToSelectedDay();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? hijauSimpan : putih,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: hijauSimpan, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.toString(),
                    style: isSelected ? putihBold15 : hitamBold15,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM').format(currentDate),
                    style: isSelected ? putihBold15 : hitamBold15,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // FILTER MINGGUAN ROW LAYOUT
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
                  color: _selectedWeek == w ? hijauSimpan : putih,
                  border: Border.all(color: hijauSimpan, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      "Minggu $w",
                      style: _selectedWeek == w ? putihBold15 : hitamBold15,
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

  // PIE CHART GRAFIK UTAMA (FL_CHART INTEGRATION)
  Widget _buildGrafikContent(
    double total,
    double pemasukan,
    double pengeluaran,
    NumberFormat currencyFormatter,
  ) {
    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                color: hijauTerang,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("SELISIH", style: hitamReguler15),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Text(
                        currencyFormatter.format(pemasukan - pengeluaran),
                        style: hitamBold12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: hijauTerang,
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
                        value: (pemasukan > 0 && pemasukan.isFinite)
                            ? pemasukan
                            : 0.01,
                        color: hijauSimpan,
                        title: "",
                        radius: 20,
                        badgeWidget: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: putih,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Masuk",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hijauSimpan,
                            ),
                          ),
                        ),
                        badgePositionPercentageOffset: 1.5,
                      ),
                      PieChartSectionData(
                        value: (pengeluaran > 0 && pengeluaran.isFinite)
                            ? pengeluaran
                            : 0.01,
                        color: merahPengeluaran,
                        title: "",
                        radius: 20,
                        badgeWidget: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: putih,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Keluar",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: merahPengeluaran,
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
                    Text("SELISIH", style: hitamReguler12),
                    const SizedBox(height: 4),
                    FittedBox(
                      child: Text(
                        currencyFormatter.format(pemasukan - pengeluaran),
                        style: hitamBold12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // DATA SALDO (PEMASUKAN & PENGELUARAN ROW BOXES)
  Widget _datasaldo(double pemasukan, double pengeluaran) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dataTotalTransaksi(
          "Pemasukan",
          pemasukan,
          hijauSimpan,
          Icons.call_made,
        ),
        const SizedBox(width: 16),
        _dataTotalTransaksi(
          "Pengeluaran",
          pengeluaran,
          merahPengeluaran,
          Icons.call_received,
        ),
      ],
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
          color: putih,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: "Pemasukan" == label ? hijauSimpan : merahPengeluaran,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: hitam.withOpacity(0.5),
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
              child: Icon(icon, color: putih),
            ),
            const SizedBox(height: 12),
            Text(label, style: hitamReguler15),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp.',
                  decimalDigits: 0,
                ).format(amount),
                style: label == "Pemasukan" ? hijauBold15 : merahBold15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LIST VIEW DAFTAR TRANSAKSI
  Widget _dataTransaksiList(List<TransaksiModel> list, NumberFormat fmt) {
    if (list.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Daftar Transaksi", style: hitamReguler15),
          const SizedBox(height: 15),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Belum ada data transaksi", style: abuReguler15),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Daftar Transaksi", style: hitamReguler15),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final tx = list[index];
            final isPemasukan = tx.tipe.trim().toLowerCase() == "pemasukan";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                            DateFormat('dd MMMM yyyy').format(tx.tanggal),
                            style: hitamReguler12,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            fmt.format(tx.nominal),
                            style: isPemasukan ? hijauBold12 : merahBold12,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Divider(color: cardstroke, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.all(11.0),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isPemasukan
                                ? hijauPemasukan
                                : merahPengeluaran,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isPemasukan
                                  ? Icons.call_made
                                  : Icons.call_received,
                              color: putih,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.judul,
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
                                tx.bank.isEmpty ? "-" : tx.bank.toUpperCase(),
                                style: hitamReguler12,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                            fmt.format(tx.nominal),
                            style: isPemasukan ? hijauBold12 : merahBold12,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
