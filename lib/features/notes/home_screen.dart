import 'package:flutter/material.dart';
import '../../theme/wasurenagusa_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showNoteTypePicker(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 16),
                  child: Text(
                    'New note',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _NoteTypeOption(
                  icon: Icons.text_fields_rounded,
                  label: 'Text note',
                  description: 'Plain writing, headings, paragraphs',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context);
                    // Create a note without a section (home note)
                    // then open editor
                  },
                ),
                _NoteTypeOption(
                  icon: Icons.check_box_outlined,
                  label: 'Checklist',
                  description: 'Tasks, to-dos, shopping lists',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context);
                    // Create a note without a section (home note)
                    // then open editor
                  },
                ),
                _NoteTypeOption(
                  icon: Icons.format_list_numbered_rounded,
                  label: 'Numbered list',
                  description: 'Ordered steps or ranked items',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context);
                    // Create a note without a section (home note)
                    // then open editor
                  },
                ),
                _NoteTypeOption(
                  icon: Icons.draw_outlined,
                  label: 'Drawing',
                  description: 'Sketches, diagrams, handwriting',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context);
                    // Create a note without a section (home note)
                    // then open editor
                  },
                ),
                _NoteTypeOption(
                  icon: Icons.image_outlined,
                  label: 'Image',
                  description: 'Photos and attachments',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: open editor with image block
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Wasurenagusa')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_home',
        onPressed: () => _showNoteTypePicker(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: const Center(child: Text('Home')),
    );
  }
}

class _NoteTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final WasurenagusaColorScheme colors;
  final VoidCallback onTap;

  const _NoteTypeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.accent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
