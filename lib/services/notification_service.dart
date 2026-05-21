import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin? _notificationsPlugin =
      kIsWeb ? null : FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    if (kIsWeb) {
      debugPrint('Notification service disabled on Web');
      return;
    }
    
    // needed this so scheduled notifications know what timezone the user is in
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    final plugin = _notificationsPlugin!;
    await plugin.initialize(initializationSettings);

    plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // I use this to pop an instant banner when the user adds a new plant
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'garden_alerts',
      'Garden Alarms',
      channelDescription:
          'Reminders to check or water your digital garden crops.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin!.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }

  // schedules a repeating watering reminder based on how often the plant needs water
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required int daysInterval,
  }) async {
    if (kIsWeb) return;
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'recurring_garden_alerts',
      'Scheduled Care Reminders',
      channelDescription: 'Automated recurring alarms for watering schedules.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin!.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(Duration(days: daysInterval)),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // used to cancel a notification when a plant is deleted so old reminders don't fire
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notificationsPlugin!.cancel(id);
  }
}
