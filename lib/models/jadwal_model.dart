/// Model untuk Jadwal Penyiraman
/// Digunakan untuk menyimpan konfigurasi jadwal di Firebase
class JadwalModel {
  final String id; // jadwal_1, jadwal_2, etc.
  final bool aktif;
  final String waktu; // Format: "HH:mm"
  final int durasi; // Dalam detik
  final List<int> potAktif; // Array pot yang aktif [1, 2, 3, 4, 5]
  final bool pompaAir;
  final bool pompaPupuk;

  JadwalModel({
    required this.id,
    this.aktif = true,
    required this.waktu,
    this.durasi = 60,
    this.potAktif = const [],
    this.pompaAir = true,
    this.pompaPupuk = false,
  });

  /// Create from Firebase JSON
  factory JadwalModel.fromJson(String id, Map<String, dynamic> json) {
    return JadwalModel(
      id: id,
      aktif: json['aktif'] ?? true,
      waktu: json['waktu'] ?? '08:00',
      durasi: json['durasi'] ?? 60,
      potAktif: _parsePotAktif(json['pot_aktif']),
      pompaAir: json['pompa_air'] ?? true,
      pompaPupuk: json['pompa_pupuk'] ?? false,
    );
  }

  /// Parse pot_aktif to List<int>
  static List<int> _parsePotAktif(dynamic potAktif) {
    if (potAktif == null) return [];
    if (potAktif is List) {
      return potAktif
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .toList();
    }
    return [];
  }

  /// Convert to Firebase JSON
  Map<String, dynamic> toJson() {
    return {
      'aktif': aktif,
      'waktu': waktu,
      'durasi': durasi,
      'pot_aktif': potAktif,
      'pompa_air': pompaAir,
      'pompa_pupuk': pompaPupuk,
    };
  }

  /// Copy with new values
  JadwalModel copyWith({
    String? id,
    bool? aktif,
    String? waktu,
    int? durasi,
    List<int>? potAktif,
    bool? pompaAir,
    bool? pompaPupuk,
  }) {
    return JadwalModel(
      id: id ?? this.id,
      aktif: aktif ?? this.aktif,
      waktu: waktu ?? this.waktu,
      durasi: durasi ?? this.durasi,
      potAktif: potAktif ?? this.potAktif,
      pompaAir: pompaAir ?? this.pompaAir,
      pompaPupuk: pompaPupuk ?? this.pompaPupuk,
    );
  }

  /// Get durasi dalam menit untuk display
  int get durasiMenit => (durasi / 60).round();

  /// Check if pot is selected
  bool isPotAktif(int potNumber) {
    return potAktif.contains(potNumber);
  }

  /// Get formatted time for display
  String get waktuFormatted {
    return waktu;
  }

  /// Get pot aktif as string for display
  String get potAktifString {
    if (potAktif.isEmpty) return 'Tidak ada pot';
    if (potAktif.length == 5) return 'Semua pot (1-5)';
    return 'Pot ${potAktif.join(', ')}';
  }

  /// Validate jadwal
  bool get isValid {
    return waktu.isNotEmpty &&
        durasi > 0 &&
        potAktif.isNotEmpty &&
        potAktif.every((pot) => pot >= 1 && pot <= 5);
  }

  @override
  String toString() {
    return 'JadwalModel(id: $id, aktif: $aktif, waktu: $waktu, durasi: ${durasi}s, pot: $potAktif)';
  }
}
