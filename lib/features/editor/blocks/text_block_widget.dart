import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(
                color: widget.colors.onSurface,
                fontSize: fontSize.textSize,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Write something...',
                hintStyle: TextStyle(color: widget.colors.onSurfaceVariant),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              maxLines: null,
              onChanged: widget.onChanged,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.drag_handle_rounded,
              color: widget.colors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: null, // handled by ReorderableListView
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
