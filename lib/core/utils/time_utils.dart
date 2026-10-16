/// 时间工具：全库统一使用 unix 毫秒时间戳存储，方便跨平台与同步比较。
class TimeUtils {
  TimeUtils._();

  static int nowMs() => DateTime.now().millisecondsSinceEpoch;

  static DateTime? toDateTime(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);

  static int? toMs(DateTime? time) => time?.millisecondsSinceEpoch;

  static String _p2(int v) => v.toString().padLeft(2, '0');

  /// 2026-10-17
  static String formatDate(DateTime? time) {
    if (time == null) return '';
    return '${time.year}-${_p2(time.month)}-${_p2(time.day)}';
  }

  /// 2026-10-17 09:30
  static String formatDateTime(DateTime? time) {
    if (time == null) return '';
    return '${formatDate(time)} ${_p2(time.hour)}:${_p2(time.minute)}';
  }

  /// 09:30
  static String formatTime(DateTime? time) {
    if (time == null) return '';
    return '${_p2(time.hour)}:${_p2(time.minute)}';
  }

  /// 20261017_093000，用于快照目录名与冲突文件名
  static String compactStamp(DateTime time) {
    return '${time.year}${_p2(time.month)}${_p2(time.day)}'
        '_${_p2(time.hour)}${_p2(time.minute)}${_p2(time.second)}';
  }

  /// 聊天流友好时间：今天显示时间，昨天显示"昨天 HH:mm"，更早显示日期
  static String formatChatTime(DateTime? time, {DateTime? now}) {
    if (time == null) return '';
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final target = DateTime(time.year, time.month, time.day);
    final diffDays = today.difference(target).inDays;
    if (diffDays == 0) return formatTime(time);
    if (diffDays == 1) return '昨天 ${formatTime(time)}';
    if (diffDays < 7) return '$diffDays 天前';
    if (time.year == current.year) {
      return '${_p2(time.month)}-${_p2(time.day)}';
    }
    return formatDate(time);
  }

  /// 距离今天的天数（未来为正）
  static int daysFromNow(int? ms, {DateTime? now}) {
    if (ms == null) return 0;
    final current = now ?? DateTime.now();
    final a = DateTime(current.year, current.month, current.day);
    final t = TimeUtils.toDateTime(ms)!;
    final b = DateTime(t.year, t.month, t.day);
    return b.difference(a).inDays;
  }
}