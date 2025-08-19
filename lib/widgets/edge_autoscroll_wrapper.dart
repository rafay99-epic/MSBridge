import 'dart:async';
import 'package:flutter/material.dart';

/// A lightweight wrapper that gently auto-scrolls the provided [ScrollController]
/// when the user's finger/drag pointer is near the top or bottom edge.
///
/// This improves text selection ergonomics by providing a smoother, slower
/// edge-drag scroll, similar to Google Keep.
class EdgeAutoScrollWrapper extends StatefulWidget {
  const EdgeAutoScrollWrapper({
    super.key,
    required this.child,
    this.activationPadding = 36.0,
    this.maxPixelsPerTick = 10.0,
    this.tick = const Duration(milliseconds: 16),
    this.controller,
  });

  /// Optionally supply a specific controller. If null, the nearest
  /// Scrollable's position will be used.
  final ScrollController? controller;
  final Widget child;

  /// Distance from top/bottom edge where auto-scroll activates.
  final double activationPadding;

  /// Max pixels to scroll per tick at the very edge.
  final double maxPixelsPerTick;

  /// How often to apply scroll deltas while active.
  final Duration tick;

  @override
  State<EdgeAutoScrollWrapper> createState() => _EdgeAutoScrollWrapperState();
}

class _EdgeAutoScrollWrapperState extends State<EdgeAutoScrollWrapper> {
  Timer? _autoScrollTimer;
  double? _localPointerDy;
  bool _isPointerDown = false;
  ScrollPosition? _descendantScrollPosition;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _isPointerDown = true;
  }

  void _onPointerUpOrCancel() {
    _isPointerDown = false;
    _localPointerDy = null;
    _stopAutoScroll();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isPointerDown) return;
    final renderBox = context.findRenderObject();
    if (renderBox is! RenderBox) return;
    final local = renderBox.globalToLocal(event.position);
    _localPointerDy = local.dy;
    _maybeStartOrUpdateAutoScroll(renderBox.size.height);
  }

  void _maybeStartOrUpdateAutoScroll(double height) {
    if (_localPointerDy == null) {
      _stopAutoScroll();
      return;
    }

    final double dy = _localPointerDy!;
    final double topZone = widget.activationPadding;
    final double bottomZoneStart = height - widget.activationPadding;

    double pixelsPerTick = 0.0;

    if (dy <= topZone) {
      // Scale speed: closer to the edge => faster (but capped by maxPixelsPerTick)
      final proximity = (topZone - dy).clamp(0.0, topZone) / topZone;
      pixelsPerTick = -widget.maxPixelsPerTick * proximity;
    } else if (dy >= bottomZoneStart) {
      final proximity =
          (dy - bottomZoneStart).clamp(0.0, widget.activationPadding) /
              widget.activationPadding;
      pixelsPerTick = widget.maxPixelsPerTick * proximity;
    }

    if (pixelsPerTick == 0.0) {
      _stopAutoScroll();
    } else {
      _startAutoScroll(pixelsPerTick);
    }
  }

  void _startAutoScroll(double pixelsPerTick) {
    // If already running, just replace the callback speed
    _autoScrollTimer ??=
        Timer.periodic(widget.tick, (_) => _tickScroll(pixelsPerTick));

    // If timer exists, we recreate it with updated speed
    if (_autoScrollTimer != null) {
      _autoScrollTimer!.cancel();
      _autoScrollTimer =
          Timer.periodic(widget.tick, (_) => _tickScroll(pixelsPerTick));
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _tickScroll(double pixelsPerTick) {
    ScrollPosition? position;
    if (widget.controller != null) {
      if (!widget.controller!.hasClients) return;
      position = widget.controller!.position;
    } else {
      position = _descendantScrollPosition;
      if (position == null) return;
    }
    final target = (position.pixels + pixelsPerTick)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (target == position.pixels) return;
    if (widget.controller != null) {
      widget.controller!.jumpTo(target);
    } else {
      position.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final ctx = notification.context;
        if (ctx != null) {
          final state = ctx.findAncestorStateOfType<ScrollableState>();
          if (state != null) {
            _descendantScrollPosition = state.position;
          }
        }
        return false;
      },
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerCancel: (_) => _onPointerUpOrCancel(),
        onPointerUp: (_) => _onPointerUpOrCancel(),
        onPointerMove: _onPointerMove,
        behavior: HitTestBehavior.deferToChild,
        child: widget.child,
      ),
    );
  }
}
