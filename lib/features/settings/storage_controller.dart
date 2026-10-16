import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/views.dart';

final storageStatsProvider = FutureProvider<StorageStats>((ref) {
  ref.watch(databaseProvider);
  return ref.read(storageServiceProvider).stats();
});

final orphanCountProvider = FutureProvider<int>((ref) {
  ref.watch(databaseProvider);
  return ref.read(storageServiceProvider).cleanOrphans(dryRun: true);
});

/// 标签管理页数据
final tagUsageListProvider = FutureProvider<List<TagUsage>>((ref) {
  ref.watch(databaseProvider);
  return ref.read(tagRepositoryProvider).usage();
});