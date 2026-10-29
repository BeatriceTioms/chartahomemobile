import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Asks the system for permission to notify, and shows local notices.
///
/// Remote push (rent reminders, ticket updates sent by the server) needs a
/// push provider on top: Firebase Cloud Messaging for Android and iOS. Once
/// it is added, its token goes to AppState.registerPushToken, which saves it
/// in `resident_devices` for the server to send to. See backend/README.md.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Ask later, from our own screen, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Shows the system prompt. True when the resident allowed notifications.
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    return false;
  }

  // The news is scheduled two weeks ahead and rescheduled each time the app
  // opens, so it stops by itself for someone who no longer uses the app.
  static const _newsBase = 9000;
  static const _newsDays = 14;
  static const newsTimes = [(9, 0), (18, 30)];

  /// Schedules the twice-daily Charta Home news, from [messages] in turn
  /// (title, body). Replaces whatever was scheduled before.
  Future<void> scheduleNews(List<(String, String)> messages) async {
    await init();
    await cancelNews();
    if (messages.isEmpty) return;
    tzdata.initializeTimeZones();
    final now = DateTime.now();
    // A different starting message each day of the year, so a reinstall does
    // not repeat yesterday's.
    final start = now.difference(DateTime(now.year)).inDays * newsTimes.length;
    var slot = 0;
    for (var d = 0; d < _newsDays; d++) {
      for (final (h, m) in newsTimes) {
        final at = DateTime(now.year, now.month, now.day + d, h, m);
        final id = _newsBase + slot;
        final (title, body) = messages[(start + slot) % messages.length];
        slot++;
        if (!at.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(at, tz.UTC),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'charta_news',
              'Charta Home news',
              channelDescription: 'New homes, offers and tips, twice a day',
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    }
  }

  Future<void> cancelNews() async {
    await init();
    for (var i = 0; i < _newsDays * newsTimes.length; i++) {
      await _plugin.cancel(id: _newsBase + i);
    }
  }

  Future<void> show({required int id, required String title, required String body}) async {
    await init();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'charta_home',
          'Charta Home',
          channelDescription: 'Rent, repairs and stays',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
