import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/models/settings.dart';

/// 自动备份调度（V0.4）：
/// - App 切后台时备份（Android 可靠；iOS 后台限制较多，文案中明确说明）
/// - 每日固定时间备份（App 在前台时按分钟轮询触发，避免依赖后台任务权限）
class BackupScheduler extends WidgetsBindingObserver {
  BackupScheduler({
    required this.settingsReader,
    required this.onAutoBackup,
  });

  final AppSettings Function() settingsReader;
  final Future<void> Function(String reason) onAutoBackup;

  Timer? _timer;
  DateTime? _lastDailyRun;
  bool _running = false;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _timer ??= Timer.periodic(const Duration(minutes: 1), (_) => _checkDaily());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = settingsReader();
    if (state == AppLifecycleState.paused && settings.autoBackupOnBackground) {
      _run('切后台自动备份');
    }
  }

  void _checkDaily() {
    final settings = settingsReader();
    if (!settings.dailyBackupEnabled) return;
    final now = DateTime.now();
    if (now.hour != settings.dailyBackupHour ||
        now.minute != settings.dailyBackupMinute) {
      return;
    }
    final last = _lastDailyRun;
    if (last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day) {
      return;
    }
    _lastDailyRun = now;
    _run('每日定时备份');
  }

  Future<void> _run(String reason) async {
    if (_running) return;
    _running = true;
    try {
      await onAutoBackup(reason);
    } catch (_) {
      // 自动备份失败不打扰用户，日志中已有记录
    } finally {
      _running = false;
    }
  }
}