import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _maxStoredNotifications = 12;
  final List<Map<String, dynamic>> _history = [];

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await _setupCheckupReminders();
    await _setupWaterReminders();
  }

  Future<void> _setupCheckupReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final checkupDate = data['checkupDate']?.toDate();
    if (checkupDate == null) return;

    // Calculate days until checkup (using ceil to count full days)
    final now = DateTime.now();
    final daysUntilCheckup = checkupDate.difference(now).inDays + 1;
    //final daysUntilCheckup = (checkupDate.difference(now).inHours / 24).ceil();

    if (daysUntilCheckup > 0) {
      if (daysUntilCheckup == 1) {
        await _scheduleCheckupReminder(_getNext8AM(now),
            'Your checkup is tomorrow at ${DateFormat('h:mm a').format(checkupDate)}');
      } else {
        await _scheduleCheckupReminder(_getNext8AM(now),
            'Your checkup is in $daysUntilCheckup days (${DateFormat('MMM dd').format(checkupDate)})');
      }
    }
  }

  Future<void> _scheduleCheckupReminder(
      DateTime reminderDate, String message) async {
    if (reminderDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 900 + reminderDate.day, // Unique ID based on day
        title: 'Checkup Reminder',
        body: message,
        scheduledDateTime: reminderDate,
        storeInHistory: true,
      );
    }
  }

  DateTime _getNext8AM(DateTime date) {
    var next8AM = DateTime(date.year, date.month, date.day, 21, 50);
    if (next8AM.isBefore(DateTime.now())) {
      next8AM = next8AM.add(const Duration(days: 1));
    }
    return next8AM;
  }

  Future<void> _setupWaterReminders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final waterIntake = (data['waterIntakeGoal'] ?? 2.0).toDouble();
    await _scheduleDailyWaterReminders(waterIntake);
  }

  Future<void> _scheduleDailyWaterReminders(double waterIntakeLiters) async {
    // Cancel existing water reminders
    for (int i = 100; i < 200; i++) {
      await cancelNotification(i);
    }

    final remindersCount = (waterIntakeLiters / 0.25).ceil();
    if (remindersCount <= 0) return;

    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day, 8, 0);
    final endTime = DateTime(now.year, now.month, now.day, 22, 0);
    final totalMinutes = endTime.difference(startTime).inMinutes;
    final interval = totalMinutes ~/ remindersCount;

    for (int i = 0; i < remindersCount; i++) {
      final reminderTime = startTime.add(Duration(minutes: interval * i));
      if (reminderTime.isAfter(now)) {
        await scheduleNotification(
          id: 100 + i,
          title: 'Stay Hydrated',
          body: 'Time to drink a glass of water!',
          scheduledDateTime: reminderTime,
          storeInHistory: false,
        );
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    bool storeInHistory = true,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pregnancy_reminders_channel',
      'Pregnancy Reminders',
      channelDescription: 'Channel for pregnancy-related reminders',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    if (storeInHistory) {
      await _addToHistory(id, title, body, scheduledDateTime);
    }
  }

  Future<void> _addToHistory(
      int id, String title, String body, DateTime time) async {
    // First check if a similar notification already exists
    final existing = await _firestore
        .collection('notification_history')
        .where('title', isEqualTo: title)
        .where('body', isEqualTo: body)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await _firestore.collection('notification_history').add({
        'id': id,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
        'type': 'Scheduled',
      });
    }

    // Clean up old notifications (keep only latest 12)
    final snapshot = await _firestore
        .collection('notification_history')
        .orderBy('time', descending: true)
        .get();

    if (snapshot.docs.length > 12) {
      final docsToDelete = snapshot.docs.sublist(12);
      for (final doc in docsToDelete) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    _removeFromHistory(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    _history.clear();
  }

  void _removeFromHistory(int id) {
    _history.removeWhere((item) => item['id'] == id);
  }

  List<Map<String, dynamic>> getHistory() {
    return List.from(_history.reversed);
  }

  Stream<QuerySnapshot> getHistoryStream() {
    return _firestore
        .collection('notification_history')
        .orderBy('time', descending: true)
        .limit(_maxStoredNotifications)
        .snapshots();
  }
}
