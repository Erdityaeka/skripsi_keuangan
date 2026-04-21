import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skripsi_keuangan/Screens/Profile/Bank/bank_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Kategori/kategori_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/formats/currency_input_formatter.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class TambahTransaksi extends StatefulWidget {
  const TambahTransaksi({super.key});

  @override
  State<TambahTransaksi> createState() => _TambahTransaksiState();
}

class _TambahTransaksiState extends State<TambahTransaksi> {
  final judul = TextEditingController();
  final nominal = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String selectedType = "pemasukan";
  String? selectedKategory;
  String? selectedBank;

  @override
  void dispose() {
    judul.dispose();
    nominal.dispose();
    super.dispose();
  }

  // SIMPAN TRANSAKSI
  void _saveTransaction() async {
    if (judul.text.isEmpty ||
        nominal.text.isEmpty ||
        selectedKategory == null ||
        selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text("Lengkapi semua data", style: whiteBold)),
          backgroundColor: rednotif,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(nominal.text.replaceAll('.', ''));

      final tx = TransaksiModel(
        id: '',
        judul: judul.text,
        kategori: selectedKategory!,
        bank: selectedBank!,
        nominal: amount,
        tanggal: DateTime.now(),
        tipe: selectedType,
      );

      await _firestoreService.addTransaction(tx);

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text("Transaksi berhasil disimpan", style: whiteBold),
          ),
          backgroundColor: greennotif,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text("Gagal menyimpan: $e", style: whiteBold)),
          backgroundColor: rednotif,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buttonInput(),
              SizedBox(height: 15),
              buttoTipe(),
              SizedBox(height: 15),
              buttonKategori(),
              SizedBox(height: 15),
              buttonBank(),
              SizedBox(height: 100),
              buttonSimpan(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('Tambah Transaksi', style: redBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  Widget buttonInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Judul Transaksi', style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 5.0, left: 14.0),
              child: TextField(
                controller: judul,
                decoration: InputDecoration(
                  hintText: 'Contoh: Mie Ayam',
                  hintStyle: greyReguler,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 15),
        Text('Nominal', style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 5.0, left: 14.0),
                child: Text('Rp.', style: blackReguler),
              ),

              Expanded(
                child: TextField(
                  controller: nominal,
                  decoration: InputDecoration(
                    hintText: '10.000',
                    hintStyle: greyReguler,
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buttoTipe() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipe Transaksi', style: redReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedType,
                dropdownColor: white,
                hint: Text('Pemasukan', style: blackReguler),
                icon: Icon(Icons.arrow_drop_down, color: black),
                onChanged: (v) => setState(() => selectedType = v!),
                items: const [
                  DropdownMenuItem(
                    value: "pemasukan",
                    child: Text("Pemasukan"),
                  ),
                  DropdownMenuItem(
                    value: "pengeluaran",
                    child: Text("Pengeluaran"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buttonKategori() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: redReguler15),
        SizedBox(height: 15),
        StreamBuilder<List<String>>(
          stream: _firestoreService.getCategories(),

          builder: (context, snapshot) {
            final kategori = snapshot.data ?? [];

            if (kategori.isEmpty) {
              return _emptyMessage(
                "Kategori kosong",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KategoriScreens()),
                ),
              );
            }
            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: red, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedKategory,
                    dropdownColor: white,
                    hint: Text('Pilih Kategori', style: blackReguler),
                    icon: Icon(Icons.arrow_drop_down, color: black),
                    onChanged: (v) => setState(() => selectedKategory = v),
                    items: kategori
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buttonBank() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank', style: redReguler15),
        SizedBox(height: 15),
        StreamBuilder<List<String>>(
          stream: _firestoreService.getBank(),

          builder: (context, snapshot) {
            final bank = snapshot.data ?? [];

            if (bank.isEmpty) {
              return _emptyMessage(
                "Bank kosong",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BankScreens()),
                ),
              );
            }

            // pastikan selectedBank valid
            if (selectedBank != null && !bank.contains(selectedBank)) {
              selectedBank = null;
            }
            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: red, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBank,
                    dropdownColor: white,
                    hint: Text('SEMUA', style: blackReguler),
                    icon: Icon(Icons.arrow_drop_down, color: black),
                    onChanged: (v) => setState(() => selectedBank = v),
                    items: bank
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buttonSimpan() {
    return GestureDetector(
      onTap: _saveTransaction,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Text('Simpan Transaksi', style: whiteBold),
        ),
      ),
    );
  }

  Widget _emptyMessage(String text, VoidCallback action) {
    return Column(
      children: [
        Text(text, style: const TextStyle(color: Colors.orange)),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Tambah Transaksi"),
          onPressed: action,
        ),
      ],
    );
  }
}
