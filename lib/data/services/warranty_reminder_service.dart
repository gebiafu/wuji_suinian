import '../../core/utils/time_utils.dart';
import '../../domain/models/settings.dart';
import 'notification_service.dart';
import '../repositories/item_repository.dart';

/// 质保到期提醒：把「即将到期」的物品排成本地通知。
class WarrantyReminderService {
  WarrantyReminderService({
    required this.items,
    required this.notifications,
    required this.settingsReader,
  });

  final ItemRepository items;
  final NotificationService notifications;
  final AppSettings Function() settingsReader;

  static const int _remindBeforeDays = 7;
  static const int _remindHour = 9;

  /// 重新排期；返回排入的提醒条数。
  Future<int> reschedule({int lookAheadDays = 30}) async {
    if (!settingsReader().warrantyReminderEnabled) {
      await notifications.cancelAll();
      return 0;
    }
    final watchList = await items.warrantyWatchList(days: lookAheadDays);
    final now = DateTime.now();
    final reminders = <WarrantyReminder>[];
    for (final entry in watchList) {
      final endMs = entry.item.warrantyEndDate;
      final end = TimeUtils.toDateTime(endMs);
      if (end == null) continue;
      var fireAt = DateTime(
        end.year,
        end.month,
        end.day,
        _remindHour,
      ).subtract(const Duration(days: _remindBeforeDays));
      if (fireAt.isBefore(now)) {
        // 提醒时间已过但质保仍在有效期内 → 立即提醒
        fireAt = now.add(const Duration(minutes: 1));
      }
      final days = TimeUtils.daysFromNow(endMs, now: now);
      reminders.add(
        WarrantyReminder(
          id: entry.item.id,
          title: '质保提醒：${entry.item.name}',
          body: days >= 0 ? '质保还有 $days 天到期，注意留存凭证' : '质保已过期 $days 天',
          fireAt: fireAt,
        ),
      );
    }
    await notifications.scheduleWarrantyReminders(reminders);
    return reminders.length;
  }
}