import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/paths/app_paths.dart';
import '../core/theme/app_theme.dart';
import '../data/db/database.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/search_repository.dart';
import '../data/repositories/tag_repository.dart';
import '../data/services/archive_service.dart';
import '../data/services/backup_service.dart';
import '../data/services/image_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/permission_service.dart';
import '../data/services/secure_store.dart';
import '../data/services/settings_store.dart';
import '../data/services/storage_service.dart';
import '../data/services/warranty_reminder_service.dart';
import '../data/services/webdav/remote_store.dart';
import '../data/services/webdav/webdav_client.dart';
import '../domain/models/backup_models.dart';
import '../domain/models/settings.dart';
import '../domain/models/views.dart';

// ---------------------------------------------------------------- 基础设施

/// 由 main() 注入实际目录。
final appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('appPathsProvider 必须在 main 中 override'),
);

/// 由 main() 注入（shared_preferences 实例）。
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsStoreProvider 必须在 main 中 override'),
);

/// 由 main() 注入（secure_storage）。测试可替换为 MemorySecureStore。
final secureStoreProvider = Provider<SecureStore>(
  (ref) => MemorySecureStore(),
);

/// 通知服务（平台不支持时自动降级，测试可替换为 NoopNotificationService）。
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => const NoopNotificationService(),
);

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => const PermissionService(),
);

/// 数据库：恢复 / 导入后通过 `reload()` 重建连接，依赖它的 provider 会自动刷新。
final databaseProvider = NotifierProvider<DatabaseNotifier, AppDatabase>(
  DatabaseNotifier.new,
);

class DatabaseNotifier extends Notifier<AppDatabase> {
  @override
  AppDatabase build() {
    final paths = ref.watch(appPathsProvider);
    final db = AppDatabase.openAt(paths);
    ref.onDispose(db.close);
    return db;
  }

  /// 覆盖本地文件（恢复 / 导入）后重建连接。
  Future<void> reload() async {
    final previous = state;
    state = AppDatabase.openAt(ref.read(appPathsProvider));
    await previous.close();
  }
}

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService(
    paths: ref.watch(appPathsProvider),
    permissions: ref.watch(permissionServiceProvider),
    settingsReader: () => ref.read(settingsProvider),
  );
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(
    paths: ref.watch(appPathsProvider),
    dbProvider: () => ref.read(databaseProvider),
    imageService: ref.watch(imageServiceProvider),
  );
});

final archiveServiceProvider = Provider<ArchiveService>(
  (ref) => ArchiveService(paths: ref.watch(appPathsProvider)),
);

// ------------------------------------------------------------------ 设置

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  late SettingsStore _store;

  @override
  AppSettings build() {
    _store = ref.watch(settingsStoreProvider);
    return _store.read();
  }

  Future<void> update(AppSettings next) async {
    state = next;
    await _store.write(next);
  }

  Future<void> patch(AppSettings Function(AppSettings current) transform) =>
      update(transform(state));

  Future<void> setThemeMode(ThemeMode mode) =>
      patch((s) => s.copyWith(themeMode: mode));

  Future<void> setThemePreset(AppThemePreset preset) =>
      patch((s) => s.copyWith(themePreset: preset));

  Future<void> setFontScale(double scale) =>
      patch((s) => s.copyWith(fontScale: scale));

  Future<void> setSnapshotKeep(int keep) =>
      patch((s) => s.copyWith(snapshotKeep: keep));

  Future<void> setCompress({required bool enabled, int? quality}) => patch(
        (s) => s.copyWith(
          compressImage: enabled,
          compressQuality: quality ?? s.compressQuality,
        ),
      );

  Future<void> setAutoBackupOnBackground(bool enabled) =>
      patch((s) => s.copyWith(autoBackupOnBackground: enabled));

  Future<void> setDailyBackup({required bool enabled, int? hour, int? minute}) =>
      patch(
        (s) => s.copyWith(
          dailyBackupEnabled: enabled,
          dailyBackupHour: hour ?? s.dailyBackupHour,
          dailyBackupMinute: minute ?? s.dailyBackupMinute,
        ),
      );

  Future<void> setWarrantyReminder(bool enabled) =>
      patch((s) => s.copyWith(warrantyReminderEnabled: enabled));

  Future<void> setDeleteImageWithItem(bool enabled) =>
      patch((s) => s.copyWith(deleteImageWithItem: enabled));
}

// ------------------------------------------------------------- WebDAV 配置

final webdavConfigsProvider =
    NotifierProvider<WebdavConfigsNotifier, List<WebdavConfig>>(
  WebdavConfigsNotifier.new,
);

class WebdavConfigsNotifier extends Notifier<List<WebdavConfig>> {
  @override
  List<WebdavConfig> build() {
    final store = ref.watch(settingsStoreProvider);
    ref.watch(settingsProvider);
    return store.readWebdavConfigs();
  }

  SettingsStore get _store => ref.read(settingsStoreProvider);

  SecureStore get _secure => ref.read(secureStoreProvider);

