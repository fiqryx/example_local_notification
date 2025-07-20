import 'dart:math';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example Local Notifications',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: NotificationTestApp(),
    );
  }
}

class NotificationTestApp extends StatefulWidget {
  const NotificationTestApp({super.key});

  @override
  State<NotificationTestApp> createState() => _NotificationTestAppState();
}

class _NotificationTestAppState extends State<NotificationTestApp> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  Future<void> configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> initializeNotifications() async {
    // Configure timezone
    await configureLocalTimeZone();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combine initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Initialize plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification clicked with payload: ${response.payload}');
        _showDialog('Notification Clicked', 'Payload: ${response.payload}');
      },
    );

    // Request permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showSimpleNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'simple_channel_id',
          'Simple Notifications',
          channelDescription: 'This channel is used for simple notifications.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      Random().nextInt(1000), // Unique ID
      'Simple Notification',
      'This is a simple notification message!',
      notificationDetails,
      payload: 'simple_notification_payload',
    );
  }

  Future<void> showBigTextNotification() async {
    const AndroidNotificationDetails
    androidNotificationDetails = AndroidNotificationDetails(
      'big_text_channel_id',
      'Big Text Notifications',
      channelDescription: 'This channel is used for big text notifications.',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        'This is a very long notification message that will be expanded when the user taps on it. '
        'It can contain multiple lines of text and provides more detailed information to the user. '
        'This is useful for displaying detailed messages or instructions.',
      ),
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      Random().nextInt(1000),
      'Big Text Notification',
      'This notification has expanded content...',
      notificationDetails,
      payload: 'big_text_notification_payload',
    );
  }

  Future<void> showProgressNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'progress_channel_id',
          'Progress Notifications',
          channelDescription:
              'This channel is used for progress notifications.',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: 50,
          onlyAlertOnce: true,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      999, // Fixed ID for progress updates
      'Download Progress',
      '50% completed',
      notificationDetails,
      payload: 'progress_notification_payload',
    );
  }

  Future<void> showScheduledNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'scheduled_channel_id',
          'Scheduled Notifications',
          channelDescription:
              'This channel is used for scheduled notifications.',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      Random().nextInt(1000),
      'Scheduled Notification',
      'This notification was scheduled 5 seconds ago!',
      tz.TZDateTime.now(tz.local).add(Duration(seconds: 5)),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'scheduled_notification_payload',
    );

    _showSnackBar('Notification scheduled for 5 seconds from now');
  }

  Future<void> showActionNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'action_channel_id',
          'Action Notifications',
          channelDescription: 'This channel is used for action notifications.',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'action_1',
              'Accept',
              icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            ),
            AndroidNotificationAction(
              'action_2',
              'Decline',
              cancelNotification: true,
            ),
          ],
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(categoryIdentifier: 'actionCategory');

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      Random().nextInt(1000),
      'Action Notification',
      'This notification has action buttons',
      notificationDetails,
      payload: 'action_notification_payload',
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    _showSnackBar('All notifications cancelled');
  }

  Future<void> showPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    if (pendingNotifications.isEmpty) {
      _showDialog('Pending Notifications', 'No pending notifications found');
    } else {
      String message =
          'Found ${pendingNotifications.length} pending notification(s):\n\n';
      for (var notification in pendingNotifications) {
        message += '• ID: ${notification.id}\n';
        message += '  Title: ${notification.title}\n';
        message += '  Body: ${notification.body}\n\n';
      }
      _showDialog('Pending Notifications', message);
    }
  }

  Future<void> testScheduledNotificationLong() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'test_scheduled_channel',
          'Test Scheduled Notifications',
          channelDescription: 'Testing scheduled notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Test scheduled notification',
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    final tz.TZDateTime scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: 1));

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        9999,
        'Test Long Schedule',
        'This notification was scheduled for 1 minute! Time: ${DateTime.now().toString()}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'test_long_scheduled_payload',
      );

      _showSnackBar('Notification scheduled for 1 minute from now');
    } catch (e) {
      debugPrint('Error scheduling long notification: $e');
      _showSnackBar('Error scheduling notification: $e');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example Local Notifications'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 48,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Test Different Notification Types',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the buttons below to test various notification features',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildNotificationButton(
                      'Simple Notification',
                      'Show a basic notification',
                      Icons.notification_important,
                      Colors.green,
                      showSimpleNotification,
                    ),
                    SizedBox(height: 12),
                    _buildNotificationButton(
                      'Big Text Notification',
                      'Show expandable text notification',
                      Icons.text_fields,
                      Colors.orange,
                      showBigTextNotification,
                    ),
                    SizedBox(height: 12),
                    _buildNotificationButton(
                      'Progress Notification',
                      'Show notification with progress bar',
                      Icons.trending_up,
                      Colors.purple,
                      showProgressNotification,
                    ),
                    SizedBox(height: 12),
                    _buildNotificationButton(
                      'Scheduled Notification',
                      'Schedule notification for 5 seconds',
                      Icons.schedule,
                      Colors.teal,
                      showScheduledNotification,
                    ),
                    SizedBox(height: 12),
                    _buildNotificationButton(
                      'Long Schedule (1 min)',
                      'Schedule notification for 1 minute',
                      Icons.access_time,
                      Colors.cyan,
                      testScheduledNotificationLong,
                    ),
                    SizedBox(height: 12),
                    _buildNotificationButton(
                      'Action Notification',
                      'Show notification with action buttons',
                      Icons.touch_app,
                      Colors.indigo,
                      showActionNotification,
                    ),
                    SizedBox(height: 20),
                    _buildNotificationButton(
                      'Check Pending',
                      'Show pending scheduled notifications',
                      Icons.pending_actions,
                      Colors.amber,
                      showPendingNotifications,
                    ),
                    SizedBox(height: 12),
                    _buildNotificationButton(
                      'Cancel All Notifications',
                      'Remove all active notifications',
                      Icons.clear_all,
                      Colors.red,
                      cancelAllNotifications,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
      ),
    );
  }
}
