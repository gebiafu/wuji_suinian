import '../../domain/models/views.dart';
import '../db/database.dart';

/// 标签仓库：物品与碎念共用同一标签池。
class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;

  Future<List<Tag>> all() => _db.tagsDao.allTags();

  Future<int> ensure(String name) => _db.tagsDao.ensureTag(name);

  Future<List<int>> ensureAll(Iterable<String> names) async {
    final ids = <int>[];
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      ids.add(await _db.tagsDao.ensureTag(trimmed));
    }
    return ids;
  }

  Future<void> rename(int id, String name) => _db.tagsDao.renameTag(id, name);

  Future<void> delete(int id) => _db.tagsDao.deleteTag(id);

  Future<Map<int, int>> usageCounts() => _db.tagsDao.usageCounts();

  /// 分类候选（供新增物品时选择）
  Future<List<Tag>> categories() async {
    final tags = await _db.tagsDao.allTags();
    final counts = await _db.tagsDao.usageCounts();
    final used = tags.where((t) => counts[t.id] != null).toList();
    used.sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    return used;
  }

  /// 标签使用统计（标签管理页）
  Future<List<TagUsage>> usage() async {
    final tags = await _db.tagsDao.allTags();
    final counts = await _db.tagsDao.usageCounts();
    return tags
        .map((tag) => TagUsage(tag: tag, count: counts[tag.id] ?? 0))
        .toList();
  }
}