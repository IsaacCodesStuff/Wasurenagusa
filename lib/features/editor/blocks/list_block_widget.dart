import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../theme/wasurenagusa_theme.dart';
import '../editor_controller.dart';

class ListBlockWidget extends StatelessWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final EditorController controller;
  final int blockIndex;

  const ListBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.controller,
    required this.blockIndex,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ThemeRegistry.instance.selectedFontSize;
    final isBullet = block.type == BlockType.bulletList;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ...block.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return _ListItem(
              item: item,
              index: i,
              isBullet: isBullet,
              colors: colors,
              onChanged: (text) => controller.updateItem(
                blockIndex,
                i,
                item.copyWith(content: text),
              ),
              onDelete: block.items.length > 1
                  ? () => controller.removeItem(blockIndex, i)
                  : null,
              onSubmit: () => controller.addItem(blockIndex),
            );
          }),
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

class _ListItem extends StatefulWidget {
  final BlockItemModel item;
  final int index;
  final bool isBullet;
  final WasurenagusaColorScheme colors;
  final ValueChanged<String> onChanged;
  final VoidCallback? onDelete;
  final VoidCallback onSubmit;

  const _ListItem({
    required this.item,
    required this.index,
    required this.isBullet,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
    required this.onSubmit,
  });

  @override
  State<_ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<_ListItem> {
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          child: Text(
            widget.isBullet ? '•' : '${widget.index + 1}.',
            style: TextStyle(
              color: widget.colors.accent,
              fontSize: fontSize.textSize,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            style: TextStyle(color: widget.colors.onSurface, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Item',
              hintStyle: TextStyle(color: widget.colors.onSurfaceVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: widget.onChanged,
            onSubmitted: (_) => widget.onSubmit(),
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
