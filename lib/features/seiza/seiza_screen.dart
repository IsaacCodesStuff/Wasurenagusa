import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/repositories/seiza_repository.dart';
import '../../theme/wasurenagusa_theme.dart';
import '../editor/note_editor_screen.dart';
import 'dart:math' show cos, sin;
import '../../widgets/note_options_sheet.dart';

// ─────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────

final _seizaNodesProvider = FutureProvider.family<List<SeizaNodeWithNote>, int>(
  (ref, notebookId) =>
      ref.watch(seizaRepositoryProvider).getNodesForNotebook(notebookId),
);

final _seizaEdgesProvider = FutureProvider.family<List<NoteLink>, int>(
  (ref, notebookId) =>
      ref.watch(seizaRepositoryProvider).getEdgesForNotebook(notebookId),
);

// ─────────────────────────────────────────────
// Seiza Screen
// ─────────────────────────────────────────────

class SeizaScreen extends ConsumerStatefulWidget {
  final Notebook notebook;
  const SeizaScreen({super.key, required this.notebook});

  @override
  ConsumerState<SeizaScreen> createState() => _SeizaScreenState();
}

class _SeizaScreenState extends ConsumerState<SeizaScreen> {
  // Node positions held in memory during session; persisted on drag end
  final Map<int, Offset> _positions = {};
  // Node sizes for hit testing
  final Map<int, Size> _sizes = {};

