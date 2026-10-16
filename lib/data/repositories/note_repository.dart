import 'package:drift/drift.dart';

import '../../core/utils/time_utils.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/views.dart';
import '../db/database.dart';
import '../services/image_service.dart';

/// 碎碎念仓库：短信式碎片记录。
class NoteRepository {
  NoteRepository({required this.db, required this.imageService});

  final AppDatabase db;
  final ImageService imageService;

  Future<List<NoteWithTags>> list(NoteFilter filter) async {
    final rows = await db.notesDao.findNotes(
      keyword: filter.keyword,
      onlyTodo: filter.onlyTodo || filter.onlyUnfinishedTodo,
      onlyUnfinishedTodo: filter.onlyUnfinishedTodo,
      onlyTop: filter.onlyTop,
      tagIds: filter.tagIds,
    );
    // 排序：置顶优先，其余按时间倒序
    final sorted = List<BulletNote>.of(rows)
      ..sort((a, b) {
        if (a.isTop != b.isTop) return a.isTop ? -1 : 1;
        return b.createAt.compareTo(a.createAt);
      });
    return _decorate(sorted);
  }

  Future<List<NoteWithTags>> _decorate(List<BulletNote> rows) async {
    if (rows.isEmpty) return <NoteWithTags>[];
    final ids = rows.map((e) => e.id).toList();
    final relTags = await db.notesDao.tagIdsForNotes(ids);
    final allTags = await db.tagsDao.allTags();
    final tagMap = <int, Tag>{for (final tag in allTags) tag.id: tag};
    return rows
        .map(
          (note) => NoteWithTags(
            note: note,
            tags: (relTags[note.id] ?? const <int>[])
                .map((id) => tagMap[id])
                .whereType<Tag>()
                .toList(),
          ),
        )
        .toList();
  }

  Future<int> create({
    required String content,
    String? imageRelativePath,
    bool isTodo = false,
    List<int> tagIds = const <int>[],
  }) async {
    final now = TimeUtils.nowMs();
    final id = await db.notesDao.insertNote(
      BulletNotesCompanion.insert(
        content: content.trim(),
        imagePath: Value(imageRelativePath),
        isTodo: Value(isTodo),
        todoFinished: const Value(false),
        isTop: const Value(false),
        createAt: now,
        updateAt: now,
      ),
    );
    if (tagIds.isNotEmpty) {
      await db.notesDao.setNoteTags(id, tagIds);
    }
    return id;
  }

  Future<void> update({
    required int id,
    required String content,
    String? imageRelativePath,
    bool? isTodo,
    List<int>? tagIds,
    String? previousImagePath,
    bool removeImage = false,
  }) async {
    final existing = await db.notesDao.findById(id);
    if (existing == null) return;

    String? nextImage = existing.imagePath;
    if (removeImage) {
      nextImage = null;
    } else if (imageRelativePath != null) {
      nextImage = imageRelativePath;
    }

    await db.notesDao.updateNote(
      existing.copyWith(
        content: content.trim(),
        imagePath: Value(nextImage),
        isTodo: isTodo ?? existing.isTodo,
        updateAt: TimeUtils.nowMs(),
      ),
    );
    if (tagIds != null) {
      await db.notesDao.setNoteTags(id, tagIds);
    }
    // 替换 / 移除图片时清理旧文件及旧路径引用
    if ((removeImage || imageRelativePath != null) &&
        previousImagePath != null &&
        previousImagePath != nextImage) {
      await _cleanupImageIfUnreferenced(previousImagePath);
    }
  }

  Future<void> delete(int id, {bool deleteImage = true}) async {
    final note = await db.notesDao.findById(id);
    await db.notesDao.deleteNote(id);
    final path = note?.imagePath;
    if (deleteImage && path != null && path.isNotEmpty) {
      await _cleanupImageIfUnreferenced(path);
    }
  }

  Future<void> toggleTodo(int id, bool finished) =>
      db.notesDao.setTodoFinished(id, finished);

  Future<void> setTop(int id, bool top) => db.notesDao.setTop(id, top);

  Future<int> count() => db.notesDao.count();

  /// 图片可能被多条记录复用，删除前确认无引用。
  Future<void> _cleanupImageIfUnreferenced(String relativePath) async {
    final notes = await db.select(db.bulletNotes).get();
    final stillUsed = notes.any((e) => e.imagePath == relativePath);
    if (!stillUsed) {
      await imageService.deleteByRelativePath(relativePath);
    }
  }
}