import 'package:flutter_test/flutter_test.dart';
import 'package:wuji_suinian/data/repositories/item_repository.dart';
import 'package:wuji_suinian/domain/models/filters.dart';
import 'package:wuji_suinian/domain/models/item_sort.dart';
import 'package:wuji_suinian/domain/models/item_status.dart';

import 'support/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = await TestEnv.create();
  });

  tearDown(() => env.dispose());

  test('新增 → 查询 → 编辑 → 删除 全流程', () async {
    final id = await seedItem(
      env,
      name: '博世电钻',
      location: '工位抽屉',
      price: 899.5,
      images: <String>['asset/images/drill.jpg'],
    );

    final created = await env.items.detail(id);
    expect(created, isNotNull);
    expect(created!.item.name, '博世电钻');
    expect(created.status, ItemStatus.using);
    expect(created.images.length, 1);
    expect(created.item.createAt, greaterThan(0));

    await env.items.update(
      ItemDraft(
        id: id,
        name: '博世电钻 GSB120',
        location: '后备箱',
        price: 799,
        status: ItemStatus.lend,
        lendTarget: '老王',
        lendTime: DateTime(2026, 10, 1),
        expectReturnTime: DateTime(2026, 11, 1),
        imageRelativePaths: <String>['asset/images/drill.jpg'],
      ),
    );
    final updated = await env.items.detail(id);
    expect(updated!.item.name, '博世电钻 GSB120');
    expect(updated.item.location, '后备箱');
    expect(updated.status, ItemStatus.lend);
    expect(updated.item.lendTarget, '老王');
    expect(updated.item.updateAt, greaterThanOrEqualTo(created.item.updateAt));

    await env.items.delete(id, deleteImages: false);
    expect(await env.items.detail(id), isNull);
  });

  test('编辑时保留 create_at，仅更新 update_at', () async {
    final id = await seedItem(env, name: 'A');
    final before = (await env.items.detail(id))!;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await env.items.update(ItemDraft(id: id, name: 'A2'));
    final after = (await env.items.detail(id))!;
    expect(after.item.createAt, before.item.createAt);
    expect(after.item.updateAt, greaterThanOrEqualTo(before.item.updateAt));
  });

  test('检索：名称 / 备注 / 位置 / 价格', () async {
    await seedItem(env, name: '机械键盘', location: '书房柜子', price: 499);
    await seedItem(env, name: '电动螺丝刀', location: '后备箱', price: 199);
    await env.items.create(
      const ItemDraft(name: '显卡', location: '主板箱', description: '二手买自朋友'),
    );

    expect((await env.items.list(const ItemFilter(keyword: '键盘'))).length, 1);
    expect((await env.items.list(const ItemFilter(keyword: '后备箱'))).length, 1);
    expect((await env.items.list(const ItemFilter(keyword: '二手'))).length, 1);
    expect((await env.items.list(const ItemFilter(keyword: '499'))).length, 1);
    expect((await env.items.list(const ItemFilter(keyword: '不存在的词'))).isEmpty, isTrue);
  });

  test('按分类 / 位置 / 状态 / 标签筛选', () async {
    final digital = await env.tags.ensure('数码');
    final tool = await env.tags.ensure('工具');

    await seedItem(env, name: '手机', categoryId: digital, location: '抽屉');
    await seedItem(env, name: '电钻', categoryId: tool, location: '后备箱');
    await env.items.update(
      ItemDraft(
        id: (await env.items.list(const ItemFilter(keyword: '电钻'))).first.item.id,
        name: '电钻',
        categoryId: tool,
        location: '后备箱',
        status: ItemStatus.discarded,
      ),
    );
    final drillId = (await env.items.list(const ItemFilter(keyword: '电钻'))).first.item.id;
    await env.db.itemsDao.setItemTags(drillId, <int>[tool]);

    expect((await env.items.list(ItemFilter(categoryId: digital))).length, 1);
    expect((await env.items.list(const ItemFilter(location: '后备箱'))).length, 1);
    expect(
      (await env.items.list(const ItemFilter(status: 'discarded'))).length,
      1,
    );
    expect((await env.items.list(ItemFilter(tagIds: <int>[tool]))).length, 1);
    expect(
      (await env.items.list(ItemFilter(tagIds: <int>[digital, tool]))).length,
      2,
    );
  });

  test('排序：新增时间 / 价格 / 名称', () async {
    await seedItem(env, name: 'B物品', price: 10);
    await seedItem(env, name: 'A物品', price: 300);
    await seedItem(env, name: 'C物品');

    final byName = await env.items.list(
      const ItemFilter(sort: ItemSort.nameAsc),
    );
    expect(byName.map((e) => e.item.name).toList(), <String>['A物品', 'B物品', 'C物品']);

    final byPrice = await env.items.list(
      const ItemFilter(sort: ItemSort.priceDesc),
    );
    expect(byPrice.first.item.name, 'A物品');
    expect(byPrice.last.item.name, 'C物品');

    final byCreated = await env.items.list(
      const ItemFilter(sort: ItemSort.createdAsc),
    );
    expect(byCreated.first.item.name, 'B物品');
  });

  test('多图与分类标签关系', () async {
    final digital = await env.tags.ensure('数码');
    final id = await env.items.create(
      ItemDraft(
        name: '相机',
        categoryId: digital,
        tagIds: <int>[digital],
        imageRelativePaths: <String>[
          'asset/images/1.jpg',
          'asset/images/2.jpg',
          'asset/images/3.jpg',
        ],
      ),
    );
    final entry = (await env.items.detail(id))!;
    expect(entry.images.length, 3);
    expect(entry.images.first.relativePath, 'asset/images/1.jpg');
    expect(entry.category?.name, '数码');
    expect(entry.normalTags, isEmpty);

    // 替换图片：顺序与数量都应更新
    await env.items.update(
      ItemDraft(
        id: id,
        name: '相机',
        categoryId: digital,
        imageRelativePaths: <String>['asset/images/9.jpg'],
      ),
    );
    final after = (await env.items.detail(id))!;
    expect(after.images.length, 1);
    expect(after.images.first.relativePath, 'asset/images/9.jpg');
  });

  test('删除物品时按需删除本地原图', () async {
    final id = await seedItem(
      env,
      name: '耳机',
      images: <String>['asset/images/ear.jpg'],
    );
    await writeImageFile(env.paths, 'ear.jpg', <int>[1, 2, 3]);
    expect(await env.paths.fileFor('asset/images/ear.jpg').exists(), isTrue);

    await env.items.delete(id, deleteImages: true);
    expect(await env.paths.fileFor('asset/images/ear.jpg').exists(), isFalse);
  });

  test('统计与质保关注清单', () async {
    final online = await env.tags.ensure('网购');
    await seedItem(env, name: 'A', price: 100, categoryId: online, location: '桌上');
    await seedItem(env, name: 'B', price: 50.5, categoryId: online, location: '抽屉');
    await seedItem(
      env,
      name: 'C',
      warrantyEnd: DateTime.now().add(const Duration(days: 5)),
    );
    await seedItem(
      env,
      name: 'D',
      warrantyEnd: DateTime.now().add(const Duration(days: 300)),
    );

    final stats = await env.items.stats();
    expect(stats.totalCount, 4);
    expect(stats.totalValue, closeTo(150.5, 0.001));
    expect(stats.statusCounts[ItemStatus.using], 4);
    expect(stats.categoryCounts['网购'], 2);

    final watch = await env.items.warrantyWatchList(days: 30);
    expect(watch.map((e) => e.item.name).toList(), <String>['C']);
  });

  test('存放位置去重列表', () async {
    await seedItem(env, name: 'A', location: '抽屉');
    await seedItem(env, name: 'B', location: '抽屉');
    await seedItem(env, name: 'C', location: '后备箱');
    await seedItem(env, name: 'D');
    expect(await env.items.distinctLocations(), <String>['后备箱', '抽屉']);
  });
}