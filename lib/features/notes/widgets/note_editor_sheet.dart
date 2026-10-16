import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/services/image_service.dart';
import '../../../domain/models/views.dart';
import '../../common/widgets/image_widgets.dart';
import '../../common/widgets/tag_selector.dart';

/// 编辑结果
class NoteEditResult {
  const NoteEditResult({
    required this.content,
    required this.isTodo,
    required this.tagIds,
    this.imageRelativePath,
    this.removeImage = false,
  });

  final String content;
  final bool isTodo;
  final List<int> tagIds;
  final String? imageRelativePath;
  final bool removeImage;
}

/// 碎念编辑面板（新增 / 修改）
Future<NoteEditResult?> showNoteEditorSheet(
  BuildContext context, {
  NoteWithTags? existing,
}) {
  return showModalBottomSheet<NoteEditResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: NoteEditorSheet(existing: existing),
    ),
  );
}

class NoteEditorSheet extends ConsumerStatefulWidget {
  const NoteEditorSheet({super.key, this.existing});

  final NoteWithTags? existing;

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.existing?.note.content ?? '');
  late bool _isTodo = widget.existing?.note.isTodo ?? false;
  late List<int> _tagIds =
      widget.existing?.tags.map((e) => e.id).toList() ?? <int>[];
  late String? _imagePath = widget.existing?.note.imagePath;
  bool _removedImage = false;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSourceKind kind) async {
    setState(() => _busy = true);
    try {
      final service = ref.read(imageServiceProvider);
      final result = kind == ImageSourceKind.camera
          ? await service.pickFromCamera()
          : await service.pickFromGallery(multiple: false);
      if (result.isNotEmpty) {
        setState(() {
          _imagePath = result.first;
          _removedImage = false;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _save() {
    final content = _controller.text.trim();
    if (content.isEmpty && _imagePath == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('内容不能为空')));
      return;
    }
    Navigator.pop(
      context,
      NoteEditResult(
        content: content,
        isTodo: _isTodo,
        tagIds: _tagIds,
        imageRelativePath: _imagePath,
        removeImage: _removedImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            widget.existing == null ? '新增碎念' : '编辑碎念',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 6,
            minLines: 3,
            autofocus: widget.existing == null,
            decoration: const InputDecoration(hintText: '记点什么…（支持换行）'),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              FilterChip(
                avatar: Icon(
                  _isTodo ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                ),
                label: const Text('标记为待办'),
                selected: _isTodo,
                onSelected: (value) => setState(() => _isTodo = value),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _busy
                    ? null
                    : () => showImageSourceSheet(context, onPick: _pick),
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(_imagePath == null ? '附加图片' : '更换图片'),
              ),
              if (_imagePath != null)
                IconButton(
                  tooltip: '移除图片',
                  onPressed: () => setState(() {
                    _imagePath = null;
                    _removedImage = true;
                  }),
                  icon: const Icon(Icons.delete_outline, size: 18),
                ),
            ],
          ),
          if (_imagePath != null) ...<Widget>[
            const SizedBox(height: 8),
            LocalImage(relativePath: _imagePath!, width: 120, height: 120),
          ],
          const SizedBox(height: 16),
          TagSelector(
            selectedIds: _tagIds,
            onChanged: (ids) => setState(() => _tagIds = ids),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _save, child: const Text('保存')),
          ),
        ],
      ),
    );
  }
}