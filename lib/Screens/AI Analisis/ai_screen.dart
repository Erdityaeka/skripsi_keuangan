import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';
import 'package:skripsi_keuangan/services/gemini_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({Key? key}) : super(key: key);

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  // CONTROLLER INPUT
  final TextEditingController _controller = TextEditingController();

  // SCROLL CHAT
  final ScrollController _scrollController = ScrollController();

  // MENYIMPAN SEMUA CHAT
  final List<Map<String, dynamic>> _messages = [];

  // STATUS LOADING
  bool _loading = false;

  // KIRIM PESAN
  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();

    if (prompt.isEmpty) return;

    setState(() {
      // Tambah pesan user
      _messages.add({"role": "user", "text": prompt});

      // Aktifkan loading
      _loading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // Delay agar terasa realistis
      await Future.delayed(const Duration(milliseconds: 700));

      // Ambil jawaban AI / lokal
      final respons = await GeminiService.ask(prompt);

      setState(() {
        // Tambah jawaban AI
        _messages.add({"role": "ai", "text": respons});

        // Matikan loading
        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "text": "Terjadi kesalahan: $e"});

        _loading = false;
      });

      _scrollToBottom();
    }
  }

  // QUICK PROMPT
  Future<void> _sendQuickPrompt(String text) async {
    _controller.text = text;
    await _sendMessage();
  }

  // AUTO SCROLL KE BAWAH
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(right: 20, left: 20),
          child: _list(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: inputPrompt(),
        ),
      ),
    );
  }

  // APPBAR
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

  // LIST CHAT
  Widget _list() {
    // Tampilan awal
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

            // Tombol cepat
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

    // Chat aktif
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (_, i) {
        // Bubble loading
        if (_loading && i == _messages.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
          );
        }

        bool isUser = _messages[i]['role'] == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? red : white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _messages[i]['text'] ?? '',
              style: isUser ? whiteReguler : blackReguler,
            ),
          ),
        );
      },
    );
  }

  // TOMBOL CEPAT
  Widget _btn(String t) {
    return InkWell(
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
  }

  // INPUT USER
  Widget inputPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 80,
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
                  controller: _controller,
                  style: blackReguler,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Tulis pertanyaan Anda...',
                    hintStyle: blackReguler,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),

              // Tombol kirim
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
    );
  }
}
