import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../core/utils/markdown_parser.dart';
import '../../../theme/wasurenagusa_theme.dart';
import '../editor_controller.dart';

class ListBlockWidget extends StatelessWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final EditorController controller;
  final int blockIndex;
  final ValueChanged<TextEditingController>? onFocusGained;
  final VoidCallback? onFocusLost;
  final ValueChanged<TextEditingController>? onItemFocusGained;
  final VoidCallback? onItemFocusLost;

  const ListBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.controller,
    required this.blockIndex,
    this.onFocusGained,
    this.onFocusLost,
    this.onItemFocusGained,
    this.onItemFocusLost,
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
              key: ValueKey(item.id ?? i),
              item: item,
              index: i,
              isBullet: isBullet,
              colors: colors,
              onChanged: (text) => controller.updateItem(
                blockIndex,
                i,
                item.copyWith(content: text),
              ),
              onFocusGained: onItemFocusGained,
              onFocusLost: onItemFocusLost,
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
  final ValueChanged<TextEditingController>? onFocusGained;
  final VoidCallback? onFocusLost;

  const _ListItem({
    super.key,
    required this.item,
    required this.index,
    required this.isBullet,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
    required this.onSubmit,
    this.onFocusGained,
    this.onFocusLost,
  });

  @override
  State<_ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<_ListItem> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.content);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      final focused = _focusNode.hasFocus;
      setState(() => _isFocused = focused);
      if (focused) {
        widget.onFocusGained?.call(_controller);
      } else {
        widget.onFocusLost?.call();
      }
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
                    hintText: showRendered ? null : 'Item',
                    hintStyle: TextStyle(color: widget.colors.onSurfaceVariant),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => widget.onSubmit(),
                  textCapitalization: TextCapitalization.sentences,
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
