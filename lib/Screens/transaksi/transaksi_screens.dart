import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/models/sumberdana_model.dart';
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

  String selectedSumberdana = "semua";
  String selectedKategori = "semua";
  String selectedJenis = "semua";

  List<String> allSumberdana = ["semua"];
  List<String> allKategori = ["semua"];
  List<String> allJenis = ["semua"];

  String _lastAlertedSumberdana = "";
  int _lastAlertedMonth = 0;

  final firestoreService = FirestoreService();

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  String normalize(String? val) {
    return (val ?? '').toLowerCase().trim();
  }

  void _showMinusAlert(String sumberdanaName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: putih,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: rednotif, size: 28),
              const SizedBox(width: 10),
              Text("Saldo Peringatan", style: hitamBold20),
            ],
          ),
          content: Text(
            "Saldo anda minus di sumber dana '$sumberdanaName', mohon input pemasukan terlebih dahulu.",
            style: teksdialogBold15,
          ),
          actions: [
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: merahHapus,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK", style: putihBold15),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showBackButton
          ? AppBar(
              backgroundColor: putih,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: hitam),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text("Daftar Transaksi", style: hitamBold20),
            )
          : null,
      body: SafeArea(
        child: StreamBuilder<List<TransaksiModel>>(
          stream: firestoreService.gettransaksi(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final transactions = snapshot.data!;

            return StreamBuilder<List<SumberdanaModel>>(
              stream: firestoreService.getSumberdanaModels(),
              builder: (context, sumberdanaSnap) {
                if (!sumberdanaSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sumberdanaMaster = sumberdanaSnap.data!
                    .map((e) => normalize(e.nama))
                    .where((e) => e.isNotEmpty)
                    .toSet();

                final sumberdanaFromTx = transactions
                    .map((tx) => normalize(tx.sumberdana))
                    .where((e) => e.isNotEmpty)
                    .toSet();

                allSumberdana = [
                  "semua",
                  ...{...sumberdanaMaster, ...sumberdanaFromTx}.toList()
                    ..sort(),
                ];

                if (!allSumberdana.contains(selectedSumberdana)) {
                  selectedSumberdana = "semua";
                }

                final jenisMaster = sumberdanaSnap.data!
                    .map((e) => normalize(e.jenis))
                    .where((e) => e.isNotEmpty)
                    .toSet();

                allJenis = ["semua", ...jenisMaster.toList()..sort()];

                if (!allJenis.contains(selectedJenis)) {
                  selectedJenis = "semua";
                }

                return StreamBuilder<List<dynamic>>(
                  stream: firestoreService.getCategoryModels(),
                  builder: (context, kategoriSnap) {
                    if (!kategoriSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final kategoriMaster = kategoriSnap.data!
                        .map((e) => normalize(e.nama))
                        .where((e) => e.isNotEmpty)
                        .toSet();

                    allKategori = ["semua", ...kategoriMaster.toList()..sort()];

                    if (!allKategori.contains(selectedKategori)) {
                      selectedKategori = "semua";
                    }

                    final currentSumberdana = selectedSumberdana;
                    final currentKategori = selectedKategori;
                    final currentJenis = selectedJenis;

                    final mapSumberdanaKeJenis = {
                      for (var sd in sumberdanaSnap.data!)
                        normalize(sd.nama): normalize(sd.jenis),
                    };

                    final filtered = transactions.where((tx) {
                      final sameMonth =
                          tx.tanggal.month == _focusedMonth.month &&
                          tx.tanggal.year == _focusedMonth.year;

                      final sumberdana = normalize(tx.sumberdana);
                      final kategori = normalize(tx.kategori);
                      final jenisSDAplikasi =
                          (mapSumberdanaKeJenis[sumberdana] ?? '').trim();

                      bool matchSumberdana =
                          currentSumberdana == "semua" ||
                          sumberdana == currentSumberdana;
                      bool matchKategori =
                          currentKategori == "semua" ||
                          kategori == currentKategori;
                      bool matchJenis =
                          currentJenis == "semua" ||
                          jenisSDAplikasi == currentJenis.trim();

                      return sameMonth &&
                          matchSumberdana &&
                          matchKategori &&
                          matchJenis;
                    }).toList();

                    final pemasukan = filtered
                        .where(
                          (tx) => tx.tipe.trim().toLowerCase() == "pemasukan",
                        )
                        .fold(0.0, (sum, tx) => sum + tx.nominal);

                    final pengeluaran = filtered
                        .where(
                          (tx) => tx.tipe.trim().toLowerCase() == "pengeluaran",
                        )
                        .fold(0.0, (sum, tx) => sum + tx.nominal);

                    final saldo = pemasukan - pengeluaran;

                    // LOGIKA ALERT MINUS PER BULAN
                    final txBulanIni = transactions.where((tx) {
                      return tx.tanggal.month == _focusedMonth.month &&
                          tx.tanggal.year == _focusedMonth.year;
                    }).toList();

                    Map<String, double> saldoPerSumberDana = {};
                    for (var tx in txBulanIni) {
                      final sdNama = normalize(tx.sumberdana);
                      if (sdNama.isEmpty) continue;

                      final nominal = tx.nominal;
                      final tipe = tx.tipe.trim().toLowerCase();

                      double perubahan = (tipe == "pemasukan")
                          ? nominal
                          : -nominal;
                      saldoPerSumberDana[sdNama] =
                          (saldoPerSumberDana[sdNama] ?? 0.0) + perubahan;
                    }

                    String sumberDanaMinus = "";
                    saldoPerSumberDana.forEach((namaSD, saldoSD) {
                      if (saldoSD < 0 && sumberDanaMinus.isEmpty) {
                        sumberDanaMinus = namaSD;
                      }
                    });

                    if (sumberDanaMinus.isNotEmpty &&
                        (_lastAlertedSumberdana != sumberDanaMinus ||
                            _lastAlertedMonth != _focusedMonth.month)) {
                      _lastAlertedSumberdana = sumberDanaMinus;
                      _lastAlertedMonth = _focusedMonth.month;

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showMinusAlert(sumberDanaMinus.toUpperCase());
                      });
                    } else if (sumberDanaMinus.isEmpty) {
                      _lastAlertedSumberdana = "";
                      _lastAlertedMonth = 0;
                    }

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
                              cardSaldo(pemasukan, pengeluaran, saldo),
                              const SizedBox(height: 20),

                              // DIPERBAIKI: Row Filter Sejajar Horizontal 50:50 Pas Kayak di Home
                              Row(
                                children: [
                                  Expanded(
                                    child: cardSumberdana(allSumberdana),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: cardKategori()),
                                ],
                              ),

                              const SizedBox(height: 30),
                              cardBulan(filtered.length),
                              const SizedBox(height: 30),
                              filtered.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                        "Belum ada transaksi yang cocok dengan filter",
                                        style: abuReguler15,
                                        textAlign: TextAlign.center,
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
            );
          },
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Card Saldo (Sama Persis Kayak Di Home, Ada cardJenis Kanan Atas)
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
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pemasukan', style: hitamBold15),
                cardJenis(), // Diposisikan menempel kanan atas
              ],
            ),
            const SizedBox(height: 5),
            Text(currency.format(pemasukan), style: hijauBold15),

            const SizedBox(height: 10),

            Text('Pengeluaran', style: hitamBold15),
            const SizedBox(height: 5),
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

  // Dropdown Sumber Dana (Dengan menuMaxHeight)
  Widget cardSumberdana(List<String> sumberdanaList) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: hijauSimpan,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: ValueKey('sd_${sumberdanaList.length}'),
            value: selectedSumberdana,
            dropdownColor: hijauSimpan,
            icon: Icon(Icons.arrow_drop_down, color: putih),
            isExpanded: true,
            menuMaxHeight: 200, // Membatasi scroller agar tidak mentok bawah
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedSumberdana = value);
            },
            items: sumberdanaList.map((sumberdana) {
              return DropdownMenuItem(
                value: sumberdana,
                child: Text(
                  sumberdana.toUpperCase(),
                  style: putihReguler15.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Dropdown Jenis Sumber Dana 
  Widget cardJenis() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        key: ValueKey(allJenis.length),
        value: selectedJenis,
        dropdownColor: hijauMedium,
        icon: Icon(Icons.arrow_drop_down, color: hitam),
        isExpanded: false,
        isDense: true,
        onChanged: (value) {
          if (value == null) return;
          setState(() => selectedJenis = value);
        },
        items: allJenis.map((jenis) {
          return DropdownMenuItem(
            value: jenis,
            child: Text(
              jenis == "semua" ? "SEMUA JENIS" : jenis.toUpperCase(),
              style: selectedJenis == jenis ? hitamBold12 : hitamBold12,
            ),
          );
        }).toList(),
      ),
    );
  }

  // Dropdown Kategori (Dengan menuMaxHeight)
  Widget cardKategori() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: hijauSimpan,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: ValueKey('kt_${allKategori.length}'),
            value: selectedKategori,
            dropdownColor: hijauSimpan,
            icon: Icon(Icons.arrow_drop_down, color: putih),
            isExpanded: true,
            menuMaxHeight: 200, // Membatasi scroller agar tidak mentok bawah
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedKategori = value);
            },
            items: allKategori.map((kategori) {
              return DropdownMenuItem(
                value: kategori,
                child: Text(
                  kategori.toUpperCase(),
                  style: putihReguler15.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

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
            const Spacer(),
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
            const Spacer(),
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

  Widget listTransaksi(
    List<DateTime> days,
    Map<DateTime, List<TransaksiModel>> grouped,
  ) {
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
                                  .where(
                                    (e) =>
                                        e.tipe.trim().toLowerCase() ==
                                        "pemasukan",
                                  )
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
                                    .where(
                                      (e) =>
                                          e.tipe.trim().toLowerCase() ==
                                          "pengeluaran",
                                    )
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
                        final bool isPemasukan =
                            tx.tipe.trim().toLowerCase() == "pemasukan";

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
                                        tx.sumberdana.toUpperCase(),
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
                                  style: isPemasukan
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

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: hijauSimpan,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TambahTransaksi()),
        );
      },
      child: Icon(Icons.add, color: putih),
    );
  }
}
