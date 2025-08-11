import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/quote.dart';

class QuoteRepository {
  static const _quotesBox = 'quotes_box';
  static const _favsBox = 'favorites_box';

  late final Box _quotes;
  late final Box _favs;

  static Future<QuoteRepository> init() async {
    await Hive.initFlutter();
    final quotes = await Hive.openBox(_quotesBox);
    final favs = await Hive.openBox(_favsBox);
    final repo = QuoteRepository._(quotes, favs);
    await repo._maybeSeedFromAssets();
    return repo;
  }

  QuoteRepository._(this._quotes, this._favs);

  Future<void> _maybeSeedFromAssets() async {
    if ((_quotes.get('all') as List?)?.isNotEmpty == true) return;
    final raw = await rootBundle.loadString('assets/sample_quotes.json');
    final List<dynamic> data = json.decode(raw);
    final quotes = data
        .map((e) => Quote.fromMap(e as Map<String, dynamic>))
        .toList();
    _quotes.put('all', quotes.map((q) => q.toMap()).toList());
  }

  List<Quote> getAll() {
    final List list = _quotes.get('all', defaultValue: []) as List;
    return list
        .map((e) => Quote.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Quote getDailyQuote(String? userId, {DateTime? now}) {
    final quotes = getAll();
    if (quotes.isEmpty) {
      return Quote(
        id: '0',
        text: 'No quotes available',
        author: 'System',
        category: 'general',
        isPremium: false,
      );
    }
    final today = (now ?? DateTime.now()).toUtc();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    final seedStr = '${userId ?? 'anon'}-$dateKey';
    final idx = seedStr.hashCode.abs() % quotes.length;
    return quotes[idx];
  }

  Quote random({bool premiumOk = true}) {
    final quotes = getAll().where((q) => premiumOk || !q.isPremium).toList();
    quotes.shuffle();
    return quotes.first;
  }

  bool isFavorite(String userId, String quoteId) {
    final Set favs =
        _favs.get(userId, defaultValue: <String>{}) as Set? ?? <String>{};
    return favs.contains(quoteId);
  }

  Future<void> toggleFavorite(String userId, String quoteId) async {
    final key = userId;
    final Set favs =
        (_favs.get(key, defaultValue: <String>{}) as Set? ?? <String>{})
            .toSet();
    if (favs.contains(quoteId)) {
      favs.remove(quoteId);
    } else {
      favs.add(quoteId);
      // light haptic on favorite add
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
    await _favs.put(key, favs);
  }

  List<Quote> favorites(String userId) {
    final Set favs =
        (_favs.get(userId, defaultValue: <String>{}) as Set? ?? <String>{})
            .toSet();
    return getAll().where((q) => favs.contains(q.id)).toList();
  }

  List<Quote> search(String query) {
    final q = query.toLowerCase();
    return getAll()
        .where(
          (e) =>
              e.text.toLowerCase().contains(q) ||
              e.author.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q),
        )
        .toList();
  }
}
