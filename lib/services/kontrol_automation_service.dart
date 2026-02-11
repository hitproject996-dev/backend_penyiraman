import 'dart:async';
import 'package:flutter/foundation.dart';
import 'firebase_database_service.dart';
import 'automation_constants.dart';
import 'connection_monitor_service.dart';

/// Service untuk menghandle logika otomatis kontrol waktu dan sensor
/// Berjalan di background untuk monitoring dan eksekusi otomatis
class KontrolAutomationService {
  static final KontrolAutomationService _instance =
      KontrolAutomationService._internal();
  factory KontrolAutomationService() => _instance;
  KontrolAutomationService._internal();

  final FirebaseDatabaseService _dbService = FirebaseDatabaseService();
  final ConnectionMonitorService _connectionMonitor =
      ConnectionMonitorService();

  Timer? _waktuCheckTimer;
  Timer? _sensorCheckTimer;
  StreamSubscription? _sensorSubscription;
  StreamSubscription? _kontrolSubscription;

  bool _isWaktuModeActive = false;
  bool _isSensorModeActive = false;

  // State untuk mencegah trigger berulang
  final Map<String, DateTime> _lastWateringTime = {};
  final Map<String, bool> _isWateringActive = {};

  // ==================== KONTROL WAKTU ====================

  /// Start monitoring waktu mode
  /// Cek setiap menit apakah ada jadwal yang harus dijalankan
  void startWaktuMode() {
    if (_isWaktuModeActive) return;

    // Start connection monitor
    _connectionMonitor.start();

    _isWaktuModeActive = true;
    debugPrint('🕐 Waktu Mode: Started');

    // Cek setiap 30 detik (gunakan constant)
    _waktuCheckTimer = Timer.periodic(
      Duration(seconds: AutomationConstants.waktuCheckInterval),
      (timer) => _checkScheduledWatering(),
    );

    // Jalankan check pertama kali
    _checkScheduledWatering();
  }

  /// Stop monitoring waktu mode
  void stopWaktuMode() {
    _waktuCheckTimer?.cancel();
    _waktuCheckTimer = null;
    _isWaktuModeActive = false;
    debugPrint('🕐 Waktu Mode: Stopped');
  }

