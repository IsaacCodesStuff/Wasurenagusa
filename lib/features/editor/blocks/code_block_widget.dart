import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/note_block_model.dart';
import '../../../theme/wasurenagusa_theme.dart';

class CodeBlockWidget extends StatefulWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  const CodeBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
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
      child: Container(
        decoration: BoxDecoration(
          color: widget.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.code_rounded,
                    color: widget.colors.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Code',
                    style: TextStyle(
                      color: widget.colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.copy_rounded,
                      color: widget.colors.onSurfaceVariant,
                      size: 16,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _controller.text));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: 'Copy',
                  ),
                ],
              ),
            ),
            Divider(color: widget.colors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  color: widget.colors.onSurface,
                  fontSize: fontSize.textSize - 1,
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: '// Write code here',
                  hintStyle: TextStyle(
                    color: widget.colors.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                // No auto-capitalization for code
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
