import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../theme/wasurenagusa_theme.dart';

class HeadingBlockWidget extends StatefulWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  const HeadingBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<HeadingBlockWidget> createState() => _HeadingBlockWidgetState();
}

class _HeadingBlockWidgetState extends State<HeadingBlockWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.textContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ThemeRegistry.instance.selectedFontSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(
                color: widget.colors.onSurface,
                fontSize: fontSize.headingSize, // was 22
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              decoration: InputDecoration(
                hintText: 'Heading',
                hintStyle: TextStyle(
                  color: widget.colors.onSurfaceVariant,
                  fontSize: fontSize.headingSize,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onChanged: widget.onChanged,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.drag_handle_rounded,
              color: widget.colors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
