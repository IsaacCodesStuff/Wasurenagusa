import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/repositories/seiza_repository.dart';
import '../../theme/wasurenagusa_theme.dart';
import '../editor/note_editor_screen.dart';
import '../../widgets/note_options_sheet.dart';
import '../../main.dart' show routeObserver;
import 'dart:math' show cos, sin;

// ─────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────

final _amanogawaNodesProvider =
    StreamProvider.family<List<SeizaNodeWithNote>, int>(
      (ref, notebookId) =>
          ref.watch(seizaRepositoryProvider).watchNodesForNotebook(notebookId),
    );

final _amanogawaEdgesProvider = StreamProvider.family<List<NoteLink>, int>(
  (ref, notebookId) =>
      ref.watch(seizaRepositoryProvider).watchEdgesForNotebook(notebookId),
);

// ─────────────────────────────────────────────
// Amanogawa Screen
// ─────────────────────────────────────────────

class AmanogawaScreen extends ConsumerStatefulWidget {
  final Notebook notebook;
  const AmanogawaScreen({super.key, required this.notebook});

  @override
  ConsumerState<AmanogawaScreen> createState() => _AmanogawaScreenState();
}

class _AmanogawaScreenState extends ConsumerState<AmanogawaScreen>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => _init();

  final Map<int, Offset> _positions = {};
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
    if (mounted) setState(() => _loading = false);
  }

  // Left-to-right layout constants
  static const double _nodeWidth = 160;
  static const double _nodeHeight = 72;
  static const double _rankSpacingX = 260;
  static const double _rankSpacingY = 110;

  // ── Topological rank placement ────────────
  // Assigns each note a column (rank) based on
  // how deep it is in the directed graph.
  Map<int, Offset> _computeFlowPositions(
    List<SeizaNodeWithNote> nodes,
    List<NoteLink> edges,
  ) {
    // Build adjacency: noteId → list of target noteIds
    final outgoing = <int, List<int>>{};
    final incoming = <int, Set<int>>{};
    for (final n in nodes) {
      outgoing[n.note.id] = [];
      incoming[n.note.id] = {};
    }
    for (final e in edges) {
      outgoing[e.sourceNoteId]?.add(e.targetNoteId);
      incoming[e.targetNoteId]?.add(e.sourceNoteId);
    }

    // Assign ranks via longest-path from roots
    final rank = <int, int>{};
    void assignRank(int noteId, int currentRank) {
      if ((rank[noteId] ?? -1) >= currentRank) return;
      rank[noteId] = currentRank;
      for (final target in outgoing[noteId] ?? []) {
        assignRank(target, currentRank + 1);
      }
    }

    // Roots = nodes with no incoming edges
    for (final n in nodes) {
      if ((incoming[n.note.id] ?? {}).isEmpty) {
        assignRank(n.note.id, 0);
      }
    }

    // Any node not yet ranked (isolated or in a cycle) gets rank 0
    for (final n in nodes) {
      rank.putIfAbsent(n.note.id, () => 0);
    }

    // Group by rank
    final byRank = <int, List<int>>{};
    for (final entry in rank.entries) {
      byRank.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    // Compute positions
    const originX = 300.0;
    const originY = 300.0;
    final positions = <int, Offset>{};

    for (final rankEntry in byRank.entries) {
      final col = rankEntry.key;
      final noteIds = rankEntry.value;
      final totalHeight =
          noteIds.length * _nodeHeight +
          (noteIds.length - 1) * (_rankSpacingY - _nodeHeight);
      final startY = originY - totalHeight / 2 + 600;

      for (int i = 0; i < noteIds.length; i++) {
        positions[noteIds[i]] = Offset(
          originX + col * _rankSpacingX,
          startY + i * _rankSpacingY,
        );
      }
    }

    return positions;
  }

  void _applyFlowPositions(
    List<SeizaNodeWithNote> nodes,
    List<NoteLink> edges,
  ) {
    final computed = _computeFlowPositions(nodes, edges);
    for (final entry in computed.entries) {
      // Never overwrite a position the user has manually dragged this session
      if (!_positions.containsKey(entry.key)) {
        _positions[entry.key] = entry.value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = WasurenagusaTheme.of(context).colors;
    final nodesAsync = ref.watch(_amanogawaNodesProvider(widget.notebook.id));
    final edgesAsync = ref.watch(_amanogawaEdgesProvider(widget.notebook.id));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.notebook.icon ?? '📓'),
            const SizedBox(width: 8),
            Text('${widget.notebook.name} — Amanogawa'),
          ],
        ),
        actions: [
          if (_connectMode)
            TextButton(
              onPressed: _cancelConnectMode,
              child: Text('Cancel', style: TextStyle(color: colors.accent)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_amanogawa',
        onPressed: () => _showCreateNoteDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : nodesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (nodes) {
                if (nodes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌌', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          'No notes in this notebook',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add notes to sections to see them here',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return edgesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (edges) {
                    _applyFlowPositions(nodes, edges);
                    return _buildCanvas(context, colors, nodes, edges);
                  },
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
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FlowEdgePainter(
                      nodes: nodes,
                      edges: edges,
                      positions: _positions,
                      sizes: _sizes,
                      colors: colors,
                      connectSourceNoteId: _connectSourceNoteId,
                    ),
                  ),
                ),
                ...nodes.map((n) => _buildNode(context, colors, n, nodes)),
              ],
            ),
          ),
        ),
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
    final pos = _positions[n.note.id] ?? const Offset(300, 300);
    final isConnectSource = _connectSourceNoteId == n.note.id;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onTap: () => _onNodeTap(context, n, nodes),
        onLongPress: () => _onNodeLongPress(context, colors, n),
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (d) => _onNodeDrag(n.note.id, d.delta),
        onPanEnd: (_) {
          _savePosition(n);
          setState(() => _isDragging = false);
        },
        child: _AmanogawaNodeCard(
          noteWithNode: n,
          colors: colors,
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
      if (_connectSourceNoteId == n.note.id) return;
      _createEdge(_connectSourceNoteId!, n.note.id);
      _cancelConnectMode();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: n.note.id)),
    );
  }

  void _onNodeLongPress(
    BuildContext context,
    WasurenagusaColorScheme colors,
    SeizaNodeWithNote n,
  ) => _showNodeOptions(context, colors, n);

  void _onNodeDrag(int noteId, Offset delta) {
    setState(() {
      final current = _positions[noteId] ?? const Offset(300, 300);
      _positions[noteId] = current + delta;
    });
  }

  Future<void> _savePosition(SeizaNodeWithNote n) async {
    final pos = _positions[n.note.id] ?? const Offset(300, 300);
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
  }

  void _cancelConnectMode() {
    setState(() {
      _connectMode = false;
      _connectSourceNoteId = null;
    });
  }

  // ── Node options ──────────────────────────
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
  }

  // ── Create note ───────────────────────────
  Future<void> _showCreateNoteDialog(BuildContext context) async {
    final colors = WasurenagusaTheme.of(context).colors;
    final sections = await ref
        .read(sectionRepositoryProvider)
        .getSectionsByNotebook(widget.notebook.id);

    if (!context.mounted) return;

    if (sections.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'No sections yet',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Create a section in this notebook first before adding notes.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: TextStyle(color: colors.accent)),
            ),
          ],
        ),
      );
      return;
    }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'Add note to section',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...sections.map(
                (section) => ListTile(
                  leading: Icon(
                    Icons.folder_outlined,
                    color: colors.accent,
                    size: 22,
                  ),
                  title: Text(
                    section.name,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final noteId = await ref
                        .read(noteRepositoryProvider)
                        .create(sectionId: section.id);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NoteEditorScreen(noteId: noteId),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Node card — Amanogawa variant (no pin UI)
// ─────────────────────────────────────────────

class _AmanogawaNodeCard extends StatefulWidget {
  final SeizaNodeWithNote noteWithNode;
  final WasurenagusaColorScheme colors;
  final bool isConnectSource;
  final double width;
  final double height;
  final ValueChanged<Size> onSizeKnown;

  const _AmanogawaNodeCard({
    required this.noteWithNode,
    required this.colors,
    required this.isConnectSource,
    required this.width,
    required this.height,
    required this.onSizeKnown,
  });

  @override
  State<_AmanogawaNodeCard> createState() => _AmanogawaNodeCardState();
}

class _AmanogawaNodeCardState extends State<_AmanogawaNodeCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSizeKnown(Size(widget.width, widget.height));
    });
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.noteWithNode.note;
    final isSource = widget.isConnectSource;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSource ? widget.colors.accent : widget.colors.divider,
          width: isSource ? 2.5 : 1,
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
            Text(
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              widget.noteWithNode.section.name,
              style: TextStyle(
                color: widget.colors.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
// Flow edge painter — horizontal, left-to-right
// ─────────────────────────────────────────────

extension _OffsetRotate on Offset {
  Offset rotate(double angle) => Offset(
    dx * cos(angle) - dy * sin(angle),
    dx * sin(angle) + dy * cos(angle),
  );
}

class _FlowEdgePainter extends CustomPainter {
  final List<SeizaNodeWithNote> nodes;
  final List<NoteLink> edges;
  final Map<int, Offset> positions;
  final Map<int, Size> sizes;
  final WasurenagusaColorScheme colors;
  final int? connectSourceNoteId;

  _FlowEdgePainter({
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

      // Exit from right edge of source, enter left edge of target
      final src = Offset(
        sourcePos.dx + sourceSize.width,
        sourcePos.dy + sourceSize.height / 2,
      );
      final tgt = Offset(targetPos.dx, targetPos.dy + targetSize.height / 2);

      final isHighlighted =
          edge.sourceNoteId == connectSourceNoteId ||
          edge.targetNoteId == connectSourceNoteId;

      // Horizontal bezier — control points pull left/right
      final dx = (tgt.dx - src.dx).abs() * 0.5;
      final path = Path()
        ..moveTo(src.dx, src.dy)
        ..cubicTo(src.dx + dx, src.dy, tgt.dx - dx, tgt.dy, tgt.dx, tgt.dy);

      canvas.drawPath(path, isHighlighted ? highlightPaint : paint);
      _drawArrow(
        canvas,
        Offset(tgt.dx - 1, tgt.dy),
        tgt,
        isHighlighted ? highlightPaint : paint,
      );
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 10.0;
    final angle = (to - from).direction;
    final p1 = to - Offset(arrowSize * 0.8, 0).rotate(angle - 0.4);
    final p2 = to - Offset(arrowSize * 0.8, 0).rotate(angle + 0.4);
    canvas.drawLine(to, p1, paint);
    canvas.drawLine(to, p2, paint);
  }

  @override
  bool shouldRepaint(_FlowEdgePainter old) =>
      old.edges != edges ||
      old.positions != positions ||
      old.connectSourceNoteId != connectSourceNoteId;
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
