class TransaksiModel {
  String id;
  String judul;
  String kategori; // Field kategori
  String bank; // Field bank
  double nominal;
  DateTime tanggal;
  String tipe; // "income" atau "expense"

  TransaksiModel({
    required this.id,
    required this.judul,
    required this.kategori, // Tambahkan di constructor
    required this.bank, // Tambahkan field bank
    required this.nominal,
    required this.tanggal,
    required this.tipe,
  });

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'kategori': kategori, // Simpan ke Firestore
      'bank': bank, // Tambahkan field bank
      'nominal': nominal,
      'tanggal': tanggal.toIso8601String(),
      'tipe': tipe,
    };
  }

  factory TransaksiModel.fromMap(String id, Map<String, dynamic> map) {
    return TransaksiModel(
      id: id,
      judul: map['judul'] ?? '',
      kategori:
          map['kategori'] ?? 'Umum', // Ambil dari Firestore (default 'Umum')
      bank: map['bank'] ?? 'Tidak Diketahui', // Ambil dari Firestore
      nominal: (map['nominal'] as num).toDouble(),
      tanggal: DateTime.parse(map['tanggal']),
      tipe: map['tipe'] ?? 'income',
    );
  }
}
