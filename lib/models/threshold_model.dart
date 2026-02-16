class ThresholdModel {
  final String id; // threshold_1, threshold_2, ...
  final bool aktif;
  final int batasBawah; // 0-100 persentase kelembaban
  final int batasAtas; // 0-100 persentase kelembaban
  final int durasi; // detik
  final bool smartMode; // true = smart, false = fixed duration
  final List<int> potAktif; // [1,2,3] atau [4,5]
  final bool pompaAir;
  final bool pompaPupuk;

  ThresholdModel({
    required this.id,
    required this.aktif,
    required this.batasBawah,
    required this.batasAtas,
    required this.durasi,
    required this.smartMode,
    required this.potAktif,
    required this.pompaAir,
    required this.pompaPupuk,
  });

  // Parse dari Firebase
  factory ThresholdModel.fromJson(String id, Map<dynamic, dynamic> json) {
    List<int> parsePotAktif(dynamic potData) {
      if (potData == null) return [];
      if (potData is List) {
        return potData.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
      }
      return [];
    }

    return ThresholdModel(
      id: id,
      aktif: json['aktif'] == true,
      batasBawah: json['batas_bawah'] is int ? json['batas_bawah'] : 30,
      batasAtas: json['batas_atas'] is int ? json['batas_atas'] : 70,
      durasi: json['durasi'] is int ? json['durasi'] : 600,
      smartMode: json['smart_mode'] == true,
      potAktif: parsePotAktif(json['pot_aktif']),
      pompaAir: json['pompa_air'] == true,
      pompaPupuk: json['pompa_pupuk'] == true,
    );
  }

  // Convert ke format Firebase
  Map<String, dynamic> toJson() {
    return {
      'aktif': aktif,
      'batas_bawah': batasBawah,
      'batas_atas': batasAtas,
      'durasi': durasi,
      'smart_mode': smartMode,
      'pot_aktif': potAktif,
      'pompa_air': pompaAir,
      'pompa_pupuk': pompaPupuk,
    };
  }

  // Helper: durasi dalam menit
  int get durasiMenit => (durasi / 60).round();

  // Helper: cek apakah pot tertentu aktif
  bool isPotAktif(int potNumber) {
    return potAktif.contains(potNumber);
  }

  // Helper: string pot aktif (1,2,3)
  String get potAktifString {
    if (potAktif.isEmpty) return 'Tidak ada pot';
    return potAktif.join(', ');
  }

  // Helper: range string (30-70%)
  String get rangeString => '$batasBawah%-$batasAtas%';

  // Helper: mode string
  String get modeString => smartMode ? 'Smart Mode' : 'Fixed Duration';

  // Validation
  bool get isValid {
    return batasBawah >= 0 &&
        batasBawah <= 100 &&
        batasAtas >= 0 &&
        batasAtas <= 100 &&
        batasBawah < batasAtas &&
        durasi > 0 &&
        potAktif.isNotEmpty;
  }

  // Copy with
  ThresholdModel copyWith({
    String? id,
    bool? aktif,
    int? batasBawah,
    int? batasAtas,
    int? durasi,
    bool? smartMode,
    List<int>? potAktif,
    bool? pompaAir,
    bool? pompaPupuk,
  }) {
    return ThresholdModel(
      id: id ?? this.id,
      aktif: aktif ?? this.aktif,
      batasBawah: batasBawah ?? this.batasBawah,
      batasAtas: batasAtas ?? this.batasAtas,
      durasi: durasi ?? this.durasi,
      smartMode: smartMode ?? this.smartMode,
      potAktif: potAktif ?? this.potAktif,
      pompaAir: pompaAir ?? this.pompaAir,
      pompaPupuk: pompaPupuk ?? this.pompaPupuk,
    );
  }
}
