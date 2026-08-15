import 'dart:async';
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
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _data = widget.block.tableData ?? TableData.empty();
    _initControllers();
  }

  void _initControllers() {
    for (int r = 0; r < _data.rows; r++) {
      for (int c = 0; c < _data.cols; c++) {
        _createCell(r, c, _data.cells[r][c]);
      }
    }
  }

  void _createCell(int r, int c, String initialText) {
    final key = '$r,$c';
    final tc = TextEditingController(text: initialText);
    final fn = FocusNode();
    tc.addListener(() => _onCellChanged(r, c));
    _controllers[key] = tc;
    _focusNodes[key] = fn;
  }

  void _onCellChanged(int row, int col) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _saveAllCells();
    });
  }

  Future<void> _saveAllCells() async {
    var newData = _data;
    for (int r = 0; r < _data.rows; r++) {
      for (int c = 0; c < _data.cols; c++) {
        final key = '$r,$c';
        final value = _controllers[key]?.text ?? '';
        newData = newData.withCell(r, c, value);
      }
    }
    _data = newData;
    await widget.onSave(newData);
  }

  void _disposeControllers() {
    for (final tc in _controllers.values) {
      tc.dispose();
    }
    for (final fn in _focusNodes.values) {
      fn.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
  }

  Future<void> _rebuildWith(TableData newData) async {
    // Flush current text into newData before rebuilding
    // so we don't lose content that was typed but not yet saved
    var flushed = newData;
    for (int r = 0; r < _data.rows && r < newData.rows; r++) {
      for (int c = 0; c < _data.cols && c < newData.cols; c++) {
        final key = '$r,$c';
        final value = _controllers[key]?.text ?? '';
        flushed = flushed.withCell(r, c, value);
      }
    }
    _disposeControllers();
    _data = flushed;
    for (int r = 0; r < _data.rows; r++) {
      for (int c = 0; c < _data.cols; c++) {
        _createCell(r, c, _data.cells[r][c]);
      }
    }
    setState(() {});
    await widget.onSave(_data);
  }

  Future<void> _addRow() => _rebuildWith(_data.addRow());
  Future<void> _addCol() => _rebuildWith(_data.addCol());
  Future<void> _removeRow() async {
    if (_data.rows <= 1) return;
    await _rebuildWith(_data.removeRow());
  }

  Future<void> _removeCol() async {
    if (_data.cols <= 1) return;
    await _rebuildWith(_data.removeCol());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _disposeControllers();
    super.dispose();
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

  const _Cell({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.width,
    required this.height,
    required this.isFirstRow,
    required this.isFirstCol,
    required this.colors,
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
