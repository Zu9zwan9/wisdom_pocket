import 'package:wisdom_pocket/letters/letter_loader.dart';
import 'dart:ui';

// Публичные константы кернинга и правил (были в handwriting_test_page)
const double kLetterGap = -3.5; // базовый межбуквенный интервал
const double kSpaceWidth = 55.0; // ширина пробела
const double kDescenderExtraShift = 0.0; // доп. вертикальный сдвиг хвостов (зарезервировано)
const double kDescenderPreGapAdjust = -45.0; // сжатие перед хвостовой буквой
const double kAfterFAdjust = -30.0; // корректировка после f
const double kBeforeJAdjust = -50.0; // корректировка перед j
const double kAfterLAdjust = -23.0; // корректировка после l
const double kFDownShift = 50.0; // опустить f
const double kBeforeFAdjust = -25.0; // корректировка перед f
const double kAfterDAdjust = -20.0; // корректировка после d
const double kBeforeQAdjust = -5.0; // корректировка перед q
const double kAfterBAdjust = -5.0; // корректировка после b

// Наборы классификаций
const String _ascenders = 'bdfhklt';
const String _descenders = 'gjpqyz'; // по требованию: z ����оже хвостовая
const String _xHeightSet = 'acemnorsuvwxz';

bool _isLower(String c) => c.isNotEmpty && c.toLowerCase() == c && RegExp(r'[a-z]').hasMatch(c);
bool _isDescender(String c) => _descenders.contains(c.toLowerCase());
bool _isAscender(String c) => _ascenders.contains(c.toLowerCase());
bool _isXHeight(String c) => _xHeightSet.contains(c.toLowerCase());

class HandwritingPathResult {
  final Path path;
  HandwritingPathResult(this.path);
}

/// Строит Path текста с расширенными правилами кернинга и базовой линией, без сегментов.
Future<HandwritingPathResult> buildAdvancedTextPath(String text,{double? baseGapOverride}) async {
  final lettersData = <_TmpLetter>[];
  for (final rune in text.runes) {
    final charStr = String.fromCharCode(rune);
    if (charStr.trim().isEmpty) {
      lettersData.add(_TmpLetter(' ', Path(), Rect.fromLTWH(0,0,kSpaceWidth,0)));
      continue;
    }
    final letterPath = await loadLetterPath(charStr);
    final bounds = letterPath.getBounds();
    if (bounds.isEmpty) {
      lettersData.add(_TmpLetter(' ', Path(), Rect.fromLTWH(0,0,kSpaceWidth,0)));
      continue;
    }
    lettersData.add(_TmpLetter(charStr, letterPath, bounds));
  }
  if (lettersData.isEmpty) return HandwritingPathResult(Path());

  // baseline candidates
  final xHeightCandidates = lettersData.where((l)=> l.char!=' ' && _isXHeight(l.char) && !_isDescender(l.char));
  Iterable<_TmpLetter> sourceForBaseline;
  if (xHeightCandidates.isNotEmpty) {
    sourceForBaseline = xHeightCandidates;
  } else {
    final nonDescLower = lettersData.where((l)=> l.char!=' ' && _isLower(l.char) && !_isDescender(l.char));
    sourceForBaseline = nonDescLower.isNotEmpty ? nonDescLower : lettersData.where((l)=> l.char!=' ');
  }
  final bottoms = sourceForBaseline.map((l)=> l.bounds.bottom).toList()..sort();
  if (bottoms.isEmpty) return HandwritingPathResult(Path());
  final baseline = bottoms.length.isOdd ? bottoms[bottoms.length~/2] : (bottoms[bottoms.length~/2 -1] + bottoms[bottoms.length~/2]) / 2.0;

  final combined = Path();
  double dx = 0.0;

  bool nextIsDescender(int i){ final n=i+1; if(n>=lettersData.length) return false; final nxt=lettersData[n]; if(nxt.char==' ') return false; return _isDescender(nxt.char); }
  bool nextIsSpecific(int i,String t){ final n=i+1; if(n>=lettersData.length) return false; final nxt=lettersData[n]; if(nxt.char==' ') return false; return nxt.char.toLowerCase()==t.toLowerCase(); }

  final baseGap = baseGapOverride ?? kLetterGap;

  for (int i=0;i<lettersData.length;i++){
    final l = lettersData[i];
    if (l.char==' '){ dx += l.bounds.width; continue; }
    final charLower = l.char.toLowerCase();
    final bool desc = _isDescender(charLower);
    final bool isF = charLower=='f';
    double dy = baseline - l.bounds.bottom; // align bottom to baseline
    if (desc){
      final descDepth = l.bounds.bottom - baseline;
      dy += descDepth + kDescenderExtraShift; // keep original tail
    }
    if (isF){ dy += kFDownShift; }
    final shifted = l.path.shift(Offset(dx, dy));
    combined.addPath(shifted, Offset.zero);

    // kerning
    double gap = baseGap;
    if (charLower=='f') gap += kAfterFAdjust;
    else if (charLower=='l') gap += kAfterLAdjust;
    else if (charLower=='d') gap += kAfterDAdjust;
    else if (charLower=='b') gap += kAfterBAdjust;

    if (nextIsSpecific(i,'q')) gap += kBeforeQAdjust; else if (nextIsDescender(i)) gap += kDescenderPreGapAdjust;
    if (nextIsSpecific(i,'j')) gap += kBeforeJAdjust;
    if (nextIsSpecific(i,'f')) gap += kBeforeFAdjust;

    dx += l.bounds.width + gap;
  }

  return HandwritingPathResult(combined);
}

