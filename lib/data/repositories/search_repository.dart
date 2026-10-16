import '../../domain/models/filters.dart';
import '../../domain/models/views.dart';
import 'item_repository.dart';
import 'note_repository.dart';

/// 全局跨模块检索：同时搜物品台账 + 碎念，结果分组展示。
class SearchRepository {
  SearchRepository({required this.items, required this.notes});

  final ItemRepository items;
  final NoteRepository notes;

  Future<SearchResults> search(String keyword) async {
    final kw = keyword.trim();
    if (kw.isEmpty) {
      return const SearchResults(keyword: '');
    }
    final itemResults = await items.list(ItemFilter(keyword: kw));
    final noteResults = await notes.list(NoteFilter(keyword: kw));
    return SearchResults(
      keyword: kw,
      items: itemResults,
      notes: noteResults,
    );
  }
}