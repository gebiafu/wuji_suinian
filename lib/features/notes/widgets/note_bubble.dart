import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/time_utils.dart';
import '../../../domain/models/views.dart';
import '../../common/widgets/image_widgets.dart';
import '../../common/widgets/tag_selector.dart';
import '../notes_controller.dart';
import 'note_editor_sheet.dart';

/// 单条碎念气泡
class NoteBubble extends ConsumerWidget {
  const NoteBubble({super.key, required this.entry, this.keyword = ''});

  final NoteWithTags entry;
  final String keyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final note = entry.note;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          GestureDetector(
            onLongPress: () => _showActions(context, ref),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                color: note.isTop
                    ? theme.colorScheme.tertiaryContainer
                    : theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (note.imagePath != null && note.imagePath!.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ImageGalleryViewer(
                            relativePaths: <String>[note.imagePath!],
                          ),
                        ),
                      ),
                      child: LocalImage(
                        relativePath: note.imagePath!,
                        width: 180,
                        height: 140,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (note.isTodo) ...<Widget>[
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: note.todoFinished,
                            onChanged: (value) => ref
                                .read(notesControllerProvider.notifier)
                                .toggleTodo(note.id, value ?? false),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          note.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: note.isTodo && note.todoFinished
                                ? TextDecoration.lineThrough
                                : null,
                            color: note.isTodo && note.todoFinished
                                ? theme.colorScheme.outline
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (entry.tags.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: <Widget>[
                        for (final tag in entry.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '#${tag.name}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (note.isTop) ...<Widget>[
                Icon(
                  Icons.push_pin,
                  size: 12,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                TimeUtils.formatChatTime(
                  TimeUtils.toDateTime(note.createAt),
                ),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final note = entry.note;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: Icon(
                note.isTop ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(note.isTop ? '取消置顶' : '置顶'),
              onTap: () => Navigator.pop(context, 'top'),
            ),
            ListTile(
              leading: const Icon(Icons.local_offer_outlined),
              title: const Text('添加标签'),
              onTap: () => Navigator.pop(context, 'tag'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('复制文本'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('删除'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final controller = ref.read(notesControllerProvider.notifier);
    switch (action) {
      case 'edit':
        final result = await showNoteEditorSheet(context, existing: entry);
        if (result == null) return;
        await controller.edit(
          id: note.id,
          content: result.content,
          imageRelativePath: result.imageRelativePath,
          isTodo: result.isTodo,
          tagIds: result.tagIds,
          previousImagePath: note.imagePath,
          removeImage: result.removeImage,
        );
        break;
      case 'top':
        await controller.toggleTop(note.id, !note.isTop);
        break;
      case 'tag':
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 8,
            ),
            child: TagSelector(
              selectedIds: entry.tags.map((e) => e.id).toList(),
              onChanged: (ids) => controller.setTags(note.id, ids),
            ),
          ),
        );
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: note.content));
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('已复制文本')));
        }
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除这条碎念？'),
            content: Text(
              note.imagePath == null
                  ? '删除后无法恢复。'
                  : '同时会删除附图文件，删除后无法恢复。',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await controller.remove(note.id);
        }
        break;
      default:
        break;
    }
  }
}