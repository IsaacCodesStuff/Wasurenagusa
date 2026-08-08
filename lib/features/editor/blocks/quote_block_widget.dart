import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../core/utils/markdown_parser.dart';
import '../../../theme/wasurenagusa_theme.dart';

class QuoteBlockWidget extends StatefulWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  const QuoteBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<QuoteBlockWidget> createState() => _QuoteBlockWidgetState();
}

class _QuoteBlockWidgetState extends State<QuoteBlockWidget> {
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
      color: widget.colors.onSurfaceVariant,
      fontSize: fontSize.textSize,
      fontStyle: FontStyle.italic,
      height: 1.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: widget.colors.accent.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: showRendered
                  ? GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: Padding(
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
                    )
                  : TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: baseStyle,
                      decoration: InputDecoration(
                        hintText: 'Quote',
                        hintStyle: TextStyle(
                          color: widget.colors.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: widget.onChanged,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
