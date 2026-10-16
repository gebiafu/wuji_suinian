import '../../core/constants/app_constants.dart';

/// 物品状态：在用 / 闲置 / 已丢弃 / 借出
enum ItemStatus {
  using(AppConstants.statusUsing, '在用'),
  idle(AppConstants.statusIdle, '闲置'),
  discarded(AppConstants.statusDiscarded, '已丢弃'),
  lend(AppConstants.statusLend, '借出');

  const ItemStatus(this.value, this.label);

  final String value;
  final String label;

  static ItemStatus fromValue(String? value) {
    return ItemStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ItemStatus.using,
    );
  }
}