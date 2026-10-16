import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database;

import '../../core/paths/app_paths.dart';
import 'tables.dart';

part 'daos/items_dao.dart';
part 'daos/notes_dao.dart';
part 'daos/tags_dao.dart';
part 'daos/backup_records_dao.dart';
part 'database.g.dart';

/// 主数据库。
///
/// 图片不存 blob，只存相对路径，保证 db 小巧、备份快。
/// 时间统一存 unix 毫秒时间戳；`update_at` 用于同步冲突判断。
@DriftDatabase(
  tables: [
    Tags,
    Items,
    ItemImages,
    BulletNotes,
    BulletNoteTagRel,
    ItemTagRel,
    BackupRecords,
  ],
  daos: [ItemsDao, NotesDao, TagsDao, BackupRecordsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// 生产环境：使用 App 私有目录下的文件数据库。
  AppDatabase.openAt(AppPaths paths)
      : super(_openConnection(paths.dbFile));

  /// 测试环境：内存数据库。
  AppDatabase.memory() : super(NativeDatabase.memory(setup: _setup));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // 预留迁移入口：后续版本按 from → to 逐步升级，禁止直接清库。
          await m.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// 备份前把 WAL 内容落盘，保证直接复制 db 文件即可得到完整快照。
  Future<void> checkpoint() async {
    try {
      await customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {
      // 内存库 / 非 WAL 模式下忽略
    }
  }

  /// 全量清空（设置页「一键清空全部数据」使用）。
  Future<void> wipeAll() async {
    await transaction(() async {
      await delete(itemTagRel).go();
      await delete(bulletNoteTagRel).go();
      await delete(itemImages).go();
      await delete(items).go();
      await delete(bulletNotes).go();
      await delete(tags).go();
      await delete(backupRecords).go();
    });
    await customStatement('VACUUM');
  }

  static QueryExecutor _openConnection(File file) {
    return LazyDatabase(() async {
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      return NativeDatabase.createInBackground(file, setup: _setup);
    });
  }

  static void _setup(Database db) {
    db.execute('PRAGMA foreign_keys = ON');
    db.execute('PRAGMA journal_mode = WAL');
  }
}