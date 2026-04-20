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
  DateTime _focusedMonth = DateTime.now();
  String _viewMode = "Bulanan";
  int _selectedWeek = 1;

  // ================= AMBIL DATA =================
  Stream<List<TransaksiModel>> getTransaksi() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('user')
        .doc(user.uid)
        .collection('transaksi')
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransaksiModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================= APPBAR =================
      appBar: AppBar(
        backgroundColor: white,
        centerTitle: true,
        title: Text("Grafik", style: redBold20),
      ),

      // ================= BODY =================
      body: StreamBuilder<List<TransaksiModel>>(
        stream: getTransaksi(),
        builder: (context, snapshot) {
          // ERROR
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];

          // FILTER BULAN
          final monthData = data.where((tx) {
            return tx.tanggal.month == _focusedMonth.month &&
                tx.tanggal.year == _focusedMonth.year;
          }).toList();

          // FILTER MINGGU
          List<TransaksiModel> finalData = monthData;

          if (_viewMode == "Mingguan") {
            finalData = monthData.where((tx) {
              final d = tx.tanggal.day;
              if (_selectedWeek == 1) return d <= 7;
              if (_selectedWeek == 2) return d <= 14;
              if (_selectedWeek == 3) return d <= 21;
              return d > 21;
            }).toList();
          }

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ================= HEADER =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildMonthNavigator(),
                ),

                const SizedBox(height: 20),

                if (_viewMode == "Mingguan") _buildWeekSelector(),

                const SizedBox(height: 20),

                // ================= ISI =================
                Expanded(
                  child: finalData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bar_chart_rounded,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Tidak ada data pada periode ini",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildPieChart(finalData),

                              const SizedBox(height: 30),

                              _buildSummary(finalData),

                              const SizedBox(height: 20),

                              _buildList(finalData),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= NAVIGASI BULAN =================
  Widget _buildMonthNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: redblack,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month - 1,
              );
            }),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'id').format(_focusedMonth),
                style: whiteReguler,
              ),

              const SizedBox(height: 2),

              Theme(
                data: Theme.of(
                  context,
                ).copyWith(visualDensity: VisualDensity.compact),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _viewMode,
                    dropdownColor: red,
                    isDense: true,
                    iconEnabledColor: white,
                    items: ["Bulanan", "Mingguan"]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: whiteReguler),
                          ),
                        )
                        .toList(),

                    onChanged: (val) => setState(() => _viewMode = val!),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: white),
            onPressed: () => setState(() {
              _focusedMonth = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
              );
            }),
          ),
        ],
      ),
    );
  }

  // ================= SELECT WEEK =================
  Widget _buildWeekSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [1, 2, 3, 4].map((w) {
        final selected = _selectedWeek == w;
        return GestureDetector(
          onTap: () => setState(() => _selectedWeek = w),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? red : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Minggu $w",
              style: selected ? whiteReguler : blackReguler,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ================= PIE =================
  Widget _buildPieChart(List<TransaksiModel> list) {
    double income = 0;
    double expense = 0;

    for (var tx in list) {
      if (tx.tipe == "income") {
        income += tx.nominal;
      } else {
        expense += tx.nominal;
      }
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(value: income, color: Colors.green),
            PieChartSectionData(value: expense, color: Colors.red),
          ],
        ),
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _buildSummary(List<TransaksiModel> list) {
    double income = 0;
    double expense = 0;

    for (var tx in list) {
      if (tx.tipe == "income") {
        income += tx.nominal;
      } else {
        expense += tx.nominal;
      }
    }

    return Row(
      children: [
        Expanded(child: Text("Income: Rp${income.toInt()}")),
        Expanded(child: Text("Expense: Rp${expense.toInt()}")),
      ],
    );
  }

  // ================= LIST =================
  Widget _buildList(List<TransaksiModel> list) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final tx = list[i];
        return ListTile(
          title: Text(tx.judul),
          subtitle: Text(DateFormat('dd MMM yyyy').format(tx.tanggal)),
          trailing: Text("Rp${tx.nominal.toInt()}"),
        );
      },
    );
  }
}
