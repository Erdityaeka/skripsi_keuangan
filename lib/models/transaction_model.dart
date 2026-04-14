class TransaksiModel {
  String id;
  String judul;
  String kategori; 
  String bank; 
  double nominal;
  DateTime tanggal;
  String tipe; 

  TransaksiModel({
    required this.id,
    required this.judul,
    required this.kategori, 
    required this.bank, 
    required this.nominal,
    required this.tanggal,
    required this.tipe,
  });

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'kategori': kategori, 
      'bank': bank, 
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
          map['kategori'] ?? 'Umum', 
      bank: map['bank'] ?? 'Tidak Diketahui', 
      nominal: (map['nominal'] as num).toDouble(),
      tanggal: DateTime.parse(map['tanggal']),
      tipe: map['tipe'] ?? 'income',
    );
  }
}
