import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/time_utils.dart';
import '../../data/db/database.dart';
import '../../data/repositories/item_repository.dart';
import '../../domain/models/item_status.dart';
import '../../domain/models/views.dart';
import '../common/widgets/image_widgets.dart';
import '../common/widgets/tag_selector.dart';
import 'items_controller.dart';

/// 新增 / 编辑物品
class ItemFormPage extends ConsumerStatefulWidget {
  const ItemFormPage({super.key, this.initial});

  final ItemWithImages? initial;

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _unit;
  late final TextEditingController _buyChannel;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _lendTarget;

  late List<String> _images;
  late List<int> _tagIds;
  int? _categoryId;
  DateTime? _buyDate;
  DateTime? _warrantyEnd;
  DateTime? _lendTime;
  DateTime? _expectReturn;
  ItemStatus _status = ItemStatus.using;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initial?.item;
    _name = TextEditingController(text: item?.name ?? '');
    _price = TextEditingController(
      text: item?.price == null ? '' : _trim(item!.price!),
    );
    _unit = TextEditingController(text: item?.unit ?? '元');
    _buyChannel = TextEditingController(text: item?.buyChannel ?? '');
    _location = TextEditingController(text: item?.location ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _lendTarget = TextEditingController(text: item?.lendTarget ?? '');
    _images = widget.initial?.images
            .map((e) => e.relativePath)
            .toList(growable: true) ??
        <String>[];
    _tagIds = widget.initial?.normalTags.map((e) => e.id).toList() ?? <int>[];
    _categoryId = item?.categoryId;
    _buyDate = TimeUtils.toDateTime(item?.buyDate);
    _warrantyEnd = TimeUtils.toDateTime(item?.warrantyEndDate);
    _lendTime = TimeUtils.toDateTime(item?.lendTime);
    _expectReturn = TimeUtils.toDateTime(item?.expectReturnTime);
    _status = ItemStatus.fromValue(item?.status);
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _name,
      _price,
      _unit,
      _buyChannel,
      _location,
      _description,
      _lendTarget,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _trim(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 30),
      helpText: '选择日期',
      confirmText: '确定',
      cancelText: '取消',
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final draft = ItemDraft(
      id: widget.initial?.item.id,
      name: _name.text,
      categoryId: _categoryId,
      location: _location.text,
      price: double.tryParse(_price.text.trim()),
      unit: _unit.text.trim().isEmpty ? '元' : _unit.text.trim(),
      buyChannel: _buyChannel.text,
      buyDate: _buyDate,
      warrantyEndDate: _warrantyEnd,
      status: _status,
      lendTarget: _status == ItemStatus.lend ? _lendTarget.text : null,
      lendTime: _status == ItemStatus.lend ? _lendTime : null,
      expectReturnTime: _status == ItemStatus.lend ? _expectReturn : null,
      description: _description.text,
      imageRelativePaths: _images,
      tagIds: _tagIds,
    );
    try {
      final controller = ref.read(itemsControllerProvider.notifier);
      if (draft.isEditing) {
        await controller.updateItem(draft);
      } else {
        await controller.create(draft);
      }
      await _cleanupRemovedImages();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 删除本次编辑中被移除的图片（确认没有其它记录引用后再删文件）
  Future<void> _cleanupRemovedImages() async {
    final original =
        widget.initial?.images.map((e) => e.relativePath).toSet() ?? <String>{};
    if (original.isEmpty) return;
    final removed = original.difference(_images.toSet());
    if (removed.isEmpty) return;
    final storage = ref.read(storageServiceProvider);
    final referenced = await storage.referencedImagePaths();
    final imageService = ref.read(imageServiceProvider);
    for (final path in removed) {
      if (!referenced.contains(path)) {
        await imageService.deleteByRelativePath(path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    final locations = ref.watch(locationsProvider).value ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? '新增物品' : '编辑物品'),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: <Widget>[
            ImagePickerField(
              relativePaths: _images,
              onChanged: (value) => setState(() => _images = value),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '物品名称 *',
                hintText: '例如：博世电钻 GSB 120',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? '请填写物品名称' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: '分类'),
                    items: <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('未分类'),
                      ),
                      for (final tag in tags)
                        DropdownMenuItem<int?>(
                          value: tag.id,
                          child: Text(tag.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '新建分类',
                  onPressed: _createCategory,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: '存放位置',
                hintText: '书房柜子 / 后备箱 / 工位抽屉',
              ),
            ),
            if (locations.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final location in locations.take(6))
                    ActionChip(
                      label: Text(location),
                      onPressed: () => setState(() => _location.text = location),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '购买价格'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(labelText: '货币单位'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buyChannel,
              decoration: const InputDecoration(
                labelText: '购买渠道',
                hintText: '淘宝 / 京东 / 线下门店',
              ),
            ),
            const SizedBox(height: 16),
            _DateField(
              label: '购买日期',
              value: _buyDate,
              onPick: () => _pickDate(
                current: _buyDate,
                onPicked: (value) => setState(() => _buyDate = value),
              ),
              onClear: () => setState(() => _buyDate = null),
            ),
            const SizedBox(height: 8),
            _DateField(
              label: '质保到期日（用于到期提醒）',
              value: _warrantyEnd,
              onPick: () => _pickDate(
                current: _warrantyEnd,
                onPicked: (value) => setState(() => _warrantyEnd = value),
              ),
              onClear: () => setState(() => _warrantyEnd = null),
            ),
            const SizedBox(height: 20),
            Text('状态', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final status in ItemStatus.values)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
              ],
            ),
            if (_status == ItemStatus.lend) ...<Widget>[
              const SizedBox(height: 16),
              TextFormField(
                controller: _lendTarget,
                decoration: const InputDecoration(
                  labelText: '借给谁',
                  hintText: '例如：老王',
                ),
              ),
              const SizedBox(height: 8),
              _DateField(
                label: '借出时间',
                value: _lendTime,
                onPick: () => _pickDate(
                  current: _lendTime,
                  onPicked: (value) => setState(() => _lendTime = value),
                ),
                onClear: () => setState(() => _lendTime = null),
              ),
              const SizedBox(height: 8),
              _DateField(
                label: '预计归还时间',
                value: _expectReturn,
                onPick: () => _pickDate(
                  current: _expectReturn,
                  onPicked: (value) => setState(() => _expectReturn = value),
                ),
                onClear: () => setState(() => _expectReturn = null),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '备注 / 详细描述',
                hintText: '型号、配件、保修凭证位置…',
              ),
            ),
            const SizedBox(height: 20),
            TagSelector(
              label: '标签（可与碎念共用）',
              selectedIds: _tagIds,
              onChanged: (ids) => setState(() => _tagIds = ids),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('保存物品'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建分类'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：数码 / 工具 / 衣物'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final id = await ref.read(tagRepositoryProvider).ensure(name);
    ref.invalidate(tagsProvider);
    setState(() => _categoryId = id);
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                ),
        ),
        child: Text(
          value == null ? '未填写' : TimeUtils.formatDate(value),
          style: value == null
              ? TextStyle(color: Theme.of(context).colorScheme.outline)
              : null,
        ),
      ),
    );
  }
}