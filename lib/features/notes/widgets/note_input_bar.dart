import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/services/image_service.dart';
import '../../common/widgets/image_widgets.dart';
import 'note_editor_sheet.dart';
import '../notes_controller.dart';

/// 底部常驻输入框（微信聊天页风格）
class NoteInputBar extends ConsumerStatefulWidget {
  const NoteInputBar({super.key});

  @override
  ConsumerState<NoteInputBar> createState() => _NoteInputBarState();
}

class _NoteInputBarState extends ConsumerState<NoteInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _imagePath;
  bool _isTodo = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSourceKind kind) async {
    try {
      final service = ref.read(imageServiceProvider);
      final result = kind == ImageSourceKind.camera
          ? await service.pickFromCamera()
          : await service.pickFromGallery(multiple: false);
      if (result.isNotEmpty) {
        setState(() => _imagePath = result.first);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _imagePath == null) return;
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(notesControllerProvider.notifier).send(
            content: content,
            imageRelativePath: _imagePath,
            isTodo: _isTodo,
          );
      _controller.clear();
      setState(() {
        _imagePath = null;
        _isTodo = false;
      });
      _focusNode.requestFocus();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('发送失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openEditor() async {
    final result = await showNoteEditorSheet(context);
    if (result == null) return;
    await ref.read(notesControllerProvider.notifier).send(
          content: result.content,
          imageRelativePath: result.imageRelativePath,
          isTodo: result.isTodo,
          tagIds: result.tagIds,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    LocalImage(
                      relativePath: _imagePath!,
                      width: 56,
                      height: 56,
                    ),
                    const SizedBox(width: 8),
                    const Text('将随这条碎念一起保存'),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _imagePath = null),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  tooltip: '添加图片',
                  onPressed: () => showImageSourceSheet(context, onPick: _pick),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                ),
                IconButton(
                  tooltip: _isTodo ? '取消待办' : '标记为待办',
                  onPressed: () => setState(() => _isTodo = !_isTodo),
                  icon: Icon(
                    _isTodo ? Icons.check_box : Icons.check_box_outline_blank,
                    color: _isTodo ? theme.colorScheme.primary : null,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: '随手记一条…',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '详细编辑（标签等）',
                  onPressed: _openEditor,
                  icon: const Icon(Icons.tune),
                ),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}