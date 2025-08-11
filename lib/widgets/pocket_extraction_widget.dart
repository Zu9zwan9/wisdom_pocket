import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PocketExtractionWidget extends StatefulWidget {
  final Widget child;
  final double stiffness; // spring stiffness
  final double damping; // spring damping
  final double maxPull; // max pull offset in px
  final VoidCallback? onExtract;
  final bool confetti; // growth experiment toggle

  const PocketExtractionWidget({
    super.key,
    required this.child,
    this.stiffness = 200,
    this.damping = 15,
    this.maxPull = 200,
    this.onExtract,
    this.confetti = false,
  });

  @override
  State<PocketExtractionWidget> createState() => _PocketExtractionWidgetState();
}

class _PocketExtractionWidgetState extends State<PocketExtractionWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _anim;
  double _drag = 0.0; // 0..1
  bool _extracted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target, {bool haptic = false}) async {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      setState(() {
        _drag = target;
      });
      return;
    }
    final from = _drag;
    _controller
      ..duration = const Duration(milliseconds: 260)
      ..reset();
    _anim = Tween<double>(
      begin: from,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.addListener(() {
      setState(() {
        _drag = _anim.value;
      });
    });
    await _controller.forward();
    if (haptic) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final dy = -d.delta.dy; // pulling up increases value
    final delta = dy / widget.maxPull;
    setState(() {
      _drag = (_drag + delta).clamp(0.0, 1.0);
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (_drag > 0.6) {
      _extracted = true;
      _animateTo(1.0, haptic: true);
      widget.onExtract?.call();
    } else {
      _extracted = false;
      _animateTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnims =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final pull = _drag * widget.maxPull;

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: _extracted ? 'Content extracted' : 'Extract content',
        child: GestureDetector(
          onTap: () {
            final target = _extracted ? 0.0 : 1.0;
            _extracted = !_extracted;
            _animateTo(target, haptic: true);
            if (_extracted) widget.onExtract?.call();
          },
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: _PocketPainter(progress: _drag),
            child: SizedBox(
              height: widget.maxPull + 240,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Pocket slot
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x22000000),
                            Color(0x11000000),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Card content being extracted
                  Positioned(
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset(0, -pull),
                      child: _CardShadow(child: widget.child),
                    ),
                  ),
                  if (widget.confetti && _extracted)
                    IgnorePointer(
                      child: AnimatedOpacity(
                        duration: disableAnims
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        opacity: _extracted ? 1 : 0,
                        child: _ConfettiOverlay(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardShadow extends StatelessWidget {
  final Widget child;
  const _CardShadow({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _PocketPainter extends CustomPainter {
  final double progress; // 0..1
  _PocketPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.transparent; // background handled by widgets
    // Optional: draw a subtle pocket notch line for reference
    final notchPaint = Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path();
    final y = size.height - 28;
    final notchWidth = size.width * 0.5;
    final left = (size.width - notchWidth) / 2;
    final right = left + notchWidth;
    path.moveTo(left, y);
    path.quadraticBezierTo(size.width / 2, y + 8 * (1 - progress), right, y);
    canvas.drawPath(path, notchPaint);
  }

  @override
  bool shouldRepaint(covariant _PocketPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(),
        size: const Size(double.infinity, double.infinity),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final math.Random _rng = math.Random(42);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 60; i++) {
      paint.color = Colors.primaries[i % Colors.primaries.length].withOpacity(
        0.25,
      );
      final x = _rng.nextDouble() * size.width;
      final y = _rng.nextDouble() * size.height * 0.7;
      final r = 2 + _rng.nextDouble() * 6;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
