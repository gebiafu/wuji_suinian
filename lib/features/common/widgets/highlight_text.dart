import 'package:flutter/material.dart';

/// 关键词高亮（全局检索结果使用）
class HighlightText extends StatelessWidget {
  const HighlightText({
    super.key,
    required this.text,
    required this.keyword,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String keyword;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final kw = keyword.trim();
    if (kw.isEmpty) {
      return Text(text, style: baseStyle, maxLines: maxLines, overflow: overflow);
    }

    final highlightStyle = baseStyle.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
      backgroundColor:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
    );

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerKeyword = kw.toLowerCase();
    var start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerKeyword, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + kw.length),
          style: highlightStyle,
        ),
      );
      start = index + kw.length;
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}