  /// 新增 / 更新配置；密码写入加密存储，不落 sqlite。
  Future<WebdavConfig> save(WebdavConfig config) async {
    final id = config.id.isEmpty
        ? 'dav_${DateTime.now().millisecondsSinceEpoch}'
        : config.id;
    final saved = config.copyWith(id: id);
    final next = List<WebdavConfig>.of(state);
    final index = next.indexWhere((e) => e.id == id);
    final persisted = saved.copyWith(password: '');
    if (index >= 0) {
      next[index] = persisted;
    } else {
      next.add(persisted);
    }
    await _store.writeWebdavConfigs(next);
    if (saved.password.isNotEmpty) {
      await _secure.write(SecureStore.passwordKey(id), saved.password);
    }
    if (ref.read(settingsProvider).activeWebdavConfigId == null ||
        ref.read(settingsProvider).activeWebdavConfigId!.isEmpty) {
      await ref.read(settingsProvider.notifier).update(
            ref.read(settingsProvider).copyWith(activeWebdavConfigId: id),
          );
    }
    state = next;
    return persisted;
  }

  Future<void> remove(String id) async {
    final next = state.where((e) => e.id != id).toList();
    await _store.writeWebdavConfigs(next);
    await _secure.delete(SecureStore.passwordKey(id));
    if (ref.read(settingsProvider).activeWebdavConfigId == id) {
      await ref.read(settingsProvider.notifier).update(
            ref
                .read(settingsProvider)
                .copyWith(clearActiveWebdavConfig: true),
          );
    }
    state = next;
  }

  Future<void> setActive(String? id) async {
    await ref.read(settingsProvider.notifier).update(
          id == null
              ? ref.read(settingsProvider).copyWith(clearActiveWebdavConfig: true)
              : ref.read(settingsProvider).copyWith(activeWebdavConfigId: id),
        );
    state = List<WebdavConfig>.of(state);
  }

  /// 读取带密码的配置（仅运行时使用）。
  Future<WebdavConfig?> activeConfigWithPassword() async {
    final activeId = ref.read(settingsProvider).activeWebdavConfigId;
    if (activeId == null) return null;
    WebdavConfig? config;
    for (final candidate in state) {
      if (candidate.id == activeId) config = candidate;
    }
    if (config == null) return null;
    final password = await _secure.read(SecureStore.passwordKey(activeId)) ?? '';
    return config.copyWith(password: password);
  }
}

final activeWebdavConfigProvider = Provider<WebdavConfig?>((ref) {
  final configs = ref.watch(webdavConfigsProvider);
  final activeId = ref.watch(settingsProvider).activeWebdavConfigId;
  if (activeId == null) return null;
  for (final config in configs) {
    if (config.id == activeId) return config;
  }
  return null;
});

/// 远端存储工厂：所有 WebDAV 操作都通过它创建客户端。
final remoteStoreFactoryProvider = Provider<Future<RemoteStore> Function()>((ref) {
  return () async {
    final config =
        await ref.read(webdavConfigsProvider.notifier).activeConfigWithPassword();
    if (config == null || config.serverUrl.trim().isEmpty) {
      throw StateError('尚未配置 WebDAV，请先到「设置 → 备份与同步」中填写');
    }
    final client = WebdavClient(
      baseUrl: joinRemoteUrl(config.serverUrl, config.remoteDir),
      username: config.username,
      password: config.password,
    );
    return WebdavRemoteStore(client);
  };
});

String joinRemoteUrl(String serverUrl, String remoteDir) {
  final base = serverUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final dir = remoteDir.trim().replaceAll(RegExp(r'^/+|/+$'), '');
  if (dir.isEmpty) return base;
  return '$base/$dir';
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    paths: ref.watch(appPathsProvider),
    dbProvider: () => ref.read(databaseProvider),
    remoteStoreFactory: ref.watch(remoteStoreFactoryProvider),
    settingsReader: () => ref.read(settingsProvider),
    logger: (report) async {
      try {
        await ref.read(databaseProvider).backupRecordsDao.add(
              type: report.type,
              status: report.success ? 'success' : 'failed',
              message: report.message,
              size: report.totalBytes,
            );
      } catch (_) {
        // 日志写入失败不应影响主流程
      }
    },
  );
});

// ------------------------------------------------------------------ 仓库

final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => TagRepository(ref.watch(databaseProvider)),
);

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(
    db: ref.watch(databaseProvider),
    imageService: ref.watch(imageServiceProvider),
  ),
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(
    db: ref.watch(databaseProvider),
    imageService: ref.watch(imageServiceProvider),
  ),
);

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(
    items: ref.watch(itemRepositoryProvider),
    notes: ref.watch(noteRepositoryProvider),
  ),
);

// --------------------------------------------------------------- 通用数据

/// 全部标签（标签变更后 invalidate 即可刷新）
final tagsProvider = FutureProvider<List<Tag>>(
  (ref) => ref.watch(tagRepositoryProvider).all(),
);

final tagUsageProvider = FutureProvider<List<TagUsage>>(
  (ref) => ref.watch(tagRepositoryProvider).usage(),
);

final locationsProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(itemRepositoryProvider).distinctLocations(),
);

/// 质保提醒：物品变更 / 设置变更后重新排期
final warrantyReminderServiceProvider = Provider<WarrantyReminderService>((ref) {
  return WarrantyReminderService(
    items: ref.watch(itemRepositoryProvider),
    notifications: ref.watch(notificationServiceProvider),
    settingsReader: () => ref.read(settingsProvider),
  );
});