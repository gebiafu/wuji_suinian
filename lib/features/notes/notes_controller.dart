import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/views.dart';

/// 碎念筛选条件（标签 / 待办 / 置顶 / 关键词）
final noteFilterProvider = NotifierProvider<NoteFilterNotifier, NoteFilter>(
  NoteFilterNotifier.new,
);

class NoteFilterNotifier extends Notifier<NoteFilter> {
  @override
  NoteFilter build() => const NoteFilter();

  void setKeyword(String keyword) => state = state.copyWith(keyword: keyword);

  void toggleOnlyTodo() => state = state.copyWith(onlyTodo: !state.onlyTodo);

  void toggleOnlyUnfinished() =>
      state = state.copyWith(onlyUnfinishedTodo: !state.onlyUnfinishedTodo);

  void toggleOnlyTop() => state = state.copyWith(onlyTop: !state.onlyTop);

  void toggleTag(int tagId) {
    final ids = List<int>.of(state.tagIds);
    if (ids.contains(tagId)) {
      ids.remove(tagId);
    } else {
      ids.add(tagId);
    }
    state = state.copyWith(tagIds: ids);
  }

  void reset() => state = const NoteFilter();
}

final notesControllerProvider =
    AsyncNotifierProvider<NotesController, List<NoteWithTags>>(
  NotesController.new,
);

class NotesController extends AsyncNotifier<List<NoteWithTags>> {
  @override
  Future<List<NoteWithTags>> build() {
    ref.watch(databaseProvider);
    final filter = ref.watch(noteFilterProvider);
    return ref.read(noteRepositoryProvider).list(filter);
  }

  Future<void> _reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<int> send({
    required String content,
    String? imageRelativePath,
    bool isTodo = false,
    List<int> tagIds = const <int>[],
  }) async {
    final id = await ref.read(noteRepositoryProvider).create(
          content: content,
          imageRelativePath: imageRelativePath,
          isTodo: isTodo,
          tagIds: tagIds,
        );
    await _reload();
    return id;
  }

  Future<void> edit({
    required int id,
    required String content,
    String? imageRelativePath,
    bool? isTodo,
    List<int>? tagIds,
    String? previousImagePath,
    bool removeImage = false,
  }) async {
    await ref.read(noteRepositoryProvider).update(
          id: id,
          content: content,
          imageRelativePath: imageRelativePath,
          isTodo: isTodo,
          tagIds: tagIds,
          previousImagePath: previousImagePath,
          removeImage: removeImage,
        );
    await _reload();
  }

  Future<void> remove(int id, {bool deleteImage = true}) async {
    await ref.read(noteRepositoryProvider).delete(id, deleteImage: deleteImage);
    await _reload();
  }

  Future<void> toggleTodo(int id, bool finished) async {
    await ref.read(noteRepositoryProvider).toggleTodo(id, finished);
    await _reload();
  }

  Future<void> toggleTop(int id, bool top) async {
    await ref.read(noteRepositoryProvider).setTop(id, top);
    await _reload();
  }

  Future<void> setTags(int id, List<int> tagIds) async {
    await ref.read(noteRepositoryProvider).db.notesDao.setNoteTags(id, tagIds);
    await _reload();
  }

  Future<void> refresh() => _reload();
}