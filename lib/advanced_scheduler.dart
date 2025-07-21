import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AdvanceScheduler extends StatefulWidget {
  const AdvanceScheduler({super.key});

  @override
  State<AdvanceScheduler> createState() => _AdvanceSchedulerState();
}

class _AdvanceSchedulerState extends State<AdvanceScheduler> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String _notificationLog = 'Notification log initialized...\n';

  void _addToLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(0, 19);
      _notificationLog += '[$timestamp] $message\n';
    });
  }

  void _clearLog() {
    setState(() {
      _notificationLog = 'Log cleared...\n';
    });
  }

  Future<void> _checkNotificationStatus() async {
    final pendingCount = await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
    _addToLog('Status Check: ${pendingCount.length} pending notifications');

    // Check permissions
    final androidImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl != null) {
      final hasNotificationPermission = await androidImpl
          .areNotificationsEnabled();
      final hasExactAlarmPermission = await androidImpl
          .canScheduleExactNotifications();

      _addToLog('Notifications enabled: $hasNotificationPermission');
      _addToLog('Exact alarms enabled: $hasExactAlarmPermission');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request permissions for Android (API 33+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Request exact alarm permission for Android 12+ (API 31+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    final message = 'Notification tapped: ${response.payload}';
    debugPrint(message);
    _addToLog('TAPPED: ${response.payload}');
  }

  // Schedule immediate notification
  Future<void> _scheduleImmediateNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'immediate_channel',
          'Immediate Notifications',
          channelDescription: 'Channel for immediate notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Immediate Notification',
      'This notification appears immediately!',
      platformChannelSpecifics,
      payload: 'immediate_notification',
    );

    _addToLog('SCHEDULED: Immediate notification (ID: 0)');
  }

  // Schedule minute notifications (every minute for 60 minutes)
  Future<void> _scheduleMinuteNotifications() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'minute_channel',
          'Minute Notifications',
          channelDescription: 'Channel for minute-by-minute notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Schedule 60 notifications, one every minute
    for (int i = 1; i <= 60; i++) {
      final scheduleTime = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(minutes: i));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        200 + i, // Unique ID for each notification (201-260)
        'Minute Reminder',
        'Minute notification #$i - ${scheduleTime.hour.toString().padLeft(2, '0')}:${scheduleTime.minute.toString().padLeft(2, '0')}',
        scheduleTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'minute_notification_$i',
      );
    }

    _addToLog('SCHEDULED: 60 minute notifications (IDs: 201-260)');
    _addToLog(
      'Next notification in 1 minute, then every minute for 60 minutes',
    );
  }

  // Schedule daily notification
  Future<void> _scheduleDailyNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'daily_channel',
          'Daily Notifications',
          channelDescription: 'Channel for daily notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Schedule daily at 9:00 AM
    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Daily Reminder',
      'Your daily notification is here!',
      _nextInstanceOfTime(9, 0), // 9:00 AM
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    _addToLog(
      'SCHEDULED: Daily notification at ${_nextInstanceOfTime(9, 0)} (ID: 1)',
    );
  }

  // Schedule hourly notification
  Future<void> _scheduleHourlyNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'hourly_channel',
          'Hourly Notifications',
          channelDescription: 'Channel for hourly notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Schedule multiple hourly notifications (next 24 hours)
    for (int i = 1; i <= 24; i++) {
      final scheduleTime = tz.TZDateTime.now(tz.local).add(Duration(hours: i));
      await flutterLocalNotificationsPlugin.zonedSchedule(
        100 + i, // Unique ID for each notification
        'Hourly Reminder',
        'Hourly notification #$i',
        scheduleTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    _addToLog('SCHEDULED: 24 hourly notifications (IDs: 101-124)');
  }

  // Schedule weekly notification
  Future<void> _scheduleWeeklyNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'weekly_channel',
          'Weekly Notifications',
          channelDescription: 'Channel for weekly notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Schedule weekly on Monday at 10:00 AM
    final weeklyTime = _nextInstanceOfWeekday(DateTime.monday, 10, 0);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      2,
      'Weekly Reminder',
      'Your weekly notification is here!',
      weeklyTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    _addToLog(
      'SCHEDULED: Weekly notification on Monday at $weeklyTime (ID: 2)',
    );
  }

  // Schedule monthly notification
  Future<void> _scheduleMonthlyNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'monthly_channel',
          'Monthly Notifications',
          channelDescription: 'Channel for monthly notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Schedule monthly on the 1st at 11:00 AM
    final monthlyTime = _nextInstanceOfMonthDay(1, 11, 0);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      3,
      'Monthly Reminder',
      'Your monthly notification is here!',
      monthlyTime, // 1st day of month at 11:00 AM
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    _addToLog('SCHEDULED: Monthly notification on 1st at $monthlyTime (ID: 3)');
  }

  // Helper method to get next instance of specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Helper method to get next instance of specific weekday and time
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Helper method to get next instance of specific month day and time
  tz.TZDateTime _nextInstanceOfMonthDay(int day, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        day,
        hour,
        minute,
      );
    }
    return scheduledDate;
  }

  // Cancel all notifications
  Future<void> _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    _addToLog('CANCELLED: All notifications cleared');
  }

  // Show pending notifications
  Future<void> _showPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Pending Notifications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total: ${pendingNotifications.length}'),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: pendingNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = pendingNotifications[index];
                    return ListTile(
                      title: Text(notification.title ?? 'No Title'),
                      subtitle: Text(notification.body ?? 'No Body'),
                      trailing: Text('ID: ${notification.id}'),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Scheduler Notifications'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Local Notification Scheduler',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _scheduleImmediateNotification,
                icon: Icon(Icons.notifications),
                label: Text('Show Immediate Notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _scheduleMinuteNotifications,
                icon: Icon(Icons.timer),
                label: Text('Schedule Every Minute (60 mins)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _scheduleHourlyNotification,
                icon: Icon(Icons.access_time),
                label: Text('Schedule Hourly (Next 24hrs)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _scheduleDailyNotification,
                icon: Icon(Icons.today),
                label: Text('Schedule Daily (9:00 AM)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _scheduleWeeklyNotification,
                icon: Icon(Icons.calendar_view_week),
                label: Text('Schedule Weekly (Mon 10:00 AM)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _scheduleMonthlyNotification,
                icon: Icon(Icons.calendar_month),
                label: Text('Schedule Monthly (1st 11:00 AM)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showPendingNotifications,
                      icon: Icon(Icons.list),
                      label: Text('Show Pending'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _cancelAllNotifications,
                      icon: Icon(Icons.cancel),
                      label: Text('Cancel All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Notification Logger Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Text(
                          'Notification Schedule Log',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _notificationLog,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _clearLog,
                            icon: Icon(Icons.clear_all, size: 16),
                            label: Text(
                              'Clear Log',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.grey[700],
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _checkNotificationStatus,
                            icon: Icon(Icons.info_outline, size: 16),
                            label: Text(
                              'Status Check',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[100],
                              foregroundColor: Colors.blue[700],
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Boot Persistence Info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restart_alt, color: Colors.amber[700]),
                        SizedBox(width: 8),
                        Text(
                          'Boot Persistence Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '✅ Notifications persist after device reboot on Android 8.0+\n'
                      '⚠️ Some manufacturers may require manual permission\n'
                      '📱 Check: Settings → Apps → [Your App] → Battery → Allow background activity\n'
                      '🔔 Exact alarm permission required for Android 12+',
                      style: TextStyle(fontSize: 12, color: Colors.amber[800]),
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
}