/// Разбиение цитаты на 3 строки (та же логика что в painter).
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

/// Собирает расширенные пути для трёх строк.
Future<List<Path>> buildAdvancedMultilineQuotePaths(String text,{double? baseGapOverride}) async {
  final parts = splitIntoThreeLines(text);
  final result = <Path>[];
  for (final p in parts) {
    if (p.trim().isEmpty) {
      result.add(Path());
    } else {
      result.add((await buildAdvancedTextPath(p, baseGapOverride: baseGapOverride)).path);
    }
  }
  return result;
}

/// Адаптивная разбивка текста на несколько строк по максимальной ширине.
/// Подбирает перенос слов, не превышая maxWidth, до maxLines.
Future<List<Path>> buildAdvancedAdaptiveMultilineQuotePaths(
  String text, {
  required double maxWidth,
  int maxLines = 10,
  double? baseGapOverride,
}) async {
  final cleaned = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return [Path()];
  final words = cleaned.split(' ');
  if (words.isEmpty) return [Path()];

  final List<Path> lines = [];
  final List<String> currentWords = [];
  Path? currentPath;

  for (int i = 0; i < words.length; i++) {
    final w = words[i];
    final testWords = [...currentWords, w];
    final testPath = (await buildAdvancedTextPath(testWords.join(' '), baseGapOverride: baseGapOverride)).path;
    final testWidth = testPath.getBounds().width;

    if (testWidth <= maxWidth || currentWords.isEmpty) {
      currentWords.add(w);
      currentPath = testPath;
    } else {
      if (currentPath != null) lines.add(currentPath);
      if (lines.length >= maxLines - 1) {
        final rest = [w, ...words.sublist(i + 1)].join(' ');
        lines.add((await buildAdvancedTextPath(rest, baseGapOverride: baseGapOverride)).path);
        return lines;
      }
      currentWords
        ..clear()
        ..add(w);
      currentPath = (await buildAdvancedTextPath(w, baseGapOverride: baseGapOverride)).path;
    }
  }
  if (currentPath != null && (lines.isEmpty || lines.last != currentPath)) {
    lines.add(currentPath);
  }
  return lines;
}

class _TmpLetter{ final String char; final Path path; final Rect bounds; _TmpLetter(this.char,this.path,this.bounds);}
