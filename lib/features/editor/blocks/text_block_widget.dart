import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../core/utils/markdown_parser.dart';
import '../../../theme/wasurenagusa_theme.dart';

class TextBlockWidget extends StatefulWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onFocused;
  final VoidCallback onUnfocused;
  final void Function(TextSelection)? onSaveSelection;

  const TextBlockWidget({
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
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget> {
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
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    TextField(
                      controller: widget.textController,
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
          ),
        ],
      ),
    );
  }
}
