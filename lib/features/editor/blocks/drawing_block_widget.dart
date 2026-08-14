import 'package:flutter/material.dart';
import '../../../core/models/note_block_model.dart';
import '../../../theme/wasurenagusa_theme.dart';
import '../drawing_editor_screen.dart';

class DrawingBlockWidget extends StatelessWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final VoidCallback onDelete;
  final Future<void> Function(DrawingData) onSave;

  const DrawingBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.onDelete,
    required this.onSave,
  });

  Future<void> _openEditor(BuildContext context) async {
    final result = await Navigator.of(context).push<DrawingData>(
      MaterialPageRoute(
        builder: (_) => DrawingEditorScreen(
          initialData: block.drawingData ?? DrawingData.empty(),
        ),
      ),
    );
    if (result != null) {
      await onSave(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = block.drawingData ?? DrawingData.empty();
    final isEmpty = data.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Canvas view
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.draw_outlined,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Edit Drawing" to start',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomPaint(
                      painter: _ViewPainter(strokes: data.strokes),
                      size: Size.infinite,
                    ),
            ),
          ),

          // "Edit Drawing" pill
          Positioned(
            bottom: 12,
            child: GestureDetector(
              onTap: () => _openEditor(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Edit Drawing',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

class _ViewPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  const _ViewPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }

      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length - 1; i++) {
        final mid = Offset(
          (stroke.points[i].dx + stroke.points[i + 1].dx) / 2,
          (stroke.points[i].dy + stroke.points[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(
          stroke.points[i].dx,
          stroke.points[i].dy,
          mid.dx,
          mid.dy,
        );
      }
      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ViewPainter old) => old.strokes != strokes;
}
