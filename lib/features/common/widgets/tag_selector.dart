import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// 标签多选 + 快速新建（物品 / 碎念共用标签池）
class TagSelector extends ConsumerStatefulWidget {
  const TagSelector({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    this.label = '标签',
    this.allowCreate = true,
  });

  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;
  final String label;
  final bool allowCreate;

  @override
  ConsumerState<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends ConsumerState<TagSelector> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createTag() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final id = await ref.read(tagRepositoryProvider).ensure(name);
    _controller.clear();
    ref.invalidate(tagsProvider);
    if (!widget.selectedIds.contains(id)) {
      widget.onChanged(<int>[...widget.selectedIds, id]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsValue = ref.watch(tagsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        tagsValue.when(
          data: (tags) {
            if (tags.isEmpty) {
              return Text(
                '暂无标签，可在下方输入新建',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                for (final tag in tags)
                  FilterChip(
                    label: Text(tag.name),
                    selected: widget.selectedIds.contains(tag.id),
                    onSelected: (selected) {
                      final ids = List<int>.of(widget.selectedIds);
                      if (selected) {
                        ids.add(tag.id);
                      } else {
                        ids.remove(tag.id);
                      }
                      widget.onChanged(ids);
                    },
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (error, stack) => Text('标签加载失败：$error'),
        ),
        if (widget.allowCreate) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: '新建标签，例如：数码 / 灵感'),
                  onSubmitted: (_) => _createTag(),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: _createTag, child: const Text('新建')),
            ],
          ),
        ],
      ],
    );
  }
}