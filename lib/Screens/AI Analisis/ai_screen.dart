import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/firestore_service.dart';
import 'package:skripsi_keuangan/services/gemini_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _messages = <Map<String, dynamic>>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final transaksiService = FirestoreService();

  bool _isLoading = false;
  DateTime? _lastRequest;

  final rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Mendeteksi Topik Untuk AI
  bool isFinanceQuestion(String text) {
    text = text.toLowerCase();

    return text.contains("saldo") ||
        text.contains("uang") ||
        text.contains("keuangan") ||
        text.contains("boros") ||
        text.contains("hemat") ||
        text.contains("pengeluaran") ||
        text.contains("pemasukan");
  }

  // Mengambil Nilai Transaksi
  Future<String> _getFinancialContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "user_not_login";

    final list = (await transaksiService.gettransaksi().first)
        .take(20)
        .toList();

    if (list.isEmpty) return "DATA_KOSONG";

    double masuk = 0;
    double keluar = 0;

    Map<String, double> perBulan = {};

    for (var t in list) {
      final nominal = t.nominal;
      final tipe = (t.tipe).toLowerCase();

      // Format Bulan
      final tanggal = t.tanggal.toLocal();
      final bulan = DateFormat('MMMM yyyy', 'id_ID').format(tanggal);

      perBulan.putIfAbsent(bulan, () => 0);

      if (tipe == "pemasukan") {
        masuk += nominal;
        perBulan[bulan] = perBulan[bulan]! + nominal;
      } else {
        keluar += nominal;
        perBulan[bulan] = perBulan[bulan]! - nominal;
      }
    }

    String detailBulan = "";
    perBulan.forEach((bulan, saldo) {
      detailBulan += "$bulan: $saldo\n";
    });

    return """
Data keuangan pengguna:

Total pemasukan: $masuk
Total pengeluaran: $keluar
Saldo: ${masuk - keluar}

Saldo per bulan:
$detailBulan

Tugas:
- Gunakan data bulan di atas
- Jika ditanya bulan, jawab sesuai data
- Jangan menebak bulan di luar data
""";
  }

  // Mengririm Pesan
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Anti Spam Prompt
    final now = DateTime.now();
    if (_lastRequest != null &&
        now.difference(_lastRequest!) < const Duration(seconds: 3)) {
      return;
    }
    _lastRequest = now;

    setState(() {
      _isLoading = true;
      _messages.add({'isUser': true, 'text': text});
      _messages.add({'isUser': false, 'text': 'loading'});
    });

    _textController.clear();
    _scrollToBottom();

    try {
      String response;

      //  BEDAKAN TOPIK
      if (isFinanceQuestion(text)) {
        String context = await _getFinancialContext();

        if (context == "DATA_KOSONG") {
          response = "Belum ada transaksi.\nSilakan isi data terlebih dahulu.";
        } else {
          response = await GeminiService.generateText(text, context: context);
        }
      } else {
        response = await GeminiService.generateText(text);
      }

      _reply(response);
    } catch (e) {
      _reply("AI tidak dapat menjawab sekarang");
    } finally {
      _isLoading = false;
      _scrollToBottom();
    }
  }

  // Mengatasi Double Jawaban AI
  void _reply(String text) {
    setState(() {
      _messages.removeLast();
      _messages.add({'isUser': false, 'text': text});
    });
  }

  // Scroll Akhir
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Fungsi Kirim Prompt
  void _sendQuickPrompt(String text) {
    _textController.text = text;
    _sendMessage();
  }

  // Widget UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 20, left: 20, bottom: 30),
          child: Column(
            children: [
              Expanded(child: _list()),
              inputPrompt(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('AI Uang Note', style: redBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: white)),
    );
  }

  // Data List Wrap
  Widget _list() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Anda Ingin Bertanya Apa Saat Ini?',
              style: blackReguler,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _btn("Saldo saya berapa?"),
                _btn("Tips menghemat uang"),
                _btn("Apakah saya boros?"),
                _btn("Prediksi keuangan saya?"),
              ],
            ),
          ],
        ),
      );
    }

    // Data Pertanyaan
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        bool isUser = _messages[i]['isUser'];

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUser ? red : white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _messages[i]['text'] == 'loading'
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _messages[i]['text'],
                    style: isUser ? whiteReguler : blackReguler,
                  ),
          ),
        );
      },
    );
  }

  // UI Wrap Button
  Widget _btn(String t) => InkWell(
    onTap: () => _sendQuickPrompt(t),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: red, width: 2),
      ),
      child: Text(t, style: blackReguler12),
    ),
  );

  // Input Prompt
  Widget inputPrompt() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 80, // 🔥 dari 100 → 80 biar lebih pas
            width: double.infinity,
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: red, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: blackReguler,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Tulis pertanyaan Anda...',
                      hintStyle: blackReguler,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10, // 🔥 biar tidak mepet
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send, color: black),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Text('AI ini bisa melakukan kesalahan!', style: blackReguler12),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
