import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Screens/Profile/Bank/bank_screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Kategori/kategori_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/formats/currency_input_formatter.dart';
import 'package:skripsi_keuangan/models/bank_model.dart';
import 'package:skripsi_keuangan/models/kategori_model.dart';
import 'package:skripsi_keuangan/models/tagihan_models.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';
import 'package:skripsi_keuangan/services/notification_service.dart';

class TambahTagihan extends StatefulWidget {
  const TambahTagihan({super.key});

  @override
  State<TambahTagihan> createState() => _TambahTagihanState();
}

class _TambahTagihanState extends State<TambahTagihan> {
  final judul = TextEditingController();
  final nominal = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  String? selectedKategori;
  String? selectedBank;

  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();

  // PILIH TANGGAL
  Future<void> pickDate() async {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final currentSelected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final safeInitialDate = currentSelected.isBefore(today)
        ? today
        : currentSelected;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: today,
      lastDate: DateTime(2100),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: red, // Header & tombol utama
              onPrimary: white, // Text header
              onSurface: black, // Text tanggal
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // PILIH JAM
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: red, // Header & tombol utama
              onPrimary: white, // Text header
              onSurface: black, // Text jam
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // SIMPAN TAGIHAN
  // SIMPAN TAGIHAN
  Future<void> savetagihan() async {
    if (judul.text.isEmpty ||
        nominal.text.isEmpty ||
        selectedKategori == null ||
        selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: rednotif,
          content: Center(
            child: Text("Semua data wajib diisi", style: whiteBold),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final scheduledDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final now = DateTime.now();

    // Waktu tidak boleh masa lalu
    if (scheduledDate.isBefore(now)) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: rednotif,
          content: Center(
            child: Text(
              "Waktu tagihan harus lebih dari waktu sekarang",
              style: whiteBold,
            ),
          ),
        ),
      );
      return;
    }

    // Jika lebih dari 10 menit:
    // notif dikirim 10 menit sebelum jatuh tempo
    // Jika kurang dari / sama dengan 10 menit:
    // notif dikirim tepat waktu
    final notificationTime = scheduledDate.difference(now).inMinutes > 10
        ? scheduledDate.subtract(const Duration(minutes: 10))
        : scheduledDate;

    // Bersihkan nominal
    final cleanNominal = nominal.text
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '');

    final nominalValue = double.tryParse(cleanNominal) ?? 0;

    // Nominal tidak boleh 0
    if (nominalValue <= 0) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: rednotif,
          content: Center(
            child: Text("Nominal harus lebih dari 0", style: whiteBold),
          ),
        ),
      );
      return;
    }

    final tagihan = TagihanModels(
      id: '',
      judul: judul.text.trim(),
      kategori: selectedKategori!,
      bank: selectedBank!,
      nominal: nominalValue,
      tanggalJatuhTempo: scheduledDate,
    );

    try {
      // Simpan Firestore
      await _firestoreService.addTagihan(tagihan);

      // Jadwalkan notifikasi
      await NotificationService.scheduleTagihanNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: "Tagihan Jatuh Tempo",
        body: "${tagihan.judul} harus dibayar sekarang",
        scheduledDate: notificationTime,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: rednotif,
          content: Text("Gagal menambahkan tagihan: $e", style: whiteBold),
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: greennotif,
        content: Text(
          "Tagihan berhasil ditambahkan dan notifikasi aktif",
          style: whiteBold,
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    judul.dispose();
    nominal.dispose();
    super.dispose();
  }

  // APPBAR
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
      title: Text('Tambah Tagihan', style: redBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  // EMPTY MESSAGE
  Widget _emptyMessage(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          border: Border.all(color: red, width: 1.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(child: Text("$title (Tambah dulu)", style: greyReguler)),
      ),
    );
  }

  // INPUT
  Widget buttonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Judul Tagihan', style: redReguler15),
        const SizedBox(height: 15),

        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 5),
            child: TextField(
              controller: judul,
              decoration: InputDecoration(
                hintText: 'Contoh: Bayar Listrik',
                hintStyle: greyReguler,
                border: InputBorder.none,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text('Nominal', style: redReguler15),
        const SizedBox(height: 15),

        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: red, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text('Rp.', style: blackReguler),
              ),
              Expanded(
                child: TextField(
                  controller: nominal,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '100.000',
                    hintStyle: greyReguler,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // KATEGORI
  Widget buttonKategori() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: redReguler15),
        const SizedBox(height: 15),

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

            if (selectedKategori != null &&
                !kategori.map((e) => e.nama).contains(selectedKategori)) {
              selectedKategori = null;
            }

            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: red, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedKategori,
                    dropdownColor: white,
                    hint: Text('Pilih Kategori', style: blackReguler),
                    icon: Icon(Icons.arrow_drop_down, color: black),
                    onChanged: (v) => setState(() => selectedKategori = v),
                    items: kategori
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.nama,
                            child: Text(e.nama),
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

  // BANK
  Widget buttonBank() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bank', style: redReguler15),
        const SizedBox(height: 15),

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
                border: Border.all(color: red, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBank,
                    dropdownColor: white,
                    hint: Text('Pilih Bank', style: blackReguler),
                    icon: Icon(Icons.arrow_drop_down, color: black),
                    onChanged: (v) => setState(() => selectedBank = v),
                    items: bank
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.nama,
                            child: Text(e.nama),
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

  // TANGGAL
  Widget buttonTanggal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanggal', style: redReguler15),
        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('dd MMM yyyy').format(selectedDate),
                style: blackReguler,
              ),
            ),

            GestureDetector(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Pilih Tanggal", style: whiteReguler),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // JAM
  Widget buttonJam() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jam', style: redReguler15),
        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: Text(selectedTime.format(context), style: blackReguler),
            ),

            GestureDetector(
              onTap: pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Pilih Jam", style: whiteReguler),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // SIMPAN
  Widget buttonSimpan() {
    return GestureDetector(
      onTap: _isLoading ? null : savetagihan,
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
              : Text('Simpan Tagihan', style: whiteBold),
        ),
      ),
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 30,
            bottom: 30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buttonInput(),
              const SizedBox(height: 15),
              buttonKategori(),
              const SizedBox(height: 15),
              buttonBank(),
              const SizedBox(height: 15),
              buttonTanggal(),
              const SizedBox(height: 15),
              buttonJam(),
              const SizedBox(height: 50),
              buttonSimpan(),
            ],
          ),
        ),
      ),
    );
  }
}
