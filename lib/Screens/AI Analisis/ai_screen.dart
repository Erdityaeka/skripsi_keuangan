import 'package:flutter/material.dart';
import 'package:skripsi_keuangan/Theme/warna_teks.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final List<Map<String, dynamic>> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: ListPrompt()), // hanya ListPrompt yang scrollable
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

  Widget _quickButton(String text) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: red, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 3,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(text, style: blackReguler12),
      ),
    );
  }

  Widget ListPrompt() {
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
                _quickButton("Saldo saya berapa?"),
                _quickButton("Saldo bulan ini berapa?"),
                _quickButton("Tips menghemat uang"),
              ],
            ),
          ],
        ),
      );
    } else {
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