  bool _loading = true;
  bool _connectMode = false;
  int? _connectSourceNoteId;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    await ref
        .read(seizaRepositoryProvider)
        .autoPlaceUnpositioned(widget.notebook.id);
    if (mounted) {
      ref.invalidate(_seizaNodesProvider(widget.notebook.id));
      ref.invalidate(_seizaEdgesProvider(widget.notebook.id));
      setState(() => _loading = false);
    }
  }

  // Grid auto-placement constants
  static const double _nodeWidth = 160;
  static const double _nodeHeight = 72;
  static const double _gridSpacingX = 200;
  static const double _gridSpacingY = 120;
  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;
    final nodesAsync = ref.watch(_seizaNodesProvider(widget.notebook.id));
    final edgesAsync = ref.watch(_seizaEdgesProvider(widget.notebook.id));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.notebook.icon ?? '📓'),
            const SizedBox(width: 8),
            Text('${widget.notebook.name} — Seiza'),
          ],
        ),
        actions: [
          if (_connectMode)
            TextButton(
              onPressed: _cancelConnectMode,
              child: Text('Cancel', style: TextStyle(color: colors.accent)),
            )
          else
            IconButton(
              icon: Icon(Icons.auto_fix_high_rounded, color: colors.onSurface),
              tooltip: 'Auto-place unpositioned notes',
              onPressed: () => _autoPlaceAll(nodesAsync.value ?? []),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : nodesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (nodes) {
                _initializePositions(nodes);
                return edgesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (edges) => _buildCanvas(context, colors, nodes, edges),
                );
              },
            ),
    );
  }

  // ── Canvas ────────────────────────────────
  Widget _buildCanvas(
    BuildContext context,
    WasurenagusaColorScheme colors,
    List<SeizaNodeWithNote> nodes,
    List<NoteLink> edges,
  ) {
    return Stack(
      children: [
        InteractiveViewer(
          panEnabled: !_isDragging,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(400),
          minScale: 0.3,
          maxScale: 2.5,
          child: SizedBox(
            width: 2400,
            height: 2400,
            child: Stack(
              children: [
                // Edge painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: _EdgePainter(
                      nodes: nodes,
                      edges: edges,
                      positions: _positions,
                      sizes: _sizes,
                      colors: colors,
                      connectSourceNoteId: _connectSourceNoteId,
                    ),
                  ),
                ),
                // Node widgets
                ...nodes.map((n) => _buildNode(context, colors, n, nodes)),
              ],
            ),
          ),
        ),
        // Connect mode banner
        if (_connectMode)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ConnectModeBanner(colors: colors),
          ),
      ],
    );
  }

  // ── Node widget ───────────────────────────
  Widget _buildNode(
    BuildContext context,
    WasurenagusaColorScheme colors,
    SeizaNodeWithNote n,
    List<SeizaNodeWithNote> nodes,
  ) {
    final pos = _positions[n.note.id] ?? Offset.zero;
    final isPinned = n.node.isPinned;
    final isConnectSource = _connectSourceNoteId == n.note.id;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onTap: () => _onNodeTap(context, n, nodes),
        onLongPress: () => _onNodeLongPress(context, colors, n),
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) => _onNodeDrag(n.note.id, details.delta),
        onPanEnd: (_) {
          _savePosition(n);
          setState(() => _isDragging = false);
        },
        child: _NodeCard(
          noteWithNode: n,
          colors: colors,
          isPinned: isPinned,
          isConnectSource: isConnectSource,
          width: _nodeWidth,
          height: _nodeHeight,
          onSizeKnown: (size) => _sizes[n.note.id] = size,
        ),
      ),
    );
  }

  // ── Interactions ──────────────────────────

  void _onNodeTap(
    BuildContext context,
    SeizaNodeWithNote n,
    List<SeizaNodeWithNote> nodes,
  ) {
    if (_connectMode) {
      if (_connectSourceNoteId == n.note.id) return; // tapped self
      _createEdge(_connectSourceNoteId!, n.note.id);
      _cancelConnectMode();
      return;
    }
    // Open note editor
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: n.note.id)),
    );
  }

  void _onNodeLongPress(
    BuildContext context,
    WasurenagusaColorScheme colors,
    SeizaNodeWithNote n,
  ) {
    _showNodeOptions(context, colors, n);
  }

  void _onNodeDrag(int noteId, Offset delta) {
    setState(() {
      final current = _positions[noteId] ?? Offset.zero;
      _positions[noteId] = current + delta;
    });
  }

  Future<void> _savePosition(SeizaNodeWithNote n) async {
    final pos = _positions[n.note.id] ?? Offset.zero;
    await ref
        .read(seizaRepositoryProvider)
        .upsertNode(
          noteId: n.note.id,
          notebookId: widget.notebook.id,
          x: pos.dx,
          y: pos.dy,
        );
  }

  Future<void> _createEdge(int sourceId, int targetId) async {
    await ref
        .read(seizaRepositoryProvider)
        .createEdge(sourceNoteId: sourceId, targetNoteId: targetId);
    ref.invalidate(_seizaEdgesProvider(widget.notebook.id));
  }

  void _cancelConnectMode() {
    setState(() {
      _connectMode = false;
      _connectSourceNoteId = null;
    });
  }

  // ── Node options sheet ────────────────────
  void _showNodeOptions(
    BuildContext context,
    WasurenagusaColorScheme colors,
    SeizaNodeWithNote n,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Note title header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  n.note.title.isEmpty ? 'Untitled' : n.note.title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.link_rounded, color: colors.onSurface),
                title: Text(
                  'Connect to…',
                  style: TextStyle(color: colors.onSurface),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _connectMode = true;
                    _connectSourceNoteId = n.note.id;
                  });
                },
              ),
              ListTile(
                leading: Icon(
                  n.node.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: colors.onSurface,
                ),
                title: Text(
                  n.node.isPinned ? 'Unpin node' : 'Pin node',
                  style: TextStyle(color: colors.onSurface),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(seizaRepositoryProvider)
                      .togglePinned(n.node.id, !n.node.isPinned);
                  ref.invalidate(_seizaNodesProvider(widget.notebook.id));
                },
              ),
              ListTile(
                leading: Icon(Icons.link_off_rounded, color: colors.onSurface),
                title: Text(
                  'Remove connections',
                  style: TextStyle(color: colors.onSurface),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _removeNodeEdges(n.note.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeNodeEdges(int noteId) async {
    final edges = await ref
        .read(seizaRepositoryProvider)
        .getEdgesForNotebook(widget.notebook.id);
    for (final edge in edges) {
      if (edge.sourceNoteId == noteId || edge.targetNoteId == noteId) {
        await ref.read(seizaRepositoryProvider).deleteEdge(edge.id);
      }
    }
    ref.invalidate(_seizaEdgesProvider(widget.notebook.id));
  }

  // ── Position initialization ───────────────

  void _initializePositions(List<SeizaNodeWithNote> nodes) {
    for (int i = 0; i < nodes.length; i++) {
      final n = nodes[i];

      // Never overwrite a position that's already in memory
      // (i.e. one the user has dragged this session)
      if (_positions.containsKey(n.note.id)) continue;

      final savedX = n.node.x;
      final savedY = n.node.y;

      if (savedX != 0.0 || savedY != 0.0) {
        _positions[n.note.id] = Offset(savedX, savedY);
      } else {
        final col = i % _columns;
        final row = i ~/ _columns;
        _positions[n.note.id] = Offset(
          300 + col * _gridSpacingX,
          300 + row * _gridSpacingY,
        );
      }
    }
  }

  void _autoPlaceAll(List<SeizaNodeWithNote> nodes) {
    setState(() {
      for (int i = 0; i < nodes.length; i++) {
        final col = i % _columns;
        final row = i ~/ _columns;
        _positions[nodes[i].note.id] = Offset(
          300 + col * _gridSpacingX,
          300 + row * _gridSpacingY,
        );
      }
    });
  }
}

// ─────────────────────────────────────────────
// Node card widget
// ─────────────────────────────────────────────

class _NodeCard extends StatefulWidget {
  final SeizaNodeWithNote noteWithNode;
  final WasurenagusaColorScheme colors;
  final bool isPinned;
  final bool isConnectSource;
  final double width;
  final double height;
  final ValueChanged<Size> onSizeKnown;

  const _NodeCard({
    required this.noteWithNode,
    required this.colors,
    required this.isPinned,
    required this.isConnectSource,
    required this.width,
    required this.height,
    required this.onSizeKnown,
  });

  @override
  State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSizeKnown(Size(widget.width, widget.height));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.noteWithNode.note;
    final isPinned = widget.isPinned;
    final isSource = widget.isConnectSource;

    return Container(
      width: isPinned ? widget.width + 16 : widget.width,
      height: isPinned ? widget.height + 8 : widget.height,
      decoration: BoxDecoration(
        color: widget.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSource
              ? widget.colors.accent
              : isPinned
              ? widget.colors.accent.withValues(alpha: 0.6)
              : widget.colors.divider,
          width: isSource
              ? 2.5
              : isPinned
              ? 2
              : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Untitled' : note.title,
                    style: TextStyle(
                      color: note.title.isEmpty
                          ? widget.colors.onSurfaceVariant
                          : widget.colors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontStyle: note.title.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.push_pin_rounded,
                      color: widget.colors.accent,
                      size: 13,
                    ),
                  ),
              ],
            ),
            if (note.colorTag != null) ...[
              const SizedBox(height: 6),
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: kColorTags[note.colorTag],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Edge painter
// ─────────────────────────────────────────────

extension _OffsetRotate on Offset {
  Offset rotate(double angle) => Offset(
    dx * cos(angle) - dy * sin(angle),
    dx * sin(angle) + dy * cos(angle),
  );
}

class _EdgePainter extends CustomPainter {
  final List<SeizaNodeWithNote> nodes;
  final List<NoteLink> edges;
  final Map<int, Offset> positions;
  final Map<int, Size> sizes;
  final WasurenagusaColorScheme colors;
  final int? connectSourceNoteId;

  _EdgePainter({
    required this.nodes,
    required this.edges,
    required this.positions,
    required this.sizes,
    required this.colors,
    this.connectSourceNoteId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.accent.withValues(alpha: 0.45)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = colors.accent
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final edge in edges) {
      final sourcePos = positions[edge.sourceNoteId];
      final targetPos = positions[edge.targetNoteId];
      if (sourcePos == null || targetPos == null) continue;

      final sourceSize = sizes[edge.sourceNoteId] ?? const Size(160, 72);
      final targetSize = sizes[edge.targetNoteId] ?? const Size(160, 72);

      final src = Offset(
        sourcePos.dx + sourceSize.width / 2,
        sourcePos.dy + sourceSize.height / 2,
      );
      final tgt = Offset(
        targetPos.dx + targetSize.width / 2,
        targetPos.dy + targetSize.height / 2,
      );

      final isHighlighted =
          edge.sourceNoteId == connectSourceNoteId ||
          edge.targetNoteId == connectSourceNoteId;

      // Bezier curve
      final controlOffset = Offset(
        (tgt.dx - src.dx) * 0.4,
        (tgt.dy - src.dy) * 0.1,
      );
      final path = Path()
        ..moveTo(src.dx, src.dy)
        ..cubicTo(
          src.dx + controlOffset.dx,
          src.dy + controlOffset.dy,
          tgt.dx - controlOffset.dx,
          tgt.dy - controlOffset.dy,
          tgt.dx,
          tgt.dy,
        );

      canvas.drawPath(path, isHighlighted ? highlightPaint : paint);

      // Arrowhead at target
      _drawArrow(canvas, src, tgt, isHighlighted ? highlightPaint : paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 10.0;
    final angle = (to - from).direction;
    final p1 =
        to - Offset(arrowSize * 0.8 * (1 + 0.5 * 0), 0).rotate(angle - 0.4);
    final p2 = to - Offset(arrowSize * 0.8, 0).rotate(angle + 0.4);

    canvas.drawLine(to, p1, paint);
    canvas.drawLine(to, p2, paint);
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) =>
      oldDelegate.edges != edges ||
      oldDelegate.positions != positions ||
      oldDelegate.connectSourceNoteId != connectSourceNoteId;
}

// ─────────────────────────────────────────────
// Connect mode banner
// ─────────────────────────────────────────────

class _ConnectModeBanner extends StatelessWidget {
  final WasurenagusaColorScheme colors;
  const _ConnectModeBanner({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.accent.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.link_rounded, color: colors.accent, size: 18),
          const SizedBox(width: 10),
          Text(
            'Tap a node to connect it',
            style: TextStyle(
              color: colors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