  /// Check apakah ada jadwal penyiraman yang harus dijalankan
  Future<void> _checkScheduledWatering() async {
    try {
      // Check connection first
      if (!_connectionMonitor.isConnected) {
        debugPrint('⚠️ No Firebase connection, skipping schedule check');
        return;
      }

      final kontrolConfig = await _dbService.getKontrolConfig();
      final waktuEnabled = kontrolConfig['waktu'] ?? false;

      if (!waktuEnabled || !_isWaktuModeActive) return;

      final now = DateTime.now();
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final waktu1 = kontrolConfig['waktu_1'] ?? '';
      final waktu2 = kontrolConfig['waktu_2'] ?? '';
      final durasi1 =
          kontrolConfig['durasi_1'] ?? AutomationConstants.defaultDurasiDetik;
      final durasi2 =
          kontrolConfig['durasi_2'] ?? AutomationConstants.defaultDurasiDetik;

      // Check Jadwal 1
      if (waktu1.isNotEmpty &&
          _shouldStartWatering('jadwal_1', currentTime, waktu1)) {
        debugPrint('🕐 Executing Jadwal 1 at $currentTime');
        await _executeWatering(
          scheduleId: 'jadwal_1',
          pompaAir: true,
          pompaPupuk: true,
          pots: [1, 2, 3, 4, 5], // Semua pot
          durasiDetik: durasi1,
        );
      }

      // Check Jadwal 2
      if (waktu2.isNotEmpty &&
          _shouldStartWatering('jadwal_2', currentTime, waktu2)) {
        debugPrint('🕐 Executing Jadwal 2 at $currentTime');
        await _executeWatering(
          scheduleId: 'jadwal_2',
          pompaAir: true,
          pompaPupuk: true,
          pots: [1, 2, 3, 4, 5], // Semua pot
          durasiDetik: durasi2,
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking scheduled watering: $e');
    }
  }

  /// Check apakah jadwal harus dijalankan
  bool _shouldStartWatering(
    String scheduleId,
    String currentTime,
    String targetTime,
  ) {
    // Cek apakah waktu sekarang sama dengan target
    if (currentTime != targetTime) return false;

    // Cek apakah sudah berjalan
    if (_isWateringActive[scheduleId] == true) return false;

    // Cek apakah sudah pernah dijalankan dalam 1 menit terakhir (prevent double trigger)
    final lastTime = _lastWateringTime[scheduleId];
    if (lastTime != null) {
      final diff = DateTime.now().difference(lastTime);
      if (diff.inSeconds < 60) return false;
    }

    return true;
  }

  /// Execute penyiraman dengan durasi tertentu
  Future<void> _executeWatering({
    required String scheduleId,
    required bool pompaAir,
    required bool pompaPupuk,
    required List<int> pots,
    required int durasiDetik,
  }) async {
    try {
      _isWateringActive[scheduleId] = true;
      _lastWateringTime[scheduleId] = DateTime.now();

      // Nyalakan pompa dan valve
      final updates = <String, bool>{};
      if (pompaAir) updates['mosvet_1'] = true;
      if (pompaPupuk) updates['mosvet_2'] = true;

      for (var pot in pots) {
        if (pot >= 1 && pot <= 5) {
          updates['mosvet_${pot + 2}'] = true;
        }
      }

      await _dbService.setMultipleAktuator(updates);
      debugPrint('✅ Watering started: $updates');

      // Tunggu sesuai durasi
      await Future.delayed(Duration(seconds: durasiDetik));

      // Matikan semua
      final offUpdates = <String, bool>{};
      updates.forEach((key, _) => offUpdates[key] = false);
      await _dbService.setMultipleAktuator(offUpdates);

      debugPrint('✅ Watering completed for $scheduleId');
      _isWateringActive[scheduleId] = false;
    } catch (e) {
      debugPrint('❌ Error executing watering: $e');
      _isWateringActive[scheduleId] = false;
    }
  }

  // ==================== KONTROL SENSOR ====================

  /// Start monitoring sensor mode
  void startSensorMode() {
    if (_isSensorModeActive) return;

    // Start connection monitor
    _connectionMonitor.start();

    _isSensorModeActive = true;
    debugPrint('🌡️ Sensor Mode: Started');

    // Monitor perubahan sensor lebih responsif (gunakan constant)
    _sensorCheckTimer = Timer.periodic(
      Duration(seconds: AutomationConstants.sensorCheckInterval),
      (timer) => _checkSensorThreshold(),
    );

    // Listen to sensor data real-time
    _sensorSubscription = _dbService.getSensorDataStream().listen((sensorData) {
      if (_isSensorModeActive) {
        _processSensorData(sensorData);
      }
    });

    // Jalankan check pertama kali
    _checkSensorThreshold();
  }

  /// Stop monitoring sensor mode
  void stopSensorMode() {
    _sensorCheckTimer?.cancel();
    _sensorCheckTimer = null;
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
    _isSensorModeActive = false;
    debugPrint('🌡️ Sensor Mode: Stopped');
  }

  /// Check sensor threshold untuk semua pot
  Future<void> _checkSensorThreshold() async {
    try {
      // Check connection first
      if (!_connectionMonitor.isConnected) {
        debugPrint('⚠️ No Firebase connection, skipping sensor check');
        return;
      }

      final kontrolConfig = await _dbService.getKontrolConfig();
      final otomatisEnabled = kontrolConfig['otomatis'] ?? false;

      if (!otomatisEnabled || !_isSensorModeActive) return;

      final batasAtas =
          kontrolConfig['batas_atas'] ?? AutomationConstants.defaultBatasAtas;
      final batasBawah =
          kontrolConfig['batas_bawah'] ?? AutomationConstants.defaultBatasBawah;
      final durasiSensor =
          kontrolConfig['durasi_sensor'] ??
          AutomationConstants.defaultDurasiDetik;
      final modeSensor =
          kontrolConfig['mode_sensor'] ?? AutomationConstants.modeSensorFixed;

      final sensorData = await _dbService.getSensorData();

      // Check setiap pot (soil_1 sampai soil_5)
      debugPrint(
        '🌡️ Checking thresholds: batas_bawah=$batasBawah, batas_atas=$batasAtas, mode=$modeSensor, durasi=${durasiSensor}s',
      );

      for (int i = 1; i <= AutomationConstants.totalPots; i++) {
        final soilKey = 'soil_$i';
        final soilValue = int.tryParse(sensorData[soilKey] ?? '0') ?? 0;

        debugPrint('🌡️ $soilKey = $soilValue (threshold: $batasBawah)');

        // Jika kelembapan di bawah batas bawah, siram pot tersebut
        if (soilValue < batasBawah) {
          debugPrint(
            '⚠️ $soilKey ($soilValue) < batasBawah ($batasBawah) → Triggering watering for POT $i',
          );
          await _waterPotBySensor(
            potNumber: i,
            soilValue: soilValue,
            batasBawah: batasBawah,
            batasAtas: batasAtas,
            durasiSeconds: durasiSensor,
            mode: modeSensor,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking sensor threshold: $e');
    }
  }

  /// Process sensor data real-time
  void _processSensorData(Map<String, dynamic> sensorData) {
    // Could be used for real-time alerts or logging
    // For now, the periodic check is sufficient
  }

  /// Siram pot berdasarkan sensor
  Future<void> _waterPotBySensor({
    required int potNumber,
    required int soilValue,
    required int batasBawah,
    required int batasAtas,
    required int durasiSeconds,
    required String mode,
  }) async {
    final potKey = 'pot_$potNumber';

    // Prevent multiple watering in short time
    if (_isWateringActive[potKey] == true) return;

    final lastTime = _lastWateringTime[potKey];
    if (lastTime != null) {
      final diff = DateTime.now().difference(lastTime);
      final cooldownSeconds = AutomationConstants.wateringCooldownSeconds;
      if (diff.inSeconds < cooldownSeconds) {
        debugPrint(
          '⏳ POT $potNumber: Cooldown active (${cooldownSeconds - diff.inSeconds}s remaining)',
        );
        return; // Minimum cooldown antar penyiraman
      }
    }

    try {
      _isWateringActive[potKey] = true;
      _lastWateringTime[potKey] = DateTime.now();

      debugPrint(
        '🌡️ Sensor Mode: Watering POT $potNumber (soil: $soilValue < $batasBawah)',
      );
      debugPrint('🔧 Mode: $mode, Durasi: ${durasiSeconds}s');

      // Nyalakan pompa air dan valve pot tersebut
      // pot 1 → mosvet_3, pot 2 → mosvet_4, ... pot 5 → mosvet_7
      debugPrint(
        '💧 Starting watering: POT $potNumber (mosvet_${potNumber + 2})',
      );
      await _dbService.setPompaAir(true);
      await _dbService.setPot(potNumber, true);

      int elapsedSeconds = 0;

      if (mode == 'smart') {
        // SMART MODE: Siram sampai batas atas atau timeout
        debugPrint(
          '🧠 Smart Mode: Target soil_$potNumber >= $batasAtas (currently: $soilValue), max ${durasiSeconds}s',
        );

        while (elapsedSeconds < durasiSeconds && _isSensorModeActive) {
          await Future.delayed(const Duration(seconds: 5));
          elapsedSeconds += 5;

          // Check sensor lagi
          final currentData = await _dbService.getSensorData();
          final currentSoil =
              int.tryParse(currentData['soil_$potNumber'] ?? '0') ?? 0;

          debugPrint(
            '💧 POT $potNumber watering: ${elapsedSeconds}s, soil_$potNumber: $currentSoil',
          );

          if (currentSoil >= batasAtas) {
            debugPrint(
              '✅ POT $potNumber reached target: $currentSoil >= $batasAtas (Smart Mode)',
            );
            break;
          }
        }

        if (elapsedSeconds >= durasiSeconds) {
          debugPrint(
            '⏰ POT $potNumber timeout: ${elapsedSeconds}s (Smart Mode safety)',
          );
        }
      } else {
        // FIXED DURATION MODE: Siram selama durasi tetap
        debugPrint(
          '⏱️ Fixed Duration Mode: Watering for exactly ${durasiSeconds}s',
        );

        while (elapsedSeconds < durasiSeconds && _isSensorModeActive) {
          await Future.delayed(const Duration(seconds: 5));
          elapsedSeconds += 5;

          // Check sensor untuk logging saja (tidak break)
          final currentData = await _dbService.getSensorData();
          final currentSoil =
              int.tryParse(currentData['soil_$potNumber'] ?? '0') ?? 0;

          debugPrint(
            '💧 POT $potNumber watering: ${elapsedSeconds}s/${durasiSeconds}s, soil_$potNumber: $currentSoil',
          );
        }

        debugPrint(
          '✅ POT $potNumber fixed duration completed: ${durasiSeconds}s',
        );
      }

      // Matikan pompa dan valve
      await _dbService.setPompaAir(false);
      await _dbService.setPot(potNumber, false);

      debugPrint(
        '✅ Sensor Mode: Watering completed for POT $potNumber (${elapsedSeconds}s, mode: $mode)',
      );

      // Pastikan flag ter-reset dengan benar
      await Future.delayed(const Duration(milliseconds: 500));
      _isWateringActive[potKey] = false;
    } catch (e) {
      debugPrint('❌ Error watering pot by sensor: $e');

      // Matikan semua untuk safety
      try {
        await _dbService.setPompaAir(false);
        await _dbService.setPot(potNumber, false);
      } catch (cleanupError) {
        debugPrint('❌ Error during cleanup: $cleanupError');
      }

      // Reset flag
      _isWateringActive[potKey] = false;
    }
  }

  // ==================== UTILITY ====================

  /// Get status semua automation
  Map<String, bool> getAutomationStatus() {
    return {'waktuMode': _isWaktuModeActive, 'sensorMode': _isSensorModeActive};
  }

  /// Stop semua automation
  void stopAll() {
    stopWaktuMode();
    stopSensorMode();
    debugPrint('⏹️ All automation stopped');
  }

  /// Cleanup saat app dispose
  void dispose() {
    stopAll();
    _kontrolSubscription?.cancel();
  }
}
