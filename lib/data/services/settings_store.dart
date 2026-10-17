import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/backup_models.dart';
import '../../domain/models/settings.dart';
import '../../core/theme/app_theme.dart';

/// 设置持久化（shared_preferences）。
///
/// 注意：WebDAV 密码不在这里，走 secure_storage。
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _kThemeMode = 'theme_mode';
  static const String _kThemePreset = 'theme_preset';
  static const String _kFontScale = 'font_scale';
  static const String _kSnapshotKeep = 'snapshot_keep';
  static const String _kAutoBackupBackground = 'auto_backup_background';
  static const String _kDailyBackupEnabled = 'daily_backup_enabled';
  static const String _kDailyBackupHour = 'daily_backup_hour';
  static const String _kDailyBackupMinute = 'daily_backup_minute';
  static const String _kCompressImage = 'compress_image';
  static const String _kCompressQuality = 'compress_quality';
  static const String _kWarrantyReminder = 'warranty_reminder';
  static const String _kDeleteImageWithItem = 'delete_image_with_item';
  static const String _kWebdavConfigs = 'webdav_configs';
  static const String _kActiveWebdavConfigId = 'active_webdav_config_id';

  AppSettings read() {
    return AppSettings(
      themeMode: _readThemeMode(),
      themePreset: AppThemePreset.fromValue(_prefs.getString(_kThemePreset)),
      fontScale: _prefs.getDouble(_kFontScale) ?? 1.0,
      snapshotKeep: _prefs.getInt(_kSnapshotKeep) ?? 5,
      autoBackupOnBackground:
          _prefs.getBool(_kAutoBackupBackground) ?? false,
      dailyBackupEnabled: _prefs.getBool(_kDailyBackupEnabled) ?? false,
      dailyBackupHour: _prefs.getInt(_kDailyBackupHour) ?? 22,
      dailyBackupMinute: _prefs.getInt(_kDailyBackupMinute) ?? 0,
      compressImage: _prefs.getBool(_kCompressImage) ?? true,
      compressQuality: _prefs.getInt(_kCompressQuality) ?? 80,
      warrantyReminderEnabled: _prefs.getBool(_kWarrantyReminder) ?? true,
      deleteImageWithItem: _prefs.getBool(_kDeleteImageWithItem) ?? true,
      activeWebdavConfigId: _prefs.getString(_kActiveWebdavConfigId),
    );
  }

  Future<void> write(AppSettings settings) async {
    await _prefs.setString(_kThemeMode, settings.themeMode.name);
    await _prefs.setString(_kThemePreset, settings.themePreset.value);
    await _prefs.setDouble(_kFontScale, settings.fontScale);
    await _prefs.setInt(_kSnapshotKeep, settings.snapshotKeep);
    await _prefs.setBool(_kAutoBackupBackground, settings.autoBackupOnBackground);
    await _prefs.setBool(_kDailyBackupEnabled, settings.dailyBackupEnabled);
    await _prefs.setInt(_kDailyBackupHour, settings.dailyBackupHour);
    await _prefs.setInt(_kDailyBackupMinute, settings.dailyBackupMinute);
    await _prefs.setBool(_kCompressImage, settings.compressImage);
    await _prefs.setInt(_kCompressQuality, settings.compressQuality);
    await _prefs.setBool(_kWarrantyReminder, settings.warrantyReminderEnabled);
    await _prefs.setBool(_kDeleteImageWithItem, settings.deleteImageWithItem);
    final activeId = settings.activeWebdavConfigId;
    if (activeId == null) {
      await _prefs.remove(_kActiveWebdavConfigId);
    } else {
      await _prefs.setString(_kActiveWebdavConfigId, activeId);
    }
  }

  ThemeMode _readThemeMode() {
    final raw = _prefs.getString(_kThemeMode);
    return ThemeMode.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  /// WebDAV 配置列表（不含密码）。
  List<WebdavConfig> readWebdavConfigs() {
    final raw = _prefs.getString(_kWebdavConfigs);
    if (raw == null || raw.isEmpty) return <WebdavConfig>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => WebdavConfig.fromJson(
                Map<String, Object?>.from(e as Map<dynamic, dynamic>),
              ))
          .toList();
    } catch (_) {
      return <WebdavConfig>[];
    }
  }

  Future<void> writeWebdavConfigs(List<WebdavConfig> configs) async {
    final payload = jsonEncode(configs.map((e) => e.toJson()).toList());
    await _prefs.setString(_kWebdavConfigs, payload);
  }
}