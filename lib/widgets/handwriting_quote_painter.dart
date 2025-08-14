import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../letters/letter_loader.dart';

/// Builds a single-line path for given text with simple spacing and baseline alignment.
Future<Path> buildTextPath(String text, {double letterGap = 8.0}) async {
  final path = Path();
  double dx = 0.0;
  // Collect letter bounds to compute baseline (median bottom of non-descenders)
  final letters = <_Glyph>[];
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (ch.trim().isEmpty) {
      dx += letterGap * 2; // space width
      continue;
    }
    final letterPath = await loadLetterPath(ch);
    final bounds = letterPath.getBounds();
    if (bounds.isEmpty) {
      dx += letterGap; // skip unknown
      continue;
    }
    letters.add(_Glyph(ch, letterPath.shift(Offset(dx, 0)), bounds.shift(Offset(dx, 0))));
    dx += bounds.width + letterGap;
  }
  if (letters.isEmpty) return path;
  final nonDesc = letters.where((g) => !_descenders.contains(g.char.toLowerCase())).toList();
  final source = nonDesc.isNotEmpty ? nonDesc : letters;
  final bottoms = source.map((g) => g.bounds.bottom).toList()..sort();
  final baseline = bottoms.length.isOdd
      ? bottoms[bottoms.length ~/ 2]
      : (bottoms[bottoms.length ~/ 2 - 1] + bottoms[bottoms.length ~/ 2]) / 2.0;
  for (final g in letters) {
    final isDesc = _descenders.contains(g.char.toLowerCase());
    double dy = baseline - g.bounds.bottom;
    if (isDesc) {
      dy += g.bounds.bottom - baseline; // keep tail
    }
    path.addPath(g.path.shift(Offset(0, dy)), Offset.zero);
  }
  return path;
}

/// Combines two paths vertically with spacing.
Path stackPaths(Path top, Path bottom, double spacing) {
  final tb = top.getBounds();
  final bb = bottom.getBounds();
  final dy = tb.bottom - bb.top + spacing;
  final combined = Path();
  combined.addPath(top, Offset.zero);
  combined.addPath(bottom, Offset(0, dy));
  return combined;
}

/// A painter that first animates the quote path, then the author path.
class QuoteHandwritingPainter extends CustomPainter {
  QuoteHandwritingPainter({
    required this.quotePath,
    required this.authorPath,
    required this.progress,
    this.strokeWidth = 2.0,
    this.padding = 16.0,
  }) {
    _init();
  }

  final Path quotePath;
  final Path authorPath;
  final double progress; // 0..1 overall
  final double strokeWidth;
  final double padding;

  late final double _quoteLen;
  late final double _authorLen;
  late final double _totalLen;

  void _init() {
    _quoteLen = _lengthOf(quotePath);
    _authorLen = _lengthOf(authorPath);
    _totalLen = _quoteLen + _authorLen;
  }

  double _lengthOf(Path p) {
    double len = 0.0;
    for (final m in p.computeMetrics()) {
      len += m.length;
    }
    return len;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_totalLen == 0) return;

    // Fit combined path into size with padding.
    final combined = Path();
    combined.addPath(quotePath, Offset.zero);
    // Position author under quote with spacing (already pre-stacked externally or we restack here)
    final authorShifted = _shiftAuthorBelow();
    combined.addPath(authorShifted, Offset.zero);
    final bounds = combined.getBounds();
    final scale = min((size.width - padding * 2) / bounds.width, (size.height - padding * 2) / bounds.height);
    final tx = (size.width - bounds.width * scale) / 2 - bounds.left * scale;
    final ty = (size.height - bounds.height * scale) / 2 - bounds.top * scale;
    final matrix = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(scale, scale);
    final transformedQuote = quotePath.transform(matrix.storage);
    final transformedAuthor = authorShifted.transform(matrix.storage);

    final paintStroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final paintFill = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final currentLen = _totalLen * progress;

