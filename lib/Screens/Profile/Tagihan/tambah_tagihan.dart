import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Screens/Profile/Sumber%20Dana/SumberDana_Screens.dart';
import 'package:skripsi_keuangan/Screens/Profile/Kategori/kategori_screens.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/formats/currency_input_formatter.dart';
import 'package:skripsi_keuangan/models/sumberdana_model.dart';
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
  String? selectedSumberdana;
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
              primary: hijauSimpan,
              onPrimary: putih,
              onSurface: hitam,
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
              primary: hijauSimpan,
              onPrimary: putih,
              onSurface: hitam,
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
  Future<void> savetagihan() async {
    if (judul.text.isEmpty ||
        nominal.text.isEmpty ||
        selectedKategori == null ||
        selectedSumberdana == null) {
      // DIPERBAIKI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: rednotif,
          content: Center(
            child: Text(
              "Semua data wajib diisi",
              style: putihBold15,
              textAlign: TextAlign.center,
            ),
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
              style: putihBold15,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
      return;
    }

    late DateTime notificationTime;

    if (scheduledDate.difference(now).inMinutes > 15) {
      notificationTime = scheduledDate.subtract(const Duration(minutes: 15));
    } else {
      notificationTime = scheduledDate;
    }

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
            child: Text(
              "Nominal harus lebih dari 0",
              style: putihBold15,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
      return;
    }

    final tagihan = TagihanModels(
      id: '',
      judul: judul.text.trim(),
      kategori: selectedKategori!,
      sumberdana:
          selectedSumberdana!, // DIPERBAIKI: Mengisi field dengan selectedSumberdana
      nominal: nominalValue,
      tanggalJatuhTempo: scheduledDate,
    );

    try {
      // Simpan Firestore
      await _firestoreService.addTagihan(tagihan);

      // Jadwalkan notifikasi lokal
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
          content: Text(
            "Gagal menambahkan tagihan: $e",
            style: putihBold15,
            textAlign: TextAlign.center,
          ),
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
          style: putihBold15,
          textAlign: TextAlign.center,
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
      backgroundColor: putih,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back, color: hitam),
      ),
      title: Text('Tambah Tagihan', style: hitamBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
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
          border: Border.all(color: merahPengeluaran, width: 1.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text("$title (Tambah dulu data)", style: merahBold15),
        ),
      ),
    );
  }

  // INPUT
  Widget buttonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Judul Tagihan', style: hitamReguler15),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 5),
            child: TextField(
              controller: judul,
              decoration: InputDecoration(
                hintText: 'Contoh: Bayar Listrik',
                hintStyle: abuReguler15,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Nominal', style: hitamReguler15),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: hijauSimpan, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text('Rp.', style: hitamReguler15),
              ),
              Expanded(
                child: TextField(
                  controller: nominal,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '100.000',
                    hintStyle: abuReguler15,
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
        Text('Kategori', style: hitamReguler15),
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
                border: Border.all(color: hijauSimpan, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedKategori,
                    dropdownColor: putih,
                    hint: Text('Pilih Kategori', style: hitamReguler15),
                    icon: Icon(Icons.arrow_drop_down, color: hitam),
                    onChanged: (v) => setState(() => selectedKategori = v),
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

  // SUMBER DANA
  Widget buttonSumberdana() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sumber Dana', style: hitamReguler15),
        const SizedBox(height: 15),
        StreamBuilder<List<SumberdanaModel>>(
          stream: _firestoreService.getSumberdanaModels(),
          builder: (context, snapshot) {
            final sumberdanaList = snapshot.data ?? <SumberdanaModel>[];

            if (sumberdanaList.isEmpty) {
              return _emptyMessage(
                "Sumber Dana kosong",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SumberDanaScreens()),
                ),
              );
            }

            if (selectedSumberdana != null &&
                !sumberdanaList
                    .map((e) => e.nama)
                    .contains(selectedSumberdana)) {
              selectedSumberdana = null;
            }

            return Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                border: Border.all(color: hijauSimpan, width: 1.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSumberdana, // DIPERBAIKI
                    dropdownColor: putih,
                    hint: Text(
                      'Pilih Sumber Dana',
                      style: hitamReguler15,
                    ), // DIPERBAIKI: Hint text berubah
                    icon: Icon(Icons.arrow_drop_down, color: hitam),
                    onChanged: (v) => setState(() => selectedSumberdana = v),
                    items: sumberdanaList
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.nama,
                            child: Text(
                              e.nama.toUpperCase(),
                              style: hitamReguler15,
                            ),
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
        Text('Tanggal', style: hitamReguler15),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('dd MMM yyyy').format(selectedDate),
                style: hitamReguler15,
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
                  color: hijauSimpan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Pilih Tanggal", style: putihReguler15),
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
        Text('Jam', style: hitamReguler15),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Text(selectedTime.format(context), style: hitamReguler15),
            ),
            GestureDetector(
              onTap: pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: hijauSimpan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Pilih Jam", style: putihReguler15),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // SIMPAN BUTTON COMPONENT
  Widget buttonSimpan() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : savetagihan,
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              color: hijauSimpan,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: _isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(putih),
                    )
                  : Text('Simpan Tagihan', style: putihBold15),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  // RENDERING UTAMA WIDGET TREE
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
              buttonSumberdana(), // DIPERBAIKI: Memanggil fungsi komponen baru
              const SizedBox(height: 15),
              buttonTanggal(),
              const SizedBox(height: 15),
              buttonJam(),
              const SizedBox(height: 50),
              SafeArea(top: false, child: buttonSimpan()),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
