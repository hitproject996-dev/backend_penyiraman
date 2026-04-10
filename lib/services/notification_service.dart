import 'dart:convert';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 🔔 NOTIFICATION SERVICE v2.0 - WITH BACKGROUND SUPPORT
///
/// Fitur Utama:
/// ✅ Exact alarm scheduling untuk precision timing
/// ✅ Background notifications (muncul bahkan saat app minimized!)
/// ✅ Retry logic untuk reliability
/// ✅ Multiple notification channels (watering, alert, info)
/// ✅ Full Firebase Cloud Messaging support
/// ✅ Proper permission handling
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String topicName = 'apsgo_notifications';
  static const String wateringChannelId = 'apsgo_watering_channel';
  static const String alertChannelId = 'apsgo_alert_channel';
  static const String infoChannelId = 'apsgo_info_channel';
  static const int _maxAndroidNotificationId = 2147483647;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  int _notificationCounter = 0;

  /// ==================== INITIALIZATION ====================

  /// Initialize notification service dengan complete setup
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    debugPrint('🔔 Initializing Notification Service v2.0...');

    // Setup timezones
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    // Android & iOS initialization
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize dengan background response support
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onNotificationResponse,
    );

    // Setup channels & permissions
    await _setupNotificationChannels();
    await _requestAllPermissions();

    // Firebase setup
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topicName);
      debugPrint('✅ Subscribed to Firebase topic: $topicName');
    } catch (e) {
      debugPrint('⚠️ Firebase subscription failed: $e');
    }

    _setupFCMHandlers();
    _isInitialized = true;
    debugPrint('✅ Notification Service v2.0 ready!');
  }

  /// Setup notification channels
  Future<void> _setupNotificationChannels() async {
    final androidPlugin =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin == null) return;

    try {
      // Watering channel - PRIORITY TINGGI
      const wateringChannel = AndroidNotificationChannel(
        wateringChannelId,
        'ApsGo Penyiraman',
        description: 'Notifikasi penyiraman - selalu muncul!',
        importance: Importance.max,
        playSound: true,
        enableLights: true,
        enableVibration: true,
      );

      // Alert channel
      const alertChannel = AndroidNotificationChannel(
        alertChannelId,
        'ApsGo Alert',
        description: 'Alert dan warning dari sistem',
        importance: Importance.high,
        playSound: true,
        enableLights: true,
        enableVibration: true,
      );

      // Info channel
      const infoChannel = AndroidNotificationChannel(
        infoChannelId,
        'ApsGo Informasi',
        description: 'Informasi sistem ApsGo',
        importance: Importance.low,
        playSound: false,
        enableLights: false,
        enableVibration: false,
      );

      await Future.wait([
        androidPlugin.createNotificationChannel(wateringChannel),
        androidPlugin.createNotificationChannel(alertChannel),
        androidPlugin.createNotificationChannel(infoChannel),
      ]);
      debugPrint('✅ Notification channels created');
    } catch (e) {
      debugPrint('❌ Error creating channels: $e');
    }
  }

  /// Request all permissions
  Future<void> _requestAllPermissions() async {
    try {
      final androidPlugin =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Notifications permission
      await androidPlugin?.requestNotificationsPermission();

      // Exact alarms permission
      final canScheduleExact =
          await androidPlugin?.canScheduleExactNotifications() ?? false;
      if (!canScheduleExact) {
        await androidPlugin?.requestExactAlarmsPermission();
      }

      // iOS permissions
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // Firebase permissions
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('✅ All permissions requested');
    } catch (e) {
      debugPrint('⚠️ Permission error: $e');
    }
  }

  /// Setup FCM handlers
  void _setupFCMHandlers() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('📨 FCM onMessage: ${message.messageId}');
      _showRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('📨 FCM onMessageOpenedApp: ${message.messageId}');
    });
  }

  /// ==================== NOTIFICATION DISPLAY ====================

  /// Build watering notification details (HIGH PRIORITY)
  NotificationDetails _buildWateringNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        wateringChannelId,
        'ApsGo Penyiraman',
        channelDescription: 'Notifikasi penyiraman',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        autoCancel: true,
        showWhen: true,
        fullScreenIntent: true,
        tag: 'watering',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'watering',
      ),
    );
  }

  /// Build alert notification details
  NotificationDetails _buildAlertNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        alertChannelId,
        'ApsGo Alert',
        channelDescription: 'Alert dan warning',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        autoCancel: true,
        showWhen: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Build basic notification details
  NotificationDetails _buildBasicNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        infoChannelId,
        'ApsGo Informasi',
        channelDescription: 'Informasi sistem',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
        autoCancel: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: true,
        presentSound: false,
      ),
    );
  }

  /// Show instant notification
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
    bool isWatering = false,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    try {
      final details =
          isWatering
              ? _buildWateringNotificationDetails()
              : _buildBasicNotificationDetails();

      await _plugin.show(_nextId(), title, body, details, payload: payload);

      debugPrint('✅ Notification: "$title"');
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  /// Show watering notification (PENTING UNTUK PENYIRAMAN!)
  Future<void> showWateringNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    try {
      await _plugin.show(
        _nextId(),
        title,
        body,
        _buildWateringNotificationDetails(),
        payload: payload == null ? null : jsonEncode(payload),
      );

      debugPrint('✅ Watering notification: "$title" - "$body"');
    } catch (e) {
      debugPrint('❌ Error showing watering notification: $e');
    }
  }

  /// Show alert notification
  Future<void> showAlertNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    try {
      await _plugin.show(
        _nextId(),
        title,
        body,
        _buildAlertNotificationDetails(),
        payload: payload,
      );

      debugPrint('✅ Alert notification: "$title"');
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  /// Show mode changed notification
  Future<void> showModeChangedNotification({
    required String modeLabel,
    required bool enabled,
  }) async {
    final body =
        enabled
            ? 'Mode diubah menjadi penyiraman $modeLabel.'
            : 'Mode penyiraman $modeLabel dinonaktifkan.';

    await showInstantNotification(
      title: 'Mode Penyiraman',
      body: body,
      payload: jsonEncode({'type': 'mode_change', 'mode': modeLabel}),
    );
  }

  /// ==================== SCHEDULING ====================

  /// Schedule notification dengan retry logic
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required Duration delay,
    String? payload,
    int retryCount = 3,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    for (int attempt = 1; attempt <= retryCount; attempt++) {
      try {
        final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);
        final androidPlugin =
            _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        final canScheduleExact =
            await androidPlugin?.canScheduleExactNotifications() ?? false;
        final scheduleMode =
            canScheduleExact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle;

        await _plugin.zonedSchedule(
          _nextId(),
          title,
          body,
          scheduledDate,
          _buildWateringNotificationDetails(),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );

        debugPrint('✅ Scheduled: "$title" in ${delay.inSeconds}s');
        return;
      } catch (e) {
        if (attempt < retryCount) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        } else {
          debugPrint('❌ Failed after $retryCount attempts: $e');
        }
      }
    }
  }

  /// Schedule daily notification
  Future<void> scheduleDailyNotificationAtTime({
    required String scheduleKey,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final androidPlugin =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final canScheduleExact =
          await androidPlugin?.canScheduleExactNotifications() ?? false;
      final scheduleMode =
          canScheduleExact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.zonedSchedule(
        _stableIdFromKey(scheduleKey),
        title,
        body,
        scheduled,
        _buildWateringNotificationDetails(),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      debugPrint(
        '✅ Daily scheduled at $hour:${minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }

  /// Cancel notification
  Future<void> cancelScheduledNotification(String scheduleKey) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    try {
      await _plugin.cancel(_stableIdFromKey(scheduleKey));
      debugPrint('✅ Cancelled: $scheduleKey');
    } catch (e) {
      debugPrint('⚠️ Error: $e');
    }
  }

  /// Sync schedule reminders from Firebase
  Future<void> syncScheduleRemindersFromFirebase() async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    debugPrint('📡 Syncing schedules from Firebase...');

    final db = FirebaseDatabase.instance.ref();
    await _syncFromKontrolNode(db.child('kontrol'), 'kontrol');
    await _syncFromKontrolNode(db.child('kontrol_1'), 'kontrol_1');
  }

  Future<void> _syncFromKontrolNode(
    DatabaseReference ref,
    String nodeName,
  ) async {
    try {
      final snapshot = await ref.get();
      if (!snapshot.exists || snapshot.value is! Map) {
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final waktuEnabled = data['waktu'] == true;

      final scheduleKeys =
          data.keys.where((key) => key.startsWith('jadwal_')).toList()..sort();

      for (final key in scheduleKeys) {
        final scheduleKey = '$nodeName:$key';
        final scheduleDataRaw = data[key];
        if (scheduleDataRaw is! Map) {
          await cancelScheduledNotification(scheduleKey);
          continue;
        }

        final scheduleData = Map<String, dynamic>.from(scheduleDataRaw);
        final aktif = scheduleData['aktif'] != false;
        final waktu = (scheduleData['waktu'] ?? '').toString();
        final isValidTime = RegExp(
          r'^([01]\d|2[0-3]):[0-5]\d$',
        ).hasMatch(waktu);

        if (!waktuEnabled || !aktif || !isValidTime) {
          await cancelScheduledNotification(scheduleKey);
          continue;
        }

        final parts = waktu.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        await scheduleDailyNotificationAtTime(
          scheduleKey: scheduleKey,
          title: 'ApsGo - Jadwal Penyiraman',
          body: 'Penyiraman akan dimulai pada jam $waktu',
          hour: hour,
          minute: minute,
          payload: jsonEncode({
            'type': 'local_schedule',
            'key': key,
            'time': waktu,
          }),
        );
      }
    } catch (e) {
      debugPrint('❌ Error syncing $nodeName: $e');
    }
  }

  /// ==================== FIREBASE & FCM ====================

  Future<String?> getFcmToken() async {
    if (kIsWeb) return null;
    if (!_isInitialized) await initialize();

    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token;
    } catch (e) {
      debugPrint('❌ FCM token error: $e');
      return null;
    }
  }

  Future<void> _showRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'ApsGo';
    final body = notification?.body ?? '';

    if (body.isEmpty) return;

    await showInstantNotification(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
      isWatering: body.toLowerCase().contains('penyiraman'),
    );
  }

  /// ==================== UTILITIES ====================

  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    if (kIsWeb) return <PendingNotificationRequest>[];
    if (!_isInitialized) await initialize();

    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('⚠️ Error: $e');
      return [];
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('⚠️ Error: $e');
    }
  }

  Future<bool> canScheduleExactNotifications() async {
    if (kIsWeb) return false;
    if (!_isInitialized) await initialize();

    final androidPlugin =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  Future<bool> requestExactAlarmsPermission() async {
    if (kIsWeb) return false;
    if (!_isInitialized) await initialize();

    final androidPlugin =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    try {
      return await androidPlugin?.requestExactAlarmsPermission() ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ==================== PRIVATE HELPERS ====================

  int _nextId() {
    _notificationCounter = (_notificationCounter + 1) % 100000;
    final nowPart = DateTime.now().millisecondsSinceEpoch % 2000000000;
    final id = nowPart + _notificationCounter;
    return id > _maxAndroidNotificationId ? id - _maxAndroidNotificationId : id;
  }

  int _stableIdFromKey(String key) {
    var hash = 0;
    for (final codeUnit in key.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash % _maxAndroidNotificationId;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      debugPrint('🔔 Notification response payload: $payload');
    }
  }
}