    // Draw filled quote letters that are complete (simple approach: once quote fully done fill it all).
    if (currentLen >= _quoteLen) {
      canvas.drawPath(transformedQuote, paintFill);
    }

    if (currentLen <= _quoteLen) {
      _drawPartial(canvas, transformedQuote, currentLen, paintStroke);
    } else {
      canvas.drawPath(transformedQuote, paintStroke);
      final authorProgress = currentLen - _quoteLen;
      if (authorProgress < _authorLen) {
        _drawPartial(canvas, transformedAuthor, authorProgress, paintStroke);
      } else {
        canvas.drawPath(transformedAuthor, paintStroke);
        canvas.drawPath(transformedAuthor, paintFill);
      }
    }
  }

  Path _shiftAuthorBelow() {
    final qb = quotePath.getBounds();
    final ab = authorPath.getBounds();
    final spacing = 28.0; // vertical space between quote and author
    final dy = qb.bottom - ab.top + spacing;
    return authorPath.shift(Offset(0, dy));
  }

  void _drawPartial(Canvas canvas, Path path, double length, Paint paint) {
    double drawn = 0.0;
    for (final metric in path.computeMetrics()) {
      final l = metric.length;
      if (drawn + l >= length) {
        final remain = length - drawn;
        if (remain > 0) {
          final part = metric.extractPath(0, remain);
            canvas.drawPath(part, paint);
        }
        break;
      } else {
        final full = metric.extractPath(0, l);
        canvas.drawPath(full, paint);
        drawn += l;
      }
    }
  }

  @override
  bool shouldRepaint(covariant QuoteHandwritingPainter old) => old.progress != progress || old.quotePath != quotePath || old.authorPath != authorPath;
}

class _Glyph {
  final String char;
  final Path path;
  final Rect bounds;
  _Glyph(this.char, this.path, this.bounds);
}

const Set<String> _descenders = {'g','j','p','q','y','z'};

/// Разбиение текста на 3 строки (примерно по балансу длины)
List<String> splitIntoThreeLines(String text) {
  final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return ['', '', ''];
  final words = cleaned.split(' ');
  if (words.length <= 3) {
    return [
      words.isNotEmpty ? words[0] : '',
      words.length > 1 ? words[1] : '',
      words.length > 2 ? words[2] : '',
    ];
  }
  final totalLen = cleaned.length;
  final target = totalLen / 3;
  final lines = <String>[];
  var current = StringBuffer();
  double accumulatedTarget = target;
  for (final w in words) {
    final tentative = current.isEmpty ? w : '${current.toString()} $w';
    if (tentative.length > accumulatedTarget && lines.length < 2) {
      if (current.isNotEmpty) {
        lines.add(current.toString());
        current = StringBuffer(w);
        accumulatedTarget += target;
      } else {
        lines.add(w);
      }
    } else {
      current..write(current.isEmpty ? w : ' $w');
    }
  }
  if (current.isNotEmpty && lines.length < 3) lines.add(current.toString());
  while (lines.length < 3) lines.add('');
  if (lines.length > 3) {
    final merged = lines.sublist(2).join(' ');
    lines
      ..removeRange(2, lines.length)
      ..add(merged);
  }
  return lines.take(3).toList();
}

/// Строит пути для 3 строк.
Future<List<Path>> buildMultilineQuotePaths(String text, {double letterGap = 8.0}) async {
  final parts = splitIntoThreeLines(text);
  final result = <Path>[];
  for (final p in parts) {
    if (p.trim().isEmpty) {
      result.add(Path());
    } else {
      result.add(await buildTextPath(p, letterGap: letterGap));
    }
  }
  return result;
}

class QuoteHandwritingMultilinePainter extends CustomPainter {
  QuoteHandwritingMultilinePainter({
    required this.quoteLinePaths,
    required this.authorPath,
    required this.progress,
    this.strokeWidth = 2.0,
    this.padding = 16.0,
    this.lineSpacing = 28.0,
  }) { _init(); }

  final List<Path> quoteLinePaths; // 3 строки
  final Path authorPath;
  final double progress; // 0..1
  final double strokeWidth;
  final double padding;
  final double lineSpacing;

  late final List<double> _lineLengths;
  late final double _authorLen;
  late final double _totalQuoteLen;
  late final double _totalLen;

  void _init() {
    _lineLengths = quoteLinePaths.map(_lengthOf).toList();
    _authorLen = _lengthOf(authorPath);
    _totalQuoteLen = _lineLengths.fold(0.0, (a, b) => a + b);
    _totalLen = _totalQuoteLen + _authorLen;
  }

  double _lengthOf(Path p) {
    double len = 0.0;
    for (final m in p.computeMetrics()) { len += m.length; }
    return len;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_totalLen == 0) return;

    // Стекуем строки + автора (автор под последней строкой с доп. отступом)
    final stackedQuoteLines = <Path>[];
    double currentY = 0.0;
    for (final path in quoteLinePaths) {
      final b = path.getBounds();
      final shifted = path.shift(Offset(0, currentY - b.top));
      stackedQuoteLines.add(shifted);
      currentY += b.height + lineSpacing;
    }
    final quoteHeight = currentY - lineSpacing; // высота блока цитаты
    final ab = authorPath.getBounds();
    final authorShifted = authorPath.shift(Offset(0, quoteHeight + 1.2 * lineSpacing - ab.top));

    // Комбинированный для вычисления масштаба
    final combined = Path();
    for (final p in stackedQuoteLines) { combined.addPath(p, Offset.zero); }
    combined.addPath(authorShifted, Offset.zero);
    final bounds = combined.getBounds();
    final scale = min((size.width - padding * 2) / bounds.width, (size.height - padding * 2) / bounds.height);
    final tx = (size.width - bounds.width * scale) / 2 - bounds.left * scale;
    final ty = (size.height - bounds.height * scale) / 2 - bounds.top * scale;
    final m4 = Matrix4.identity()..translate(tx, ty)..scale(scale, scale);

    final transformedLines = stackedQuoteLines.map((p) => p.transform(m4.storage)).toList();
    final transformedAuthor = authorShifted.transform(m4.storage);

    final paintStroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final paintFill = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final currentLen = _totalLen * progress;

    double remaining = currentLen;

    // Рисуем строки по очереди (stroke). После полной прорисовки всех строк — заливаем их.
    final fullyDrawnQuote = remaining >= _totalQuoteLen;

    for (int i = 0; i < transformedLines.length; i++) {
      final linePath = transformedLines[i];
      final len = _lineLengths[i];
      if (len == 0) continue; // пустая строка
      if (remaining <= 0) break;
      if (remaining < len) {
        _drawPartial(canvas, linePath, remaining, paintStroke);
        remaining = 0;
        break;
      } else {
        canvas.drawPath(linePath, paintStroke);
        remaining -= len;
      }
    }

    if (fullyDrawnQuote) {
      // Все строки целиком — заливаем
      for (final lp in transformedLines) { canvas.drawPath(lp, paintFill); }
      final authorProgress = currentLen - _totalQuoteLen;
      if (authorProgress < _authorLen) {
        _drawPartial(canvas, transformedAuthor, authorProgress, paintStroke);
      } else {
        canvas.drawPath(transformedAuthor, paintStroke);
        canvas.drawPath(transformedAuthor, paintFill);
      }
    }
  }

  void _drawPartial(Canvas canvas, Path path, double length, Paint paint) {
    double drawn = 0.0;
    for (final metric in path.computeMetrics()) {
      final l = metric.length;
      if (drawn + l >= length) {
        final remain = length - drawn;
        if (remain > 0) {
          final part = metric.extractPath(0, remain);
          canvas.drawPath(part, paint);
        }
        break;
      } else {
        canvas.drawPath(metric.extractPath(0, l), paint);
        drawn += l;
      }
    }
  }

  @override
  bool shouldRepaint(covariant QuoteHandwritingMultilinePainter old) =>
      old.progress != progress || old.quoteLinePaths != quoteLinePaths || old.authorPath != authorPath;
}
