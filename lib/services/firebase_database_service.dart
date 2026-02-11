import 'package:firebase_database/firebase_database.dart';

class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance =
      FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;
  FirebaseDatabaseService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // ==================== SENSOR DATA ====================

  /// Get real-time stream of sensor data
  Stream<Map<String, dynamic>> getSensorDataStream() {
    return _database.child('data').onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return {
          'suhu': _parseValue(data['suhu']),
          'kelembapan': _parseValue(data['kelembapan']),
          'ldr': _parseValue(data['ldr']),
          'soil_1': _parseValue(data['soil_1']),
          'soil_2': _parseValue(data['soil_2']),
          'soil_3': _parseValue(data['soil_3']),
          'soil_4': _parseValue(data['soil_4']),
          'soil_5': _parseValue(data['soil_5']),
        };
      }
      return {};
    });
  }

  /// Get sensor data once
  Future<Map<String, dynamic>> getSensorData() async {
    try {
      final snapshot = await _database.child('data').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return {
          'suhu': _parseValue(data['suhu']),
          'kelembapan': _parseValue(data['kelembapan']),
          'ldr': _parseValue(data['ldr']),
          'soil_1': _parseValue(data['soil_1']),
          'soil_2': _parseValue(data['soil_2']),
          'soil_3': _parseValue(data['soil_3']),
          'soil_4': _parseValue(data['soil_4']),
          'soil_5': _parseValue(data['soil_5']),
        };
      }
    } catch (e) {
      print('Error getting sensor data: $e');
    }
    return {};
  }

  // ==================== AKTUATOR CONTROL ====================

  /// Get real-time stream of aktuator status
  Stream<Map<String, bool>> getAktuatorStream() {
    return _database.child('aktuator').onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return {
          'mosvet_1': data['mosvet_1'] ?? false, // Pompa Air
          'mosvet_2': data['mosvet_2'] ?? false, // Pompa Pupuk
          'mosvet_3': data['mosvet_3'] ?? false, // Valve 1
          'mosvet_4': data['mosvet_4'] ?? false, // Valve 2
          'mosvet_5': data['mosvet_5'] ?? false, // Valve 3
          'mosvet_6': data['mosvet_6'] ?? false, // Valve 4
          'mosvet_7': data['mosvet_7'] ?? false, // Valve 5
          'mosvet_8': data['mosvet_8'] ?? false, // Pengaduk
        };
      }
      return {};
    });
  }

  /// Set aktuator status (untuk kontrol manual)
  Future<void> setAktuator(String mosfetName, bool value) async {
    try {
      await _database.child('aktuator/$mosfetName').set(value);
    } catch (e) {
      print('Error setting aktuator: $e');
      rethrow;
    }
  }

  /// Set pompa air (mosvet_1)
  Future<void> setPompaAir(bool value) async {
    await setAktuator('mosvet_1', value);
  }

  /// Set pompa pupuk (mosvet_2)
  Future<void> setPompaPupuk(bool value) async {
    await setAktuator('mosvet_2', value);
  }

  /// Set pengaduk/motor (mosvet_8)
  Future<void> setPengaduk(bool value) async {
    await setAktuator('mosvet_8', value);
  }

  /// Set pot/valve (mosvet_3 to mosvet_7 untuk POT 1-5)
  /// potNumber: 1-5
  Future<void> setPot(int potNumber, bool value) async {
    if (potNumber < 1 || potNumber > 5) {
      throw ArgumentError('Pot number must be between 1 and 5');
    }
    await setAktuator('mosvet_${potNumber + 2}', value);
  }

  /// Set multiple aktuator at once
  Future<void> setMultipleAktuator(Map<String, bool> aktuatorStates) async {
    try {
      await _database.child('aktuator').update(aktuatorStates);
    } catch (e) {
      print('Error setting multiple aktuator: $e');
      rethrow;
    }
  }

  /// Matikan semua aktuator
  Future<void> turnOffAllAktuator() async {
    await setMultipleAktuator({
      'mosvet_1': false,
      'mosvet_2': false,
      'mosvet_3': false,
      'mosvet_4': false,
      'mosvet_5': false,
      'mosvet_6': false,
      'mosvet_7': false,
      'mosvet_8': false,
    });
  }

  // ==================== KONTROL CONFIG ====================

  /// Get real-time stream of kontrol configuration
  Stream<Map<String, dynamic>> getKontrolStream() {
    return _database.child('kontrol').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  /// Get kontrol configuration once
  Future<Map<String, dynamic>> getKontrolConfig() async {
    try {
      final snapshot = await _database.child('kontrol').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Error getting kontrol config: $e');
    }
    return {};
  }

  /// Update kontrol configuration
  Future<void> updateKontrolConfig(Map<String, dynamic> config) async {
    try {
      print('🔥 [DEBUG] Updating Firebase kontrol config: $config');
      await _database.child('kontrol').update(config);
      print('✅ [DEBUG] Firebase kontrol config updated successfully');
    } catch (e) {
      print('❌ [DEBUG] Error updating kontrol config: $e');
      rethrow;
    }
  }

  /// Set batas threshold (batas_atas, batas_bawah)
  Future<void> setThreshold({int? batasAtas, int? batasBawah}) async {
    try {
      final updates = <String, dynamic>{};
      if (batasAtas != null) updates['batas_atas'] = batasAtas;
      if (batasBawah != null) updates['batas_bawah'] = batasBawah;
      await _database.child('kontrol').update(updates);
    } catch (e) {
      print('Error setting threshold: $e');
      rethrow;
    }
  }

  /// Set waktu penyiraman
  Future<void> setWaktuPenyiraman({
    String? waktu1,
    String? waktu2,
    bool? waktuEnabled,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (waktu1 != null) updates['waktu_1'] = waktu1;
      if (waktu2 != null) updates['waktu_2'] = waktu2;
      if (waktuEnabled != null) updates['waktu'] = waktuEnabled;
      await _database.child('kontrol').update(updates);
    } catch (e) {
      print('Error setting waktu: $e');
      rethrow;
    }
  }

  /// Set durasi penyiraman
  Future<void> setDurasi({int? durasi1, int? durasi2}) async {
    try {
      final updates = <String, dynamic>{};
      if (durasi1 != null) updates['durasi_1'] = durasi1;
      if (durasi2 != null) updates['durasi_2'] = durasi2;
      await _database.child('kontrol').update(updates);
    } catch (e) {
      print('Error setting durasi: $e');
      rethrow;
    }
  }

  /// Toggle mode otomatis
  Future<void> setOtomatis(bool value) async {
    try {
      await _database.child('kontrol/otomatis').set(value);
    } catch (e) {
      print('Error setting otomatis: $e');
      rethrow;
    }
  }

  // ==================== HELPER FUNCTIONS ====================

  /// Parse value dari Firebase (handle empty string)
  String _parseValue(dynamic value) {
    if (value == null || value == '') {
      return '0';
    }
    return value.toString();
  }

  /// Get database reference (untuk advanced usage)
  DatabaseReference get databaseRef => _database;

  /// Check connection status
  Stream<bool> getConnectionStatus() {
    return _database.child('.info/connected').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  // ==================== HISTORY LOGGING ====================

  /// Save sensor data snapshot to history
  Future<void> saveHistory(Map<String, dynamic> sensorData) async {
    try {
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeKey =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      await _database.child('history/$dateKey/$timeKey').set({
        ...sensorData,
        'timestamp': now.millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  /// Get history data for a specific date range
  Future<Map<String, dynamic>> getHistoryByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allHistory = <String, dynamic>{};

      // Loop through each day in the range
      for (
        var date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final snapshot = await _database.child('history/$dateKey').get();
        if (snapshot.exists) {
          allHistory[dateKey] = snapshot.value;
        }
      }

      return allHistory;
    } catch (e) {
      print('Error getting history: $e');
      return {};
    }
  }

  /// Get latest history entries (limit)
  Future<Map<String, dynamic>> getLatestHistory({int limit = 100}) async {
    try {
      final snapshot =
          await _database
              .child('history')
              .orderByKey()
              .limitToLast(limit)
              .get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Error getting latest history: $e');
    }
    return {};
  }

  /// Clear old history data (older than X days)
  Future<void> clearOldHistory({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final snapshot = await _database.child('history').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (var dateKey in data.keys) {
          try {
            final parts = dateKey.split('-');
            if (parts.length == 3) {
              final date = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );

              if (date.isBefore(cutoffDate)) {
                await _database.child('history/$dateKey').remove();
                print('Deleted old history: $dateKey');
              }
            }
          } catch (e) {
            print('Error parsing date key $dateKey: $e');
          }
        }
      }
    } catch (e) {
      print('Error clearing old history: $e');
    }
  }
}
