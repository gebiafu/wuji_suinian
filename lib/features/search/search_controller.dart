import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/views.dart';

/// 全局检索关键词
final searchKeywordProvider = NotifierProvider<SearchKeywordNotifier, String>(
  SearchKeywordNotifier.new,
);

class SearchKeywordNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setKeyword(String keyword) => state = keyword;

  void clear() => state = '';
}

/// 跨模块检索结果（物品 / 碎念 分组）
final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  ref.watch(databaseProvider);
  final keyword = ref.watch(searchKeywordProvider);
  if (keyword.trim().isEmpty) {
    return const SearchResults(keyword: '');
  }
  return ref.read(searchRepositoryProvider).search(keyword);
});