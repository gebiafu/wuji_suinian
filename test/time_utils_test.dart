import 'package:flutter_test/flutter_test.dart';
import 'package:wuji_suinian/core/utils/time_utils.dart';

void main() {
  group('TimeUtils', () {
    test('格式化日期与时间', () {
      final time = DateTime(2026, 10, 17, 9, 5);
      expect(TimeUtils.formatDate(time), '2026-10-17');
      expect(TimeUtils.formatDateTime(time), '2026-10-17 09:05');
      expect(TimeUtils.formatTime(time), '09:05');
      expect(TimeUtils.compactStamp(time), '20261017_090500');
    });

    test('聊天流时间显示', () {
      final now = DateTime(2026, 10, 17, 12, 0);
      expect(
        TimeUtils.formatChatTime(DateTime(2026, 10, 17, 9, 30), now: now),
        '09:30',
      );
      expect(
        TimeUtils.formatChatTime(DateTime(2026, 10, 16, 21, 5), now: now),
        '昨天 21:05',
      );
      expect(
        TimeUtils.formatChatTime(DateTime(2026, 10, 14, 8, 0), now: now),
        '3 天前',
      );
      expect(
        TimeUtils.formatChatTime(DateTime(2026, 9, 1, 8, 0), now: now),
        '09-01',
      );
    });

    test('距离今天的天数', () {
      final now = DateTime(2026, 10, 17, 12, 0);
      final inTenDays = DateTime(2026, 10, 27, 8, 0).millisecondsSinceEpoch;
      final threeDaysAgo = DateTime(2026, 10, 14, 8, 0).millisecondsSinceEpoch;
      expect(TimeUtils.daysFromNow(inTenDays, now: now), 10);
      expect(TimeUtils.daysFromNow(threeDaysAgo, now: now), -3);
      expect(TimeUtils.daysFromNow(null, now: now), 0);
    });
  });
}