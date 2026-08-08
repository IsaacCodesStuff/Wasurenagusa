import 'package:flutter/material.dart';

/// Parses a subset of inline Markdown into a TextSpan tree.
/// Supports: **bold**, *italic*, `inline code`
/// Nesting is not supported — patterns are applied left to right.
class InlineMarkdown {
  static TextSpan parse(
    String text, {
    required TextStyle baseStyle,
    required Color codeBackground,
    required Color codeColor,
  }) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|~~(.+?)~~');
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(
          TextSpan(
            text: match.group(1),
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (match.group(2) != null) {
        // *italic*
        spans.add(
          TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(3) != null) {
        // `code`
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: codeBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                match.group(3)!,
                style: baseStyle.copyWith(
                  fontFamily: 'monospace',
                  color: codeColor,
                  fontSize: (baseStyle.fontSize ?? 15) - 1,
                ),
              ),
            ),
          ),
        );
      } else if (match.group(4) != null) {
        // ~~strikethrough~~
        spans.add(
          TextSpan(
            text: match.group(4),
            style: baseStyle.copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: baseStyle.color,
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return TextSpan(children: spans);
  }
}
