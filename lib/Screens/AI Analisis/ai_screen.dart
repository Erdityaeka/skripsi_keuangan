import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ditambahkan untuk menggunakan Clipboard
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
    // Kunci tombol kirim jika sedang loading
    if (_loading) return;

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
      await Future.delayed(const Duration(milliseconds: 500));

      // Ambil jawaban AI / lokal melalui Direct HTTP Call
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
        _messages.add({
          "role": "ai",
          "text": "Terjadi kesalahan koneksi. Silakan coba lagi.",
        });
        _loading = false;
      });

      _scrollToBottom();
    }
  }

  // QUICK PROMPT
  Future<void> _sendQuickPrompt(String text) async {
    if (_loading) return; // Cegah klik tombol cepat saat AI sedang berpikir
    _controller.text = text;
    await _sendMessage();
  }

  // FUNGSI UNTUK SALIN TEKS KE CLIPBOARD
  void _copyToClipboard(String text, String role) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      String label = role == 'user' ? 'Pertanyaan' : 'Jawaban';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label berhasil disalin ke papan klip!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  // AUTO SCROLL KE BAWAH
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _list(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
          ),
          child: inputPrompt(),
        ),
      ),
    );
  }

  // APPBAR
  PreferredSizeWidget _buildAppbar() {
    return AppBar(
      backgroundColor: putih,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: hitam),
      ),
      title: Text('AI Uang Note', style: hitamBold20),
      centerTitle: true,
      flexibleSpace: Container(decoration: BoxDecoration(color: putih)),
    );
  }

  // LIST CHAT
  Widget _list() {
    // Tampilan awal
    if (_messages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Anda Ingin Bertanya Apa Saat Ini?',
                style: hitamReguler15,
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
        ),
      );
    }

    // Chat aktif
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length + (_loading ? 1 : 0),
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (_, i) {
        // Bubble loading
        if (_loading && i == _messages.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: putih,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: hitam.withOpacity(0.1)),
              ),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        bool isUser = _messages[i]['role'] == 'user';
        String textMessage = _messages[i]['text'] ?? '';
        String roleMessage = _messages[i]['role'] ?? 'ai';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 4,
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: isUser ? hitam : hitam.withOpacity(0.1),
                width: 1.5,
              ),
              color: isUser ? hijauMedium : putih,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isUser
                    ? const Radius.circular(12)
                    : const Radius.circular(0),
                bottomRight: isUser
                    ? const Radius.circular(0)
                    : const Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Isi Teks Utama
                Text(textMessage, style: hitamReguler15),

                // Deretan Tombol Aksi di bagian bawah balon chat
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _copyToClipboard(textMessage, roleMessage),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: isUser
                                  ? hitam.withOpacity(0.6)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Salin',
                              style:
                                  (isUser
                                          ? hitamReguler12
                                          : hitamReguler12.copyWith(
                                              color: Colors.grey,
                                            ))
                                      .copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: putih,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hijauSimpan, width: 2),
        ),
        child: Text(t, style: hitamReguler12),
      ),
    );
  }

  // INPUT USER
  Widget inputPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 50, maxHeight: 120),
          width: double.infinity,
          decoration: BoxDecoration(
            color: putih,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: hijauSimpan, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: hitamReguler15,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Tulis pertanyaan Anda...',
                    hintStyle: hitamReguler15.copyWith(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _sendMessage,
                icon: Icon(Icons.send, color: _loading ? Colors.grey : hitam),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('AI ini bisa melakukan kesalahan!', style: merahReguler12),
      ],
    );
  }
}
