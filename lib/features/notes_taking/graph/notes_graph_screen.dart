import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/features/notes_taking/read/read_note_page.dart';
import 'package:msbridge/widgets/appbar.dart';
import 'package:page_transition/page_transition.dart';

class NotesGraphScreen extends StatefulWidget {
  const NotesGraphScreen({super.key});

  @override
  State<NotesGraphScreen> createState() => _NotesGraphScreenState();
}

class _NotesGraphScreenState extends State<NotesGraphScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final TransformationController _transformController =
      TransformationController();

  List<NoteTakingModel> notes = [];
  List<GraphLink> links = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _loadGraphData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadGraphData() async {
    try {
      final notesBox = await Hive.openBox<NoteTakingModel>('notesBox');
      final allNotes =
          notesBox.values.where((note) => !note.isDeleted).toList();

      final graphLinks = <GraphLink>[];

      for (final note in allNotes) {
        for (final linkedId in note.outgoingLinkIds) {
          final targetNote = allNotes.firstWhere(
            (n) => n.noteId == linkedId,
            orElse: () => allNotes.first, // fallback, should handle better
          );
          if (targetNote.noteId == linkedId) {
            graphLinks.add(GraphLink(
              fromNote: note,
              toNote: targetNote,
            ));
          }
        }
      }

      setState(() {
        notes = allNotes;
        links = graphLinks;
        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      debugPrint('Error loading graph data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(
        backbutton: true,
        title: 'Notes Graph',
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? _buildEmptyState(theme)
              : InteractiveViewer(
                  transformationController: _transformController,
                  boundaryMargin: const EdgeInsets.all(100),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 2,
                    height: MediaQuery.of(context).size.height * 2,
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: GraphPainter(
                            notes: notes,
                            links: links,
                            theme: theme,
                            animationValue: _scaleAnimation.value,
                            onNodeTap: _onNodeTap,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _resetView,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        icon: const Icon(Icons.center_focus_strong),
        label: const Text('Reset View'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notes Found',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create some notes and link them together\nto see the graph visualization',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _onNodeTap(NoteTakingModel note) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: ReadNotePage(note: note),
      ),
    );
  }

  void _resetView() {
    _transformController.value = Matrix4.identity();
  }
}

class GraphLink {
  final NoteTakingModel fromNote;
  final NoteTakingModel toNote;

  GraphLink({required this.fromNote, required this.toNote});
}

class GraphPainter extends CustomPainter {
  final List<NoteTakingModel> notes;
  final List<GraphLink> links;
  final ThemeData theme;
  final double animationValue;
  final Function(NoteTakingModel) onNodeTap;

  GraphPainter({
    required this.notes,
    required this.links,
    required this.theme,
    required this.animationValue,
    required this.onNodeTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (notes.isEmpty) return;

    final positions = _calculateNodePositions(size);

    // Draw links first (behind nodes)
    _drawLinks(canvas, positions);

    // Draw nodes
    _drawNodes(canvas, positions);
  }

  Map<String, Offset> _calculateNodePositions(Size size) {
    final positions = <String, Offset>{};
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    if (notes.length == 1) {
      positions[notes.first.noteId!] = Offset(centerX, centerY);
      return positions;
    }

    // Simple circular layout for now
    final radius = math.min(size.width, size.height) * 0.3;
    for (int i = 0; i < notes.length; i++) {
      final angle = (i / notes.length) * 2 * math.pi;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      positions[notes[i].noteId!] = Offset(x, y);
    }

    return positions;
  }

  void _drawLinks(Canvas canvas, Map<String, Offset> positions) {
    final linkPaint = Paint()
      ..color = theme.colorScheme.outline.withOpacity(0.4 * animationValue)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final link in links) {
      final fromPos = positions[link.fromNote.noteId];
      final toPos = positions[link.toNote.noteId];

      if (fromPos != null && toPos != null) {
        canvas.drawLine(fromPos, toPos, linkPaint);

        // Draw arrow
        _drawArrow(canvas, fromPos, toPos, linkPaint);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 8.0;
    final direction = (to - from).normalized();
    final arrowStart = to - direction * 40; // Start arrow before node

    final arrowEnd1 = arrowStart -
        direction * arrowSize +
        Offset(-direction.dy, direction.dx) * arrowSize * 0.5;
    final arrowEnd2 = arrowStart -
        direction * arrowSize +
        Offset(direction.dy, -direction.dx) * arrowSize * 0.5;

    final arrowPath = Path()
      ..moveTo(arrowStart.dx, arrowStart.dy)
      ..lineTo(arrowEnd1.dx, arrowEnd1.dy)
      ..moveTo(arrowStart.dx, arrowStart.dy)
      ..lineTo(arrowEnd2.dx, arrowEnd2.dy);

    canvas.drawPath(arrowPath, paint);
  }

  void _drawNodes(Canvas canvas, Map<String, Offset> positions) {
    final nodePaint = Paint()
      ..color = theme.colorScheme.primary.withOpacity(animationValue)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final note in notes) {
      final position = positions[note.noteId];
      if (position == null) continue;

      final nodeRadius = 30.0 * animationValue;

      // Draw node circle
      canvas.drawCircle(position, nodeRadius, nodePaint);
      canvas.drawCircle(position, nodeRadius, borderPaint);

      // Draw note title
      final textStyle = TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: note.noteTitle.isEmpty
              ? 'Untitled'
              : (note.noteTitle.length > 15
                  ? '${note.noteTitle.substring(0, 15)}...'
                  : note.noteTitle),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy + nodeRadius + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  @override
  bool hitTest(Offset position) {
    // Enable hit testing for tap detection
    return true;
  }
}

extension on Offset {
  Offset normalized() {
    final length = distance;
    if (length == 0) return Offset.zero;
    return this / length;
  }
}
