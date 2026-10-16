import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 质保提醒任务
class WarrantyReminder {
  const WarrantyReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
  });

  final int id;
  final String title;
  final String body;
  final DateTime fireAt;
}

abstract class NotificationService {
  Future<void> init();

  Future<void> scheduleWarrantyReminders(List<WarrantyReminder> reminders);

  Future<void> showNow(String title, String body);

  Future<void> cancelAll();
}

/// 无操作实现：桌面 / 测试 / 插件不可用时降级。
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleWarrantyReminders(List<WarrantyReminder> reminders) async {}

  @override
  Future<void> showNow(String title, String body) async {}

  @override
  Future<void> cancelAll() async {}
}

/// flutter_local_notifications 实现（质保到期本地通知）。
class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const String _channelId = 'warranty_reminder';
  static const String _channelName = '质保提醒';
  static const int _baseId = 10000;

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      tz_data.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      _ready = true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('通知初始化失败（平台不支持时忽略）: $error');
      }
      _ready = false;
    }
  }

  @override
  Future<void> scheduleWarrantyReminders(List<WarrantyReminder> reminders) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      for (final reminder in reminders) {
        final scheduled = tz.TZDateTime.from(reminder.fireAt, tz.local);
        if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) continue;
        await _plugin.zonedSchedule(
          id: _baseId + reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: scheduled,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: '物品质保即将到期提醒',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('质保提醒调度失败: $error');
      }
    }
  }

  @override
  Future<void> showNow(String title, String body) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: 1,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(_channelId, _channelName),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // ignore
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }
}