import 'package:firebase_database/firebase_database.dart';
import '../models/jadwal_model.dart';

/// Service untuk manage Jadwal di Firebase
class JadwalService {
  // Path untuk kontrol di Firebase (ubah sesuai kebutuhan)
  static const String kontrolPath = 'kontrol_1';

  final DatabaseReference _kontrolRef = FirebaseDatabase.instance.ref().child(
    kontrolPath,
  );

  /// Get all jadwal from Firebase
  Future<List<JadwalModel>> getAllJadwal() async {
    try {
      final snapshot = await _kontrolRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final List<JadwalModel> jadwalList = [];

      // Filter keys yang mulai dengan 'jadwal_'
      data.forEach((key, value) {
        if (key.toString().startsWith('jadwal_') && value is Map) {
          final jadwal = JadwalModel.fromJson(
            key.toString(),
            Map<String, dynamic>.from(value),
          );
          jadwalList.add(jadwal);
        }
      });

      // Sort by ID
      jadwalList.sort((a, b) => a.id.compareTo(b.id));

      return jadwalList;
    } catch (e) {
      print('Error getting all jadwal: $e');
      return [];
    }
  }

  /// Get single jadwal by ID
  Future<JadwalModel?> getJadwal(String jadwalId) async {
    try {
      final snapshot = await _kontrolRef.child(jadwalId).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return JadwalModel.fromJson(jadwalId, data);
    } catch (e) {
      print('Error getting jadwal $jadwalId: $e');
      return null;
    }
  }

  /// Save/Update jadwal to Firebase
  Future<bool> saveJadwal(JadwalModel jadwal) async {
    try {
      await _kontrolRef.child(jadwal.id).set(jadwal.toJson());
      print('✅ Jadwal ${jadwal.id} saved successfully');
      return true;
    } catch (e) {
      print('❌ Error saving jadwal ${jadwal.id}: $e');
      return false;
    }
  }

  /// Delete jadwal from Firebase
  Future<bool> deleteJadwal(String jadwalId) async {
    try {
      await _kontrolRef.child(jadwalId).remove();
      print('✅ Jadwal $jadwalId deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting jadwal $jadwalId: $e');
      return false;
    }
  }

  /// Toggle jadwal aktif/nonaktif
  Future<bool> toggleJadwalAktif(String jadwalId, bool aktif) async {
    try {
      await _kontrolRef.child(jadwalId).child('aktif').set(aktif);
      print('✅ Jadwal $jadwalId set to ${aktif ? "aktif" : "nonaktif"}');
      return true;
    } catch (e) {
      print('❌ Error toggling jadwal $jadwalId: $e');
      return false;
    }
  }

  /// Get next available jadwal ID
  Future<String> getNextJadwalId() async {
    try {
      final jadwalList = await getAllJadwal();

      if (jadwalList.isEmpty) {
        return 'jadwal_1';
      }

      // Extract numbers from existing IDs
      final numbers =
          jadwalList
              .map((j) => int.tryParse(j.id.replaceAll('jadwal_', '')) ?? 0)
              .toList();

      final maxNumber = numbers.reduce((a, b) => a > b ? a : b);

      return 'jadwal_${maxNumber + 1}';
    } catch (e) {
      print('Error getting next jadwal ID: $e');
      return 'jadwal_1';
    }
  }

  /// Get waktu mode status
  Future<bool> getWaktuModeStatus() async {
    try {
      final snapshot = await _kontrolRef.child('waktu').get();
      return snapshot.value as bool? ?? false;
    } catch (e) {
      print('Error getting waktu mode status: $e');
      return false;
    }
  }

  /// Set waktu mode status
  Future<bool> setWaktuModeStatus(bool enabled) async {
    try {
      await _kontrolRef.child('waktu').set(enabled);
      print('✅ Waktu mode set to ${enabled ? "enabled" : "disabled"}');
      return true;
    } catch (e) {
      print('❌ Error setting waktu mode: $e');
      return false;
    }
  }

  /// Duplicate jadwal (copy with new ID)
  Future<String?> duplicateJadwal(JadwalModel jadwal) async {
    try {
      final newId = await getNextJadwalId();
      final newJadwal = jadwal.copyWith(
        id: newId,
        aktif: false, // Set nonaktif by default
      );

      final success = await saveJadwal(newJadwal);
      return success ? newId : null;
    } catch (e) {
      print('Error duplicating jadwal: $e');
      return null;
    }
  }

  /// Stream for real-time updates
  Stream<List<JadwalModel>> watchAllJadwal() {
    return _kontrolRef.onValue.map((event) {
      if (!event.snapshot.exists) {
        return <JadwalModel>[];
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<JadwalModel> jadwalList = [];

      data.forEach((key, value) {
        if (key.toString().startsWith('jadwal_') && value is Map) {
          final jadwal = JadwalModel.fromJson(
            key.toString(),
            Map<String, dynamic>.from(value),
          );
          jadwalList.add(jadwal);
        }
      });

      jadwalList.sort((a, b) => a.id.compareTo(b.id));
      return jadwalList;
    });
  }

  /// Validate time format
  bool isValidTimeFormat(String time) {
    final regex = RegExp(r'^([0-1][0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  /// Get active jadwal count
  Future<int> getActiveJadwalCount() async {
    try {
      final jadwalList = await getAllJadwal();
      return jadwalList.where((j) => j.aktif).length;
    } catch (e) {
      print('Error getting active jadwal count: $e');
      return 0;
    }
  }

  /// Check if time slot is already taken
  Future<bool> isTimeSlotTaken(String waktu, {String? excludeJadwalId}) async {
    try {
      final jadwalList = await getAllJadwal();
      return jadwalList.any(
        (j) => j.waktu == waktu && j.aktif && j.id != excludeJadwalId,
      );
    } catch (e) {
      print('Error checking time slot: $e');
      return false;
    }
  }
}
