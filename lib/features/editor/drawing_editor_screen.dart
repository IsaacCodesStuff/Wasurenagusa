import 'package:flutter/material.dart';
import '../../core/models/note_block_model.dart';
import '../../theme/wasurenagusa_theme.dart';

class DrawingEditorScreen extends StatefulWidget {
  final DrawingData initialData;

  const DrawingEditorScreen({super.key, required this.initialData});

  @override
  State<DrawingEditorScreen> createState() => _DrawingEditorScreenState();
}

class _DrawingEditorScreenState extends State<DrawingEditorScreen> {
  late List<DrawingStroke> _strokes;
  List<Offset> _currentPoints = [];

  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false;

  static const List<Color> _palette = [
    Colors.black,
    Colors.white,
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFFFCA28),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
  ];

  @override
  void initState() {
    super.initState();
    _strokes = List.from(widget.initialData.strokes);
  }

  void _onPanStart(DragStartDetails details, Size canvasSize) {
    final local = _clamp(details.localPosition, canvasSize);
    setState(() => _currentPoints = [local]);
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    final local = _clamp(details.localPosition, canvasSize);
    setState(() => _currentPoints = [..._currentPoints, local]);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_currentPoints.isEmpty) return;
    setState(() {
      _strokes.add(
        DrawingStroke(
          color: _isEraser ? Colors.white : _selectedColor,
          width: _isEraser ? _strokeWidth * 3 : _strokeWidth,
          points: List.from(_currentPoints),
        ),
      );
      _currentPoints = [];
    });
  }

  Offset _clamp(Offset point, Size size) =>
      Offset(point.dx.clamp(0, size.width), point.dy.clamp(0, size.height));

  void _clear() => setState(() {
    _strokes.clear();
    _currentPoints = [];
  });

  void _save() => Navigator.of(context).pop(DrawingData(strokes: _strokes));
  void _discard() => Navigator.of(context).pop(null);

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.onSurface),
          onPressed: _discard,
        ),
        title: Text(
          'Edit Drawing',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.check_rounded, color: colors.accent),
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Canvas ───────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return GestureDetector(
                        onPanStart: (d) => _onPanStart(d, size),
                        onPanUpdate: (d) => _onPanUpdate(d, size),
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          size: size,
                          painter: _DrawingPainter(
                            strokes: _strokes,
                            currentPoints: _currentPoints,
                            currentColor: _isEraser
                                ? Colors.white
                                : _selectedColor,
                            currentWidth: _isEraser
                                ? _strokeWidth * 3
                                : _strokeWidth,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // ── Toolbar panel ────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.divider),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Row 1: palette left, tools right ──
                Row(
                  children: [
                    // Palette — wraps naturally, no Spacer fighting it
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final color in _palette)
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedColor = color;
                                _isEraser = false;
                              }),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: !_isEraser && _selectedColor == color
                                        ? colors.accent
                                        : colors.divider,
                                    width: !_isEraser && _selectedColor == color
                                        ? 2.5
                                        : 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Eraser toggle
                    GestureDetector(
                      onTap: () => setState(() => _isEraser = !_isEraser),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isEraser
                              ? colors.accent.withValues(alpha: 0.15)
                              : colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isEraser ? colors.accent : colors.divider,
                          ),
                        ),
                        child: Icon(
                          Icons.auto_fix_normal_rounded,
                          size: 18,
                          color: _isEraser
                              ? colors.accent
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Clear button
                    GestureDetector(
                      onTap: _strokes.isEmpty ? null : _clear,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.divider),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: _strokes.isEmpty
                              ? colors.onSurfaceVariant.withValues(alpha: 0.4)
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Row 2: stroke width slider ────────
                Row(
                  children: [
                    Icon(
                      Icons.remove_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 1.0,
                        max: 16.0,
                        activeColor: colors.accent,
                        inactiveColor: colors.divider,
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                    Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────

class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  const _DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.width);
    }
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, currentColor, currentWidth);
    }
  }

  void _drawStroke(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DrawingPainter old) =>
      old.strokes != strokes ||
      old.currentPoints != currentPoints ||
      old.currentColor != currentColor ||
      old.currentWidth != currentWidth;
}
