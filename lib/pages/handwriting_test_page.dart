import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wisdom_pocket/letters/letter_loader.dart';

class HandwritingTestPage extends StatefulWidget {
  const HandwritingTestPage({super.key});

  @override
  State<HandwritingTestPage> createState() => _HandwritingTestPageState();
}

class _HandwritingTestPageState extends State<HandwritingTestPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final TextEditingController _textController;
  Path? _textPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _textController = TextEditingController();
  }

  Future<void> _animateText(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _textPath = null;
    });

    try {
      final combinedPath = Path();
      var dx = 0.0;

      for (final char in text.runes) {
        final charStr = String.fromCharCode(char);
        if (charStr.trim().isEmpty) {
          dx += 20.0; // Add space for non-alphabetic characters
          continue;
        }

        final letterPath = await loadLetterPath(charStr);
        if (letterPath.getBounds().isEmpty) {
          dx += 20.0; // Add space for unsupported characters
          continue;
        }

        final bounds = letterPath.getBounds();
        combinedPath.addPath(letterPath, Offset(dx, 0));
        dx += bounds.width + 10; // Add some spacing between letters
      }

      if (mounted) {
        setState(() {
          _textPath = combinedPath;
          _isLoading = false;
        });
        _controller.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('Failed to load text path: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _replay() {
    if (_textController.text.isNotEmpty) {
      _animateText(_textController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Handwriting Test'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _replay,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _textController,
                placeholder: 'Enter text to animate',
                onSubmitted: _animateText,
                textInputAction: TextInputAction.go,
                suffix: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: const Icon(CupertinoIcons.play_arrow),
                  onPressed: () => _animateText(_textController.text),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : _textPath == null
                        ? const Center(
                            child: Text('Enter text and press play.'))
                        : Center(
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: HandwritingPainter(
                                      path: _textPath!,
                                      progress: _controller.value,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HandwritingPainter extends CustomPainter {
  HandwritingPainter({
    required this.path,
    required this.progress,
  });

  final Path path;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.getBounds().isEmpty) return;

    final bounds = path.getBounds();
    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final scale = min(scaleX, scaleY) * 0.9;

    final transform = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale, scale)
      ..translate(-bounds.center.dx, -bounds.center.dy);

    final transformedPath = path.transform(transform.storage);

    final paint = Paint()
      ..color(Colors.black)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final penPaint = Paint()
      ..color(Colors.red)
      ..style = PaintingStyle.fill;

    final metrics = transformedPath.computeMetrics();
    var totalLength = 0.0;
    for (final metric in metrics) {
      totalLength += metric.length;
    }

    final currentLength = totalLength * progress;
    var drawnLength = 0.0;

    for (final metric in metrics) {
      final length = metric.length;
      if (drawnLength + length >= currentLength) {
        final remaining = currentLength - drawnLength;
        final extract = metric.extractPath(0, remaining);
        canvas.drawPath(extract, paint);

        final tangent = metric.getTangentForOffset(remaining);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 5.0, penPaint);
        }
        break;
      } else {
        final extract = metric.extractPath(0, length);
        canvas.drawPath(extract, paint);
        drawnLength += length;
      }
    }
  }

  @override
  bool shouldRepaint(HandwritingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.path != path;
  }
}
