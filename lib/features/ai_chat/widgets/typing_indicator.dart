// Flutter imports:
import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key, required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(6),
              ),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _TypingDot(index: 0),
                SizedBox(width: 8),
                _TypingDot(index: 1),
                SizedBox(width: 8),
                _TypingDot(index: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.index});
  final int index;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    // Optimized controller with shorter duration for better performance
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final double start = (0.15 * widget.index).clamp(0.0, 0.6);
    final double end = (start + 0.6).clamp(0.0, 1.0);
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final double t = _curve.value; // 0..1
        final double opacity = 0.4 + (0.6 * t);
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
