import 'package:flutter_test/flutter_test.dart';
import 'package:wuji_suinian/domain/models/filters.dart';

import 'support/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = await TestEnv.create();
  });

  tearDown(() => env.dispose());

  test('新增 / 编辑 / 删除碎念', () async {
    final id = await seedNote(env, content: '买牛奶');
    var list = await env.notes.list(const NoteFilter());
    expect(list.length, 1);
    expect(list.first.note.content, '买牛奶');
    expect(list.first.note.isTodo, isFalse);

    await env.notes.update(id: id, content: '买牛奶和面包', isTodo: true);
    list = await env.notes.list(const NoteFilter());
    expect(list.first.note.content, '买牛奶和面包');
    expect(list.first.note.isTodo, isTrue);
    expect(list.first.note.todoFinished, isFalse);

    await env.notes.delete(id);
    expect((await env.notes.list(const NoteFilter())).isEmpty, isTrue);
  });

  test('待办勾选', () async {
    final id = await seedNote(env, content: '交电费', isTodo: true);
    await env.notes.toggleTodo(id, true);
    var list = await env.notes.list(const NoteFilter());
    expect(list.first.note.todoFinished, isTrue);

    await env.notes.toggleTodo(id, false);
    list = await env.notes.list(const NoteFilter());
    expect(list.first.note.todoFinished, isFalse);
  });

  test('置顶排序优先且时间倒序', () async {
    final first = await seedNote(env, content: '第一条');
    await Future<void>.delayed(const Duration(milliseconds: 3));
    final second = await seedNote(env, content: '第二条');
    await Future<void>.delayed(const Duration(milliseconds: 3));
    await seedNote(env, content: '第三条');
    await env.notes.setTop(first, true);

    final list = await env.notes.list(const NoteFilter());
    expect(list.first.note.id, first, reason: '置顶应排在最前');
    expect(list[1].note.content, '第三条');
    expect(list[2].note.content, '第二条');

    final onlyTop = await env.notes.list(const NoteFilter(onlyTop: true));
    expect(onlyTop.length, 1);
    expect(onlyTop.first.note.id, first);
    expect(second, isNot(first));
  });

  test('筛选：只看待办 / 只看未完成', () async {
    await seedNote(env, content: '普通碎念');
    final todoA = await seedNote(env, content: '待办A', isTodo: true);
    await seedNote(env, content: '待办B', isTodo: true);
    await env.notes.toggleTodo(todoA, true);

    expect(
      (await env.notes.list(const NoteFilter(onlyTodo: true))).length,
      2,
    );
    final unfinished =
        await env.notes.list(const NoteFilter(onlyUnfinishedTodo: true));
    expect(unfinished.length, 1);
    expect(unfinished.first.note.content, '待办B');
  });

  test('标签关联与标签筛选', () async {
    final idea = await env.tags.ensure('灵感');
    final todo = await env.tags.ensure('待办');
    await seedNote(env, content: '做个小工具', tagIds: <int>[idea]);
    await seedNote(env, content: '买电池', tagIds: <int>[todo]);

    final byTag = await env.notes.list(NoteFilter(tagIds: <int>[idea]));
    expect(byTag.length, 1);
    expect(byTag.first.note.content, '做个小工具');
    expect(byTag.first.tags.single.name, '灵感');
  });

  test('全文检索碎片文本', () async {
    await seedNote(env, content: '周三去医院取报告');
    await seedNote(env, content: '记一下报销流程');
    expect(
      (await env.notes.list(const NoteFilter(keyword: '医院'))).length,
      1,
    );
    expect(
      (await env.notes.list(const NoteFilter(keyword: '报告'))).length,
      1,
    );
    expect(
      (await env.notes.list(const NoteFilter(keyword: '不存在'))).isEmpty,
      isTrue,
    );
  });

  test('碎念附加图片：替换与删除时清理文件', () async {
    await writeImageFile(env.paths, 'note1.jpg', <int>[1, 2, 3]);
    final id = await seedNote(
      env,
      content: '收据',
      imagePath: 'asset/images/note1.jpg',
    );
    expect(await env.paths.fileFor('asset/images/note1.jpg').exists(), isTrue);
    await env.notes.delete(id);
    expect(await env.paths.fileFor('asset/images/note1.jpg').exists(), isFalse);
  });

  test('跨模块检索：物品与碎念分组返回', () async {
    await seedItem(env, name: '充电宝 20000mAh');
    await seedNote(env, content: '充电宝要记得充电');
    await seedNote(env, content: '别的碎念');

    final results = await env.search.search('充电宝');
    expect(results.items.length, 1);
    expect(results.notes.length, 1);
    expect(results.total, 2);

    final empty = await env.search.search('   ');
    expect(empty.isEmpty, isTrue);
  });
}