/// 物品列表排序方式。
enum ItemSort {
  createdDesc('新增时间（新→旧）'),
  createdAsc('新增时间（旧→新）'),
  buyDateDesc('购买时间（新→旧）'),
  priceDesc('价格（高→低）'),
  priceAsc('价格（低→高）'),
  nameAsc('名称（A→Z）');

  const ItemSort(this.label);

  final String label;
}