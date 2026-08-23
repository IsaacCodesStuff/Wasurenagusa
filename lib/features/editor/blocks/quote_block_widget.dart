import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../core/utils/markdown_parser.dart';
import '../../../theme/wasurenagusa_theme.dart';

class QuoteBlockWidget extends StatefulWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onFocused;
  final VoidCallback onUnfocused;
  final void Function(TextSelection)? onSaveSelection;

  const QuoteBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.textController,
    required this.onChanged,
    required this.onDelete,
    required this.onFocused,
    required this.onUnfocused,
    required this.onSaveSelection,
  });

  @override
  State<QuoteBlockWidget> createState() => _QuoteBlockWidgetState();
}

class _QuoteBlockWidgetState extends State<QuoteBlockWidget> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      final focused = _focusNode.hasFocus;
      setState(() => _isFocused = focused);
      if (focused) {
        widget.onFocused();
      } else {
        // Save selection before focus is lost
        widget.onSaveSelection?.call(widget.textController.selection);
        widget.onUnfocused();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ThemeRegistry.instance.selectedFontSize;
    final markdownEnabled = ThemeRegistry.instance.markdownEnabled;
    final showRendered =
        markdownEnabled && !_isFocused && widget.textController.text.isNotEmpty;

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
                      controller: widget.textController,
                      focusNode: _focusNode,
                      style: baseStyle.copyWith(
                        color: showRendered
                            ? Colors.transparent
                            : widget.colors.onSurfaceVariant,
                      ),
                      decoration: InputDecoration(
                        hintText: showRendered ? null : 'Quote',
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
                    if (showRendered)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: RichText(
                          text: InlineMarkdown.parse(
                            widget.textController.text,
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
      ),
    );
  }
}
