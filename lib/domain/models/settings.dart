import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// App 设置（本地 shared_preferences 存储）。
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.themePreset = AppThemePreset.defaultTheme,
    this.fontScale = 1.0,
    this.snapshotKeep = 5,
    this.autoBackupOnBackground = false,
    this.dailyBackupEnabled = false,
    this.dailyBackupHour = 22,
    this.dailyBackupMinute = 0,
    this.compressImage = true,
    this.compressQuality = 80,
    this.warrantyReminderEnabled = true,
    this.deleteImageWithItem = true,
    this.activeWebdavConfigId,
  });

  final ThemeMode themeMode;

  /// 配色预设（樱花粉 / 天空蓝 / 毛玻璃等，与明暗模式正交）
  final AppThemePreset themePreset;
  final double fontScale;

  /// 远端保留快照份数：3 / 5 / 10
  final int snapshotKeep;

  /// App 切后台时自动备份
  final bool autoBackupOnBackground;

  /// 每日固定时间备份
  final bool dailyBackupEnabled;
  final int dailyBackupHour;
  final int dailyBackupMinute;

  /// 拍照自动压缩（推荐，否则 WebDAV 同步很慢）
  final bool compressImage;
  final int compressQuality;

  final bool warrantyReminderEnabled;

  /// 删除物品时默认是否同时删除本地原图
  final bool deleteImageWithItem;

  final String? activeWebdavConfigId;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppThemePreset? themePreset,
    double? fontScale,
    int? snapshotKeep,
    bool? autoBackupOnBackground,
    bool? dailyBackupEnabled,
    int? dailyBackupHour,
    int? dailyBackupMinute,
    bool? compressImage,
    int? compressQuality,
    bool? warrantyReminderEnabled,
    bool? deleteImageWithItem,
    String? activeWebdavConfigId,
    bool clearActiveWebdavConfig = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      fontScale: fontScale ?? this.fontScale,
      snapshotKeep: snapshotKeep ?? this.snapshotKeep,
      autoBackupOnBackground:
          autoBackupOnBackground ?? this.autoBackupOnBackground,
      dailyBackupEnabled: dailyBackupEnabled ?? this.dailyBackupEnabled,
      dailyBackupHour: dailyBackupHour ?? this.dailyBackupHour,
      dailyBackupMinute: dailyBackupMinute ?? this.dailyBackupMinute,
      compressImage: compressImage ?? this.compressImage,
      compressQuality: compressQuality ?? this.compressQuality,
      warrantyReminderEnabled:
          warrantyReminderEnabled ?? this.warrantyReminderEnabled,
      deleteImageWithItem: deleteImageWithItem ?? this.deleteImageWithItem,
      activeWebdavConfigId: clearActiveWebdavConfig
          ? null
          : (activeWebdavConfigId ?? this.activeWebdavConfigId),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.themePreset == themePreset &&
      other.fontScale == fontScale &&
      other.snapshotKeep == snapshotKeep &&
      other.autoBackupOnBackground == autoBackupOnBackground &&
      other.dailyBackupEnabled == dailyBackupEnabled &&
      other.dailyBackupHour == dailyBackupHour &&
      other.dailyBackupMinute == dailyBackupMinute &&
      other.compressImage == compressImage &&
      other.compressQuality == compressQuality &&
      other.warrantyReminderEnabled == warrantyReminderEnabled &&
      other.deleteImageWithItem == deleteImageWithItem &&
      other.activeWebdavConfigId == activeWebdavConfigId;

  @override
  int get hashCode => Object.hash(
        themeMode,
        themePreset,
        fontScale,
        snapshotKeep,
        autoBackupOnBackground,
        dailyBackupEnabled,
        dailyBackupHour,
        dailyBackupMinute,
        compressImage,
        compressQuality,
        warrantyReminderEnabled,
        deleteImageWithItem,
        activeWebdavConfigId,
      );
}