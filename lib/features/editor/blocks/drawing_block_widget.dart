import 'package:flutter/material.dart';
import '../../../../core/models/note_block_model.dart';
import '../../../../theme/wasurenagusa_theme.dart';

class DrawingBlockWidget extends StatelessWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final VoidCallback onDelete;

  const DrawingBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.draw_outlined, color: colors.onSurfaceVariant, size: 36),
            const SizedBox(height: 12),
            Text(
              'Drawing canvas',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coming in v0.3.0',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
