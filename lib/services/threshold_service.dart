import 'package:firebase_database/firebase_database.dart';
import '../models/threshold_model.dart';

class ThresholdService {
  static const String kontrolPath = 'kontrol_1';
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Get semua threshold dari Firebase
  static Future<List<ThresholdModel>> getAllThreshold() async {
    try {
      final snapshot = await _dbRef.child(kontrolPath).get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      // Filter hanya yang key-nya dimulai dengan 'threshold_'
      final thresholdList = <ThresholdModel>[];
      data.forEach((key, value) {
        if (key.toString().startsWith('threshold_') && value is Map) {
          try {
            final threshold = ThresholdModel.fromJson(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            );
            thresholdList.add(threshold);
          } catch (e) {
            print('Error parsing threshold $key: $e');
          }
        }
      });

      // Sort by ID (threshold_1, threshold_2, ...)
      thresholdList.sort((a, b) {
        final numA = int.tryParse(a.id.replaceAll('threshold_', '')) ?? 0;
        final numB = int.tryParse(b.id.replaceAll('threshold_', '')) ?? 0;
        return numA.compareTo(numB);
      });

      return thresholdList;
    } catch (e) {
      print('Error getting all threshold: $e');
      return [];
    }
  }

  // Save threshold (create atau update)
  static Future<bool> saveThreshold(ThresholdModel threshold) async {
    try {
      await _dbRef
          .child(kontrolPath)
          .child(threshold.id)
          .set(threshold.toJson());
      return true;
    } catch (e) {
      print('Error saving threshold: $e');
      return false;
    }
  }

  // Delete threshold
  static Future<bool> deleteThreshold(String id) async {
    try {
      await _dbRef.child(kontrolPath).child(id).remove();
      return true;
    } catch (e) {
      print('Error deleting threshold: $e');
      return false;
    }
  }

  // Toggle threshold aktif/nonaktif
  static Future<bool> toggleThresholdAktif(String id, bool aktif) async {
    try {
      await _dbRef.child(kontrolPath).child(id).child('aktif').set(aktif);
      return true;
    } catch (e) {
      print('Error toggling threshold: $e');
      return false;
    }
  }

  // Duplicate threshold dengan ID baru
  static Future<String?> duplicateThreshold(ThresholdModel threshold) async {
    try {
      final allThresholds = await getAllThreshold();

      // Cari ID tertinggi
      int maxId = 0;
      for (var t in allThresholds) {
        final num = int.tryParse(t.id.replaceAll('threshold_', '')) ?? 0;
        if (num > maxId) maxId = num;
      }

      final newId = 'threshold_${maxId + 1}';
      final newThreshold = threshold.copyWith(
        id: newId,
        aktif: false, // Duplikat dimulai dengan nonaktif
      );

      final success = await saveThreshold(newThreshold);
      return success ? newId : null;
    } catch (e) {
      print('Error duplicating threshold: $e');
      return null;
    }
  }

  // Get single threshold by ID
  static Future<ThresholdModel?> getThreshold(String id) async {
    try {
      final snapshot = await _dbRef.child(kontrolPath).child(id).get();

      if (!snapshot.exists) return null;

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;

      return ThresholdModel.fromJson(id, data);
    } catch (e) {
      print('Error getting threshold: $e');
      return null;
    }
  }

  // Watch semua threshold (real-time stream)
  static Stream<List<ThresholdModel>> watchAllThreshold() {
    return _dbRef.child(kontrolPath).onValue.map((event) {
      if (!event.snapshot.exists) return [];

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final thresholdList = <ThresholdModel>[];
      data.forEach((key, value) {
        if (key.toString().startsWith('threshold_') && value is Map) {
          try {
            final threshold = ThresholdModel.fromJson(
              key.toString(),
              Map<dynamic, dynamic>.from(value),
            );
            thresholdList.add(threshold);
          } catch (e) {
            print('Error parsing threshold $key: $e');
          }
        }
      });

      // Sort by ID
      thresholdList.sort((a, b) {
        final numA = int.tryParse(a.id.replaceAll('threshold_', '')) ?? 0;
        final numB = int.tryParse(b.id.replaceAll('threshold_', '')) ?? 0;
        return numA.compareTo(numB);
      });

      return thresholdList;
    });
  }

  // Cek apakah ada range yang overlap dengan threshold lain
  static Future<bool> isRangeOverlap(
    String currentId,
    int batasBawah,
    int batasAtas,
    List<int> potAktif,
  ) async {
    try {
      final allThresholds = await getAllThreshold();

      for (var threshold in allThresholds) {
        // Skip threshold yang sama
        if (threshold.id == currentId) continue;

        // Cek apakah ada pot yang sama
        final hasSamePot = threshold.potAktif.any(
          (pot) => potAktif.contains(pot),
        );
        if (!hasSamePot) continue;

        // Cek apakah range overlap
        final rangeOverlap =
            !(batasAtas < threshold.batasBawah ||
                batasBawah > threshold.batasAtas);

        if (rangeOverlap) return true;
      }

      return false;
    } catch (e) {
      print('Error checking range overlap: $e');
      return false;
    }
  }

  // Get next available threshold ID
  static Future<String> getNextThresholdId() async {
    try {
      final allThresholds = await getAllThreshold();

      if (allThresholds.isEmpty) return 'threshold_1';

      // Cari ID tertinggi
      int maxId = 0;
      for (var t in allThresholds) {
        final num = int.tryParse(t.id.replaceAll('threshold_', '')) ?? 0;
        if (num > maxId) maxId = num;
      }

      return 'threshold_${maxId + 1}';
    } catch (e) {
      print('Error getting next threshold ID: $e');
      return 'threshold_1';
    }
  }

  // Get sensor mode status (otomatis)
  static Future<bool> getSensorModeStatus() async {
    try {
      final snapshot = await _dbRef.child(kontrolPath).child('otomatis').get();
      return snapshot.value as bool? ?? false;
    } catch (e) {
      print('Error getting sensor mode status: $e');
      return false;
    }
  }

  // Set sensor mode status (otomatis)
  static Future<bool> setSensorModeStatus(bool enabled) async {
    try {
      await _dbRef.child(kontrolPath).child('otomatis').set(enabled);
      print('✅ Sensor mode set to ${enabled ? "enabled" : "disabled"}');
      return true;
    } catch (e) {
      print('❌ Error setting sensor mode: $e');
      return false;
    }
  }
}
