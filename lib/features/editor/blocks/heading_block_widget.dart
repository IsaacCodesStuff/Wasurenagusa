import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../core/utils/markdown_parser.dart';
import '../../../theme/wasurenagusa_theme.dart';

class HeadingBlockWidget extends StatefulWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final TextEditingController textController;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onFocused;
  final VoidCallback onUnfocused;
  final void Function(TextSelection)? onSaveSelection;

  const HeadingBlockWidget({
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
  State<HeadingBlockWidget> createState() => _HeadingBlockWidgetState();
}

class _HeadingBlockWidgetState extends State<HeadingBlockWidget> {
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
      fontSize: fontSize.headingSize, // heading-specific
      fontWeight: FontWeight.w700, // heading-specific
      height: 1.3, // heading-specific
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), // heading-specific
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
                        hintText: showRendered ? null : 'Heading',
                        hintStyle: TextStyle(
                          color: widget.colors.onSurfaceVariant,
                          fontSize: fontSize.headingSize, // heading-specific
                          fontWeight: FontWeight.w700, // heading-specific
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                        ), // heading-specific
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: widget.onChanged,
                    ),
                    if (showRendered)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                        ), // heading-specific
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
