part of '../database.dart';

/// 碎碎念数据访问。
@DriftAccessor(tables: [BulletNotes, BulletNoteTagRel])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  Future<List<BulletNote>> findNotes({
    String? keyword,
    bool onlyTodo = false,
    bool onlyUnfinishedTodo = false,
    bool onlyTop = false,
    List<int>? tagIds,
  }) async {
    final query = select(bulletNotes);
    if (onlyTodo) {
      query.where((t) => t.isTodo.equals(true));
    }
    if (onlyUnfinishedTodo) {
      query.where((t) => t.isTodo.equals(true) & t.todoFinished.equals(false));
    }
    if (onlyTop) {
      query.where((t) => t.isTop.equals(true));
    }

    final kw = keyword?.trim() ?? '';
    if (kw.isNotEmpty) {
      query.where((t) => t.content.lower().like('%${kw.toLowerCase()}%'));
    }

    if (tagIds != null && tagIds.isNotEmpty) {
      final ids = await noteIdsForTags(tagIds);
      if (ids.isEmpty) return <BulletNote>[];
      query.where((t) => t.id.isIn(ids));
    }

    return query.get();
  }

  Future<BulletNote?> findById(int id) =>
      (select(bulletNotes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> count() async => (await select(bulletNotes).get()).length;

  Future<int> insertNote(BulletNotesCompanion companion) =>
      into(bulletNotes).insert(companion);

  Future<bool> updateNote(BulletNote row) => update(bulletNotes).replace(row);

  Future<int> deleteNote(int id) =>
      (delete(bulletNotes)..where((t) => t.id.equals(id))).go();

  Future<void> setTodoFinished(int id, bool finished) async {
    await (update(bulletNotes)..where((t) => t.id.equals(id))).write(
      BulletNotesCompanion(
        todoFinished: Value(finished),
        updateAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setTop(int id, bool top) async {
    await (update(bulletNotes)..where((t) => t.id.equals(id))).write(
      BulletNotesCompanion(
        isTop: Value(top),
        updateAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<List<int>> tagIdsForNote(int noteId) async {
    final rows = await (select(bulletNoteTagRel)
          ..where((t) => t.noteId.equals(noteId)))
        .get();
    return rows.map((r) => r.tagId).toList();
  }

  Future<Map<int, List<int>>> tagIdsForNotes(List<int> noteIds) async {
    if (noteIds.isEmpty) return <int, List<int>>{};
    final rows = await (select(bulletNoteTagRel)
          ..where((t) => t.noteId.isIn(noteIds)))
        .get();
    final map = <int, List<int>>{};
    for (final row in rows) {
      map.putIfAbsent(row.noteId, () => <int>[]).add(row.tagId);
    }
    return map;
  }

  Future<void> setNoteTags(int noteId, List<int> tagIds) async {
    await transaction(() async {
      await (delete(bulletNoteTagRel)..where((t) => t.noteId.equals(noteId)))
          .go();
      for (final tagId in tagIds.toSet()) {
        await into(bulletNoteTagRel).insert(
          BulletNoteTagRelData(noteId: noteId, tagId: tagId),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<List<int>> noteIdsForTags(List<int> tagIds) async {
    if (tagIds.isEmpty) return <int>[];
    final rows = await (select(bulletNoteTagRel)
          ..where((t) => t.tagId.isIn(tagIds)))
        .get();
    return rows.map((r) => r.noteId).toSet().toList();
  }
}