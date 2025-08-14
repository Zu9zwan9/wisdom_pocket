import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wisdom_pocket/letters/letter_loader.dart';

class _LetterData {
  final String char;
  final Path path;
  final Rect bounds;
  _LetterData(this.char, this.path, this.bounds);
}

class _LetterSegment {
  final Path path; // уже смещенный path буквы
  final double start; // стартовая длина в общей последовательности
  final double end;   // конечная длина
  _LetterSegment(this.path, this.start, this.end);
}

const double _kLetterGap = -3.5; // межбуквенный интервал (базовый)
const double _kSpaceWidth = 55.0; // ширина пробела
const double _kDescenderExtraShift = 0.0; // доп. опускание хвостов
const double _kDescenderPreGapAdjust = -45.0; // коррекция перед хвостовой буквой
// Новые регулируемые значения кернинга:
const double _kAfterFAdjust = -30.0; // добавка (может быть отрицательной) к интервалу ПОСЛЕ f
const double _kBeforeJAdjust = -50.0; // добавка к интервалу ПЕРЕД j (применяется к предыдущей букве)
const double _kAfterLAdjust = -23.0; // добавка к интервалу ПОСЛЕ l
// Упрощённая настройка для буквы f: просто опустить её (после выравнивания низа к baseline)
const double _kFDownShift = 50.0; // положительное значение опустит f вниз
const double _kBeforeFAdjust = -25.0; // добавка к интервалу ПЕРЕД f (применяется к предыдущей букве)
const double _kAfterDAdjust = -20.0; // добавка к интервалу ПОСЛЕ d
const double _kBeforeQAdjust = -5.0; // добавка к интервалу ПЕРЕД q
const double _kAfterBAdjust = -5.0; // добавка к интервалу ПОСЛЕ b

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
  List<_LetterSegment> _segments = [];
  double _originalTotalLength = 0.0; // суммарная длина до трансформации

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Handle animation completion if needed
      }
    });
    _textController = TextEditingController();
  }

  Future<void> _animateText(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _textPath = null;
      _segments = [];
    });

    try {
      final lettersData = <_LetterData>[];

      for (final rune in text.runes) {
        final charStr = String.fromCharCode(rune);
        if (charStr.trim().isEmpty) {
          lettersData.add(_LetterData(' ', Path(), Rect.fromLTWH(0, 0, _kSpaceWidth, 0)));
          continue;
        }
        final letterPath = await loadLetterPath(charStr);
        final bounds = letterPath.getBounds();
        if (bounds.isEmpty) {
          lettersData.add(_LetterData(' ', Path(), Rect.fromLTWH(0, 0, _kSpaceWidth, 0)));
          continue;
        }
        lettersData.add(_LetterData(charStr, letterPath, bounds));
      }

      if (lettersData.isEmpty) {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
        return;
      }

      // Классификация
      bool isLower(String c) => c.isNotEmpty && c.toLowerCase() == c && RegExp(r'[a-z]').hasMatch(c);
      const ascenders = 'bdfhklt';
      const descenders = 'gjpqyz'; // добавлено 'z' как хвостовая по требованию
      const xHeightSet = 'acemnorsuvwxz'; // базовые для x-height
      bool isDescender(String c) => descenders.contains(c.toLowerCase());
      bool isAscender(String c) => ascenders.contains(c.toLowerCase());
      bool isCapital(String c) => c.toUpperCase() == c && RegExp(r'[A-Z]').hasMatch(c);
      bool isXHeight(String c) => xHeightSet.contains(c.toLowerCase());

      // Кандидаты для baseline: x-height (строчные без выносных)
      final xHeightCandidates = lettersData.where((l) => l.char != ' ' && isXHeight(l.char) && !isDescender(l.char));
      Iterable<_LetterData> sourceForBaseline;
      if (xHeightCandidates.isNotEmpty) {
        sourceForBaseline = xHeightCandidates;
      } else {
        final nonDescLower = lettersData.where((l) => l.char != ' ' && isLower(l.char) && !isDescender(l.char));
        sourceForBaseline = nonDescLower.isNotEmpty ? nonDescLower : lettersData.where((l) => l.char != ' ');
      }

      final bottoms = sourceForBaseline.map((l) => l.bounds.bottom).toList()..sort();
      if (bottoms.isEmpty) {
        if (mounted) setState(() { _isLoading = false; });
        return;
      }
      final double baseline = bottoms.length.isOdd
          ? bottoms[bottoms.length ~/ 2]
          : (bottoms[bottoms.length ~/ 2 - 1] + bottoms[bottoms.length ~/ 2]) / 2.0;

      final combinedPath = Path();
      final segments = <_LetterSegment>[];
      double dx = 0.0;
      double cumulative = 0.0;

      bool nextIsDescender(int currentIndex) {
        // Учитываем только следующий непосредственный символ
        final nextIndex = currentIndex + 1;
        if (nextIndex >= lettersData.length) return false;
        final nxt = lettersData[nextIndex];
        if (nxt.char == ' ') return false;
        return isDescender(nxt.char.toLowerCase());
      }

      bool nextIsSpecific(int currentIndex, String target) {
        final nextIndex = currentIndex + 1;
        if (nextIndex >= lettersData.length) return false;
        final nxt = lettersData[nextIndex];
        if (nxt.char == ' ') return false;
        return nxt.char.toLowerCase() == target.toLowerCase();
      }

      for (int i = 0; i < lettersData.length; i++) {
        final l = lettersData[i];
        if (l.char == ' ') {
          dx += l.bounds.width; // пробел без дополнительного kerning
          continue;
        }
        final charLower = l.char.toLowerCase();
        final bool desc = isDescender(charLower);
        final bool isF = charLower == 'f';
        double dy = baseline - l.bounds.bottom; // базовое выравнивание низа к baseline
        if (desc) {
          // Для хвостовых оставляем исходную вертикаль (не поднимаем корпус)
          final descDepth = l.bounds.bottom - baseline;
          dy += descDepth; // dy -> 0
        }
        if (isF) {
          // Простое опускание f (учитывая что она уже выровнена как обычная буква)
          dy += _kFDownShift;
        }
        final shifted = l.path.shift(Offset(dx, dy));
        combinedPath.addPath(shifted, Offset.zero);
        double letterLen = 0.0;
        for (final m in shifted.computeMetrics()) { letterLen += m.length; }
        segments.add(_LetterSegment(shifted, cumulative, cumulative + letterLen));
        cumulative += letterLen;

        // Вычисляем gap с учётом условий
        double gap = _kLetterGap;
        final currentLower = charLower;
        if (currentLower == 'f') {
          gap += _kAfterFAdjust;
        } else if (currentLower == 'l') {
          gap += _kAfterLAdjust;
        } else if (currentLower == 'd') {
          gap += _kAfterDAdjust;
        } else if (currentLower == 'b') {
          gap += _kAfterBAdjust;
        }
        // Особое правило перед 'q' (перекрывает общее descender-сжатие)
        if (nextIsSpecific(i, 'q')) {
          gap += _kBeforeQAdjust;
        } else if (nextIsDescender(i)) {
          gap += _kDescenderPreGapAdjust; // уменьшение перед хвостовой
        }
        if (nextIsSpecific(i, 'j')) {
          gap += _kBeforeJAdjust; // коррекция перед j
        }
        if (nextIsSpecific(i, 'f')) {
          gap += _kBeforeFAdjust; // коррекция перед f
        }
        dx += l.bounds.width + gap;
      }

      if (mounted) {
        setState(() {
          _textPath = combinedPath;
          _segments = segments;
          _originalTotalLength = cumulative;
          _isLoading = false;
        });
        _controller.reset();
        _controller.forward();
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
    // Раньше просто перезапускалась анимация без пересборки пути,
    // поэтому изменения кернинга/констант не применялись.
    if (_textController.text.isNotEmpty) {
      _animateText(_textController.text); // пересобираем путь с новыми константами
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
                              child: Container(
                                child: AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: HandwritingPainter(
                                        path: _textPath!,
                                        progress: _controller.value,
                                        segments: _segments,
                                        originalTotalLength: _originalTotalLength,
                                      ),
                                    );
                                  },
                                ),
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
    required this.segments,
    required this.originalTotalLength,
  });

  final Path path;
  final double progress;
  final List<_LetterSegment> segments;
  final double originalTotalLength;

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

    final paintStroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintFill = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final penPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Используем оригинальную длину (до масштабирования) для определения прогресса
    final currentOriginalLength = originalTotalLength * progress;
    final currentTransformedLength = currentOriginalLength * scale; // масштабируем для сопоставления с transformedPath

    // Заливка завершённых букв: сравниваем по оригинальным длинам
    for (final seg in segments) {
      if (seg.end <= currentOriginalLength) {
        final transformedSeg = seg.path.transform(transform.storage);
        canvas.drawPath(transformedSeg, paintFill);
      }
    }

    // Прорисовка текущего штриха по трансформированному пути
    final metrics = transformedPath.computeMetrics().toList();
    double drawnLength = 0.0;
    for (final metric in metrics) {
      final length = metric.length;
      if (drawnLength + length >= currentTransformedLength) {
        final remaining = currentTransformedLength - drawnLength;
        if (remaining > 0) {
          final extract = metric.extractPath(0, remaining);
          canvas.drawPath(extract, paintStroke);
          final tangent = metric.getTangentForOffset(remaining);
          if (tangent != null) {
            canvas.drawCircle(tangent.position, 5.0, penPaint);
          }
        }
        break;
      } else {
        final extract = metric.extractPath(0, length);
        canvas.drawPath(extract, paintStroke);
        drawnLength += length;
      }
    }
  }

  @override
  bool shouldRepaint(HandwritingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.path != path ||
        oldDelegate.segments != segments ||
        oldDelegate.originalTotalLength != originalTotalLength;
  }
}
