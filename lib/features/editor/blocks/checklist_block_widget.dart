import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../theme/wasurenagusa_theme.dart';
import '../editor_controller.dart';

class ChecklistBlockWidget extends StatelessWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final EditorController controller;
  final int blockIndex;

  const ChecklistBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.controller,
    required this.blockIndex,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ThemeRegistry.instance.selectedFontSize;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ...block.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return _ChecklistItem(
              item: item,
              colors: colors,
              onChanged: (text) => controller.updateItem(
                blockIndex,
                i,
                item.copyWith(content: text),
              ),
              onToggle: () => controller.updateItem(
                blockIndex,
                i,
                item.copyWith(isChecked: !item.isChecked),
              ),
              onDelete: block.items.length > 1
                  ? () => controller.removeItem(blockIndex, i)
                  : null,
              onSubmit: () => controller.addItem(blockIndex),
            );
          }),
          // Add item button
          InkWell(
            onTap: () => controller.addItem(blockIndex),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add item',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: fontSize.textSize,
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

class _ChecklistItem extends StatefulWidget {
  final BlockItemModel item;
  final WasurenagusaColorScheme colors;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback onSubmit;

  const _ChecklistItem({
    required this.item,
    required this.colors,
    required this.onChanged,
    required this.onToggle,
    required this.onDelete,
    required this.onSubmit,
  });

  @override
  State<_ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<_ChecklistItem> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ThemeRegistry.instance.selectedFontSize;
    return Row(
      children: [
        Checkbox(
          value: widget.item.isChecked,
          onChanged: (_) => widget.onToggle(),
          activeColor: widget.colors.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: BorderSide(color: widget.colors.onSurfaceVariant),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            style: TextStyle(
              color: widget.item.isChecked
                  ? widget.colors.onSurfaceVariant
                  : widget.colors.onSurface,
              fontSize: fontSize.textSize,
              decoration: widget.item.isChecked
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
            decoration: InputDecoration(
              hintText: 'Item',
              hintStyle: TextStyle(color: widget.colors.onSurfaceVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: widget.onChanged,
            onSubmitted: (_) => widget.onSubmit(),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        if (widget.onDelete != null)
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: widget.colors.onSurfaceVariant,
              size: 18,
            ),
            onPressed: widget.onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }
}
