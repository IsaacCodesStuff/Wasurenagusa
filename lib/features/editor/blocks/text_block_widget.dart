import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../core/utils/markdown_parser.dart';
import '../../../theme/wasurenagusa_theme.dart';

class TextBlockWidget extends StatefulWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  const TextBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.textContent);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ThemeRegistry.instance.selectedFontSize;
    final markdownEnabled = ThemeRegistry.instance.markdownEnabled;
    final showRendered =
        markdownEnabled && !_isFocused && _controller.text.isNotEmpty;

    final baseStyle = TextStyle(
      color: widget.colors.onSurface,
      fontSize: fontSize.textSize,
      height: 1.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (showRendered) {
                  setState(() => _isFocused = true);
                  _focusNode.requestFocus();
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: baseStyle.copyWith(
                      color: showRendered
                          ? Colors.transparent
                          : widget.colors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: showRendered ? null : 'Write something...',
                      hintStyle: TextStyle(
                        color: widget.colors.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: widget.onChanged,
                  ),
                  if (showRendered)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: RichText(
                        text: InlineMarkdown.parse(
                          _controller.text,
                          baseStyle: baseStyle,
                          codeBackground: widget.colors.surfaceVariant,
                          codeColor: widget.colors.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
