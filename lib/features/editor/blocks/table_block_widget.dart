import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../theme/wasurenagusa_theme.dart';

class TableBlockWidget extends StatefulWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final VoidCallback onDelete;
  final Future<void> Function(TableData) onSave;

  const TableBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<TableBlockWidget> createState() => _TableBlockWidgetState();
}

class _TableBlockWidgetState extends State<TableBlockWidget> {
  late TableData _data;
  // Keyed by "row,col"
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _data = widget.block.tableData ?? TableData.empty();
    _initControllers();
  }

  void _initControllers() {
    for (int r = 0; r < _data.rows; r++) {
      for (int c = 0; c < _data.cols; c++) {
        final key = '$r,$c';
        _controllers[key] = TextEditingController(text: _data.cells[r][c]);
        _focusNodes[key] = FocusNode();
      }
    }
  }

  void _disposeControllers() {
    for (final tc in _controllers.values) tc.dispose();
    for (final fn in _focusNodes.values) fn.dispose();
    _controllers.clear();
    _focusNodes.clear();
  }

  void _rebuildControllers(TableData newData) {
    // Dispose old, rebuild for new dimensions
    _disposeControllers();
    _data = newData;
    _initControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _saveCell(int row, int col) async {
    final key = '$row,$col';
    final value = _controllers[key]?.text ?? '';
    final newData = _data.withCell(row, col, value);
    _data = newData;
    await widget.onSave(newData);
  }

  Future<void> _addRow() async {
    final newData = _data.addRow();
    _rebuildControllers(newData);
    setState(() {});
    await widget.onSave(newData);
  }

  Future<void> _addCol() async {
    final newData = _data.addCol();
    _rebuildControllers(newData);
    setState(() {});
    await widget.onSave(newData);
  }

  Future<void> _removeRow() async {
    if (_data.rows <= 1) return;
    final newData = _data.removeRow();
    _rebuildControllers(newData);
    setState(() {});
    await widget.onSave(newData);
  }

  Future<void> _removeCol() async {
    if (_data.cols <= 1) return;
    final newData = _data.removeCol();
    _rebuildControllers(newData);
    setState(() {});
    await widget.onSave(newData);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    const cellWidth = 100.0;
    const cellHeight = 40.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scrollable table grid ─────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int r = 0; r < _data.rows; r++)
                    Row(
                      children: [
                        for (int c = 0; c < _data.cols; c++)
                          _Cell(
                            key: ValueKey('$r,$c'),
                            controller: _controllers['$r,$c']!,
                            focusNode: _focusNodes['$r,$c']!,
                            width: cellWidth,
                            height: cellHeight,
                            isFirstRow: r == 0,
                            isFirstCol: c == 0,
                            colors: colors,
                            onEditingComplete: () => _saveCell(r, c),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            // ── Row/col controls ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  // Row controls
                  _TableControlButton(
                    icon: Icons.remove_rounded,
                    label: 'Row',
                    colors: colors,
                    enabled: _data.rows > 1,
                    onTap: _removeRow,
                  ),
                  const SizedBox(width: 4),
                  _TableControlButton(
                    icon: Icons.add_rounded,
                    label: 'Row',
                    colors: colors,
                    enabled: true,
                    onTap: _addRow,
                  ),
                  const SizedBox(width: 12),
                  // Col controls
                  _TableControlButton(
                    icon: Icons.remove_rounded,
                    label: 'Col',
                    colors: colors,
                    enabled: _data.cols > 1,
                    onTap: _removeCol,
                  ),
                  const SizedBox(width: 4),
                  _TableControlButton(
                    icon: Icons.add_rounded,
                    label: 'Col',
                    colors: colors,
                    enabled: true,
                    onTap: _addCol,
                  ),
                  const Spacer(),
                  // Delete block
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Individual cell
// ─────────────────────────────────────────────

class _Cell extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double width;
  final double height;
  final bool isFirstRow;
  final bool isFirstCol;
  final WasurenagusaColorScheme colors;
  final VoidCallback onEditingComplete;

  const _Cell({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.width,
    required this.height,
    required this.isFirstRow,
    required this.isFirstCol,
    required this.colors,
    required this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isFirstRow
            ? colors.accent.withValues(alpha: 0.08)
            : colors.surface,
        border: Border(
          top: isFirstRow
              ? BorderSide.none
              : BorderSide(color: colors.divider, width: 0.5),
          left: isFirstCol
              ? BorderSide.none
              : BorderSide(color: colors.divider, width: 0.5),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 13,
          fontWeight: isFirstRow ? FontWeight.w600 : FontWeight.w400,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        textCapitalization: TextCapitalization.sentences,
        onEditingComplete: onEditingComplete,
        onTapOutside: (_) {
          if (focusNode.hasFocus) {
            focusNode.unfocus();
            onEditingComplete();
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Row/col control button
// ─────────────────────────────────────────────

class _TableControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final WasurenagusaColorScheme colors;
  final bool enabled;
  final VoidCallback onTap;

  const _TableControlButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? colors.onSurfaceVariant
        : colors.onSurfaceVariant.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: effectiveColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
