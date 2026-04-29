import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AiCacheService {
  
  // FIREBASE INSTANCE
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  
  // UID USER LOGIN
  
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  
  // FILTER PROMPT MUDAH
  bool isSimplePrompt(String prompt) {
    final lower = prompt.toLowerCase();

    return lower.contains("saldo") ||
        lower.contains("transaksi") ||
        lower.contains("tanggal") ||
        lower.contains("hari") ||
        lower.contains("bulan") ||
        lower.contains("apa aja") ||
        lower.contains("apa saja") ||
        lower.contains("apa") ||
        lower.contains("kapan") ||
        lower.contains("ada kah") ||
        lower.contains("apakah ada") ||
        lower.contains("riwayat") ||
        lower.contains("pengeluaran") ||
        lower.contains("pemasukan");
  }

  
  // CARI PROMPT DI FIRESTORE
  Future<Map<String, dynamic>?> findSimilarAiPrompt(String prompt) async {
    try {
      if (uid == null) return null;

      final cleanPrompt = prompt.trim().toLowerCase();

      final snapshot = await _db
          .collection('user')
          .doc(uid)
          .collection('ai')
          .where('prompt', isEqualTo: cleanPrompt)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }

      return null;
    } catch (e) {
      print("Gagal cari cache AI: $e");
      return null;
    }
  }

  
  // SIMPAN AI 
  
  Future<void> addAiResult(String prompt, String respon, String periode) async {
    try {
      if (uid == null) return;

      final cleanPrompt = prompt.trim().toLowerCase();

      
      // JANGAN SIMPAN PROMPT MUDAH
      
      if (isSimplePrompt(cleanPrompt)) {
        return;
      }

      final aiRef = _db.collection('user').doc(uid).collection('ai');

      
      // CEK DUPLIKAT
      
      final existing = await aiRef
          .where('prompt', isEqualTo: cleanPrompt)
          .limit(1)
          .get();

    
      // TIDAK PERLU GEMINI
      
      if (existing.docs.isNotEmpty) {
        print("CACHE EXISTS - NO NEW GEMINI");
        return;
      }

      
      // JIKA BARU:
      // SIMPAN SEKALI
      await aiRef.add({
        'prompt': cleanPrompt,
        'respon': respon,
        'periode': periode,
        'tanggal': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("AI SAVED NEW");
    } catch (e) {
      print("Gagal simpan AI: $e");
    }
  }

  
  // AMBIL AI TERAKHIR
  
  Future<Map<String, dynamic>?> getLastAiResult() async {
    try {
      if (uid == null) return null;

      final snapshot = await _db
          .collection('user')
          .doc(uid)
          .collection('ai')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  
  // CARI PROMPT SPESIFIK
  
  Future<Map<String, dynamic>?> findAiByPrompt(String prompt) async {
    try {
      if (uid == null) return null;

      final cleanPrompt = prompt.trim().toLowerCase();

      final snapshot = await _db
          .collection('user')
          .doc(uid)
          .collection('ai')
          .where('prompt', isEqualTo: cleanPrompt)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  
  // RIWAYAT AI
  Stream<List<Map<String, dynamic>>> getAiHistory() {
    if (uid == null) {
      return const Stream.empty();
    }

    return _db
        .collection('user')
        .doc(uid)
        .collection('ai')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
