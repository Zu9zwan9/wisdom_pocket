import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

final Map<String, Path> _pathCache = {};

Future<Path> loadLetterPath(String id) async {
  if (_pathCache.containsKey(id)) {
    return _pathCache[id]!;
  }

  try {
    final isCapital = id == id.toUpperCase() && id != id.toLowerCase();
    final folder = isCapital ? 'capital_letters' : 'letters';
    final svgString = await rootBundle.loadString('assets/$folder/$id.svg');
    final document = XmlDocument.parse(svgString);
    final paths = document.findAllElements('path');

    final combinedPath = Path();
    for (final element in paths) {
      final d = element.getAttribute('d');
      if (d != null) {
        combinedPath.addPath(parseSvgPathData(d), Offset.zero);
      }
    }

    _pathCache[id] = combinedPath;
    return combinedPath;
  } catch (e) {
    debugPrint('Error loading letter "$id": $e');
    return Path();
  }
}

Future<Map<String, Path>> loadAllLetterPaths(List<String> ids) async {
  final results = <String, Path>{};
  for (final id in ids) {
    results[id] = await loadLetterPath(id);
  }
  return results;
}
