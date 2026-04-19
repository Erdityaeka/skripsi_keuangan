import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class KomentarScreens extends StatefulWidget {
  const KomentarScreens({super.key});

  @override
  State<KomentarScreens> createState() => _KomentarScreensState();
}

class _KomentarScreensState extends State<KomentarScreens> {
  final List<Map<String, dynamic>> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: ListKomentar()), // hanya ListPrompt yang scrollable
          ],
        ),
      ),
      bottomNavigationBar: inputPrompt(), // input bar fix di bawah
    );
  }

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back, color: red),
      ),
      title: Text('AI Uang Note', style: redBold20),
      centerTitle: true,
    );
  }

  Widget ListKomentar() {
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        bool isUser = _messages[i]['isUser'];
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_messages[i]['text'], style: blackReguler),
          ),
        );
      },
    );
  }

  Widget inputPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: red, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: blackReguler,
                    decoration: InputDecoration(
                      hintText: 'Tulis pertanyaan Anda...',
                      hintStyle: blackReguler,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Logika kirim pertanyaan
                  },
                  icon: Icon(Icons.send, color: black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('AI ini bisa dapat melakukan kesalahan!', style: blackReguler12),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
