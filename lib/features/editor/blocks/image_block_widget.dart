import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/note_block_model.dart';
import '../../../core/services/media_service.dart';
import '../../../theme/wasurenagusa_theme.dart';
import '../camera_screen.dart';

const _uuid = Uuid();

class ImageBlockWidget extends StatefulWidget {
  final NoteBlockModel block;
  final WasurenagusaColorScheme colors;
  final VoidCallback onDelete;
  final Future<void> Function(ImageData) onSave;

  const ImageBlockWidget({
    super.key,
    required this.block,
    required this.colors,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<ImageBlockWidget> createState() => _ImageBlockWidgetState();
}

class _ImageBlockWidgetState extends State<ImageBlockWidget> {
  final _picker = ImagePicker();
  bool _loading = false;
  String? _resolvedPath;

  @override
  void initState() {
    super.initState();
    _resolveExisting();
  }

  Future<void> _resolveExisting() async {
    final imageData = widget.block.imageData;
    if (imageData == null) return;
    final path = await MediaService.instance.resolve(imageData.filename);
    if (mounted) setState(() => _resolvedPath = path);
  }

  Future<void> _pickFromGallery() async {
    Navigator.pop(context); // close bottom sheet
    setState(() => _loading = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final ext = picked.path.split('.').last.toLowerCase();
      final filename = '${_uuid.v4()}.$ext';
      await MediaService.instance.copyInto(File(picked.path), filename);
      final resolvedPath = await MediaService.instance.resolve(filename);

      await widget.onSave(ImageData(filename: filename));
      if (mounted) setState(() => _resolvedPath = resolvedPath);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFromCamera() async {
    Navigator.pop(context); // close bottom sheet
    final path = await CameraScreen.show(context);
    if (path == null) return;

    setState(() => _loading = true);
    try {
      final filename = '${_uuid.v4()}.jpg';
      await MediaService.instance.copyInto(File(path), filename);
      final resolvedPath = await MediaService.instance.resolve(filename);

      await widget.onSave(ImageData(filename: filename));
      if (mounted) setState(() => _resolvedPath = resolvedPath);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSourcePicker() {
    final colors = widget.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Add image',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _SourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                colors: colors,
                onTap: _pickFromGallery,
              ),
              const SizedBox(height: 8),
              _SourceOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                colors: colors,
                onTap: _pickFromCamera,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final imageData = widget.block.imageData;

    // Empty state
    if (imageData == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: _showSourcePicker,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.image_outlined, color: colors.accent, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Tap to add image',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Loading state
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: CircularProgressIndicator(color: colors.accent)),
        ),
      );
    }

    // Image display state
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _resolvedPath != null
                ? Image.file(
                    File(_resolvedPath!),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 200,
                    color: colors.surfaceVariant,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: colors.onSurfaceVariant,
                        size: 40,
                      ),
                    ),
                  ),
          ),
          // Replace button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _showSourcePicker,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Source picker option row
// ─────────────────────────────────────────────

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final WasurenagusaColorScheme colors;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: colors.accent, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
