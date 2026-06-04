import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Screens/Profile/Bank/bank_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Kategori/kategori_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/formats/currency_input_formatter.dart';
import 'package:skripsi_keuangan/models/bank_model.dart';
import 'package:skripsi_keuangan/models/kategori_model.dart';
import 'package:skripsi_keuangan/models/transaction_model.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';

class EditTransaksi extends StatefulWidget {
  final TransaksiModel tx;

  const EditTransaksi({super.key, required this.tx});

  @override
  State<EditTransaksi> createState() => _EditTransaksiState();
}

class _EditTransaksiState extends State<EditTransaksi> {
  final judul = TextEditingController();
  final nominal = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;

  String selectedType = "pemasukan";
  String? selectedKategory;
  String? selectedBank;

  @override
  void initState() {
    super.initState();
    judul.text = widget.tx.judul;
    nominal.text = NumberFormat.decimalPattern('id').format(widget.tx.nominal);
    selectedKategory = widget.tx.kategori;
    selectedBank = widget.tx.bank;
    selectedType = widget.tx.tipe;
  }

  @override
  void dispose() {
    judul.dispose();
    nominal.dispose();
    super.dispose();
  }

  // Simpan Update Data
  void _saveTransaction() async {
    if (judul.text.isEmpty ||
        nominal.text.isEmpty ||
        selectedKategory == null ||
        selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text("Lengkapi semua data", style: putihBold15),
          ),
          backgroundColor: rednotif,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(nominal.text.replaceAll('.', ''));

      //  Ambil Update Di Firestore
      await _firestoreService.updateTransaction(
        widget.tx.id,
        judul.text,
        amount,
        selectedKategory!,
        selectedBank!,
        selectedType,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text("Transaksi berhasil diupdate", style: putihBold15),
          ),
          backgroundColor: greennotif,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(child: Text("Gagal update: $e", style: putihBold15)),
          backgroundColor: rednotif,
        ),
      );
    }
  }

  // Fungsi Hapus Transaksi
  void _deleteTransaksi() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: putih,
        title: Text("Hapus Transaksi?", style: hitamBold20),
        content: Text(
          "Yakin ingin menghapus data transaksi ini?",
          style: teksdialogBold15,
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: dialogBatalBold15),
          ),

          Container(
            width: 100,
            height: 40,
            decoration: BoxDecoration(
              color: merahHapus,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              child: Text("Hapus", style: putihBold15),

              onPressed: () async {
                try {
                  await _firestoreService.deleteTransaction(widget.tx.id);

                  if (!mounted) return;

                  Navigator.pop(context);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text(
                          "Transaksi berhasil dihapus",
                          style: putihBold15,
                        ),
                      ),
                      backgroundColor: greennotif,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text("Gagal menghapus: $e", style: putihBold15),
                      ),
                      backgroundColor: rednotif,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
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

  // APPBAR
  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: putih,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back, color: hitam),
      ),
      title: Text('Edit Transaksi', style: hitamBold20),
      centerTitle: true,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 10),
          child: IconButton(
            onPressed: () {
              _deleteTransaksi();
            },
            icon: Icon(Icons.delete, color: merahHapus),
          ),
        ),
      ],
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  // Button Input(Judul Dan Nominal)
  Widget buttonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Judul Transaksi', style: hitamReguler15),
        SizedBox(height: 15),
        Container(
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: judul,
              decoration: InputDecoration(
                hintText: 'Contoh: Mie Ayam',
                hintStyle: abuReguler15,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        SizedBox(height: 15),
        Text('Nominal', style: hitamReguler15),
        SizedBox(height: 15),
        Container(
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 14),
                child: Text('Rp.', style: hitamReguler15),
              ),
              Expanded(
                child: TextField(
                  controller: nominal,
                  decoration: InputDecoration(
                    hintText: '10.000',
                    hintStyle: abuReguler15,
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

  // Button Tipe Transaksi
  Widget buttoTipe() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipe Transaksi', style: hitamReguler15),
        SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedType,
                dropdownColor: putih,
                hint: Text('Pemasukan', style: hitamReguler15),
                icon: Icon(Icons.arrow_drop_down, color: hitam),
                onChanged: (v) => setState(() => selectedType = v!),
                items: [
                  DropdownMenuItem(
                    value: "pemasukan",
                    child: Text("Pemasukan", style: hitamReguler15),
                  ),
                  DropdownMenuItem(
                    value: "pengeluaran",
                    child: Text("Pengeluaran", style: hitamReguler15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // BUTTON KATEGORI
  Widget buttonKategori() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: hitamReguler15),
        SizedBox(height: 15),
        StreamBuilder<List<KategoriModel>>(
          stream: _firestoreService.getCategoryModels(),
          builder: (context, snapshot) {
            final kategori = snapshot.data ?? <KategoriModel>[];

            if (kategori.isEmpty) {
              return _emptyMessage(
                "Kategori kosong",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KategoriScreens()),
                ),
              );
            }

            if (selectedKategory != null &&
                !kategori.map((e) => e.nama).contains(selectedKategory)) {
              selectedKategory = null;
            }

            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: hijauSimpan, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedKategory,
                    dropdownColor: putih,
                    hint: Text('Pilih Kategori', style: hitamReguler15),
                    icon: Icon(Icons.arrow_drop_down, color: hitam),
                    onChanged: (v) => setState(() => selectedKategory = v),
                    items: kategori
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.nama,
                            child: Text(e.nama, style: hitamReguler15),
                          ),
                        )
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

  // BUTTON BANK
  Widget buttonBank() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank', style: hitamReguler15),
        SizedBox(height: 15),
        StreamBuilder<List<BankModel>>(
          stream: _firestoreService.getBankModels(),
          builder: (context, snapshot) {
            final bank = snapshot.data ?? <BankModel>[];

            if (bank.isEmpty) {
              return _emptyMessage(
                "Bank kosong",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BankScreens()),
                ),
              );
            }

            if (selectedBank != null &&
                !bank.map((e) => e.nama).contains(selectedBank)) {
              selectedBank = null;
            }

            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: hijauSimpan, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBank,
                    dropdownColor: putih,
                    hint: Text('SEMUA', style: hitamReguler15),
                    icon: Icon(Icons.arrow_drop_down, color: hitam),
                    onChanged: (v) => setState(() => selectedBank = v),
                    items: bank
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.nama,
                            child: Text(e.nama, style: hitamReguler15),
                          ),
                        )
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

  // Button Simpan
  Widget buttonSimpan() {
    return GestureDetector(
      onTap: _saveTransaction,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: hijauSimpan,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(color: putih)
              : Text('Simpan Transaksi', style: putihBold15),
        ),
      ),
    );
  }

  Widget _emptyMessage(String text, VoidCallback action) {
    return Column(
      children: [
        Text(text, style: biruReguler12),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Tambah Data"),
          onPressed: action,
        ),
      ],
    );
  }
}
