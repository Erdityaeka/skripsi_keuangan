import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Screens/transaksi/edit_transaksi.dart';
import 'package:skripsi_keuangan/Screens/transaksi/transaksi_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/models/sumberdana_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

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

  final firestoreService = FirestoreService();

  String selectedSumberdana = "semua";
  String selectedKategori = "semua";
  String selectedJenis = "semua";

  bool _isPasswordVisible = false;

  List<String> allSumberdana = ["semua"];
  List<String> allKategori = ["semua"];
  List<String> allJenis = ["semua"];

  Future<void> _refreshData() async {
    setState(() {});
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

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
      body: StreamBuilder<List<TransaksiModel>>(
        stream: firestoreService.gettransaksi(),
        builder: (context, txSnap) {
          if (!txSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = txSnap.data!;

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

              final sumberdanaFromTx = all
                  .map((tx) => normalize(tx.sumberdana))
                  .where((e) => e.isNotEmpty)
                  .toSet();

              allSumberdana = [
                "semua",
                ...{...sumberdanaMaster, ...sumberdanaFromTx}.toList()..sort(),
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

                  final filtered = all.where((tx) {
                    final sumberdana = normalize(tx.sumberdana);
                    final kategori = normalize(tx.kategori);
                    final jenisSDAplikasi =
                        mapSumberdanaKeJenis[sumberdana] ?? "";

                    bool matchSumberdana =
                        currentSumberdana == "semua" ||
                        sumberdana == currentSumberdana;
                    bool matchKategori =
                        currentKategori == "semua" ||
                        kategori == currentKategori;
                    bool matchJenis =
                        currentJenis == "semua" ||
                        jenisSDAplikasi == currentJenis;

                    return matchSumberdana && matchKategori && matchJenis;
                  }).toList();

                  filtered.sort((a, b) => b.tanggal.compareTo(a.tanggal));

                  final recent = filtered.take(3).toList();

                  double pemasukan = 0;
                  double pengeluaran = 0;

                  for (var tx in filtered) {
                    if (tx.tipe.trim().toLowerCase() == "pemasukan") {
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
                            cardSaldo(pemasukan, pengeluaran, saldo),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(child: cardSumberdana()),
                                const SizedBox(width: 12),
                                Expanded(child: cardKategori()),
                              ],
                            ),

                            const SizedBox(height: 30),
                            listTransaksi(recent),
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
    );
  }

  PreferredSizeWidget _buildAppbar(context, String nama) {
    return AppBar(
      backgroundColor: putih,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Hi,', style: hitamBold15),
                const SizedBox(width: 5),
                Text(capitalize(nama), style: hitamBold15),
                const SizedBox(width: 5),
                Text('👋,', style: hitamBold15),
              ],
            ),
            const SizedBox(height: 5),
            Text('Ayo mulai kelola uang dengan baik!', style: hitamBold15),
          ],
        ),
      ),
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

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
                cardJenis(),
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

  Widget cardSumberdana() {
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
            key: ValueKey(allSumberdana.length),
            value: selectedSumberdana,
            dropdownColor: hijauSimpan,
            icon: Icon(Icons.arrow_drop_down, color: putih),
            isExpanded: true,
            menuMaxHeight: 200,
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedSumberdana = value);
            },
            items: allSumberdana.map((sumberdana) {
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
            key: ValueKey(allKategori.length),
            value: selectedKategori,
            dropdownColor: hijauSimpan,
            icon: Icon(Icons.arrow_drop_down, color: putih),
            isExpanded: true,
            menuMaxHeight: 200,
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

  Widget listTransaksi(List<TransaksiModel> list) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "Belum ada transaksi",
          style: abuReguler15,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Transaksi Terbaru', style: hitamReguler15),
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
              child: Text('Lihat Semua', style: biruReguler12),
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
                          child: Text(
                            DateFormat('dd MMM yyyy').format(tx.tanggal),
                            style: hitamReguler12,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currency.format(tx.nominal),
                          style: tx.tipe.trim().toLowerCase() == "pemasukan"
                              ? hijauBold12
                              : merahBold12,
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
                            color: tx.tipe.trim().toLowerCase() == "pemasukan"
                                ? hijauPemasukan
                                : merahPengeluaran,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            tx.tipe.trim().toLowerCase() == "pemasukan"
                                ? Icons.call_made
                                : Icons.call_received,
                            color: putih,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                capitalize(tx.judul),
                                style: hitamBold15,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                capitalize(tx.kategori),
                                style: hitamReguler12,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                tx.sumberdana.toUpperCase(),
                                style: hitamReguler12,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currency.format(tx.nominal),
                          style: tx.tipe.trim().toLowerCase() == "pemasukan"
                              ? hijauBold12
                              : merahBold12,
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
