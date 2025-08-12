import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/quote.dart';

class QuoteRepository {
  static QuoteRepository? _instance;
  List<Quote> _quotes = [];
  final Random _random = Random();

  QuoteRepository._();

  static Future<QuoteRepository> init() async {
    _instance ??= QuoteRepository._();
    await _instance!._loadQuotes();
    return _instance!;
  }

  static QuoteRepository get instance {
    if (_instance == null) {
      throw StateError('QuoteRepository not initialized. Call QuoteRepository.init() first.');
    }
    return _instance!;
  }

  Future<void> _loadQuotes() async {
    try {
      print('Loading quotes from assets/sample_quotes.json...');
      final String quotesJson = await rootBundle.loadString('assets/sample_quotes.json');
      final List<dynamic> quotesData = json.decode(quotesJson);
      _quotes = quotesData.map((json) => Quote.fromJson(json)).toList();
      print('Loaded ${_quotes.length} quotes successfully');
    } catch (e) {
      print('Error loading quotes: $e');
      // Fallback quotes if file doesn't exist
      _quotes = [
        const Quote(
          id: 1,
          text: 'The only way to do great work is to love what you do.',
          author: 'Steve Jobs',
          category: 'motivation',
        ),
        const Quote(
          id: 2,
          text: 'Innovation distinguishes between a leader and a follower.',
          author: 'Steve Jobs',
          category: 'leadership',
        ),
        const Quote(
          id: 3,
          text: 'Life is what happens to you while you\'re busy making other plans.',
          author: 'John Lennon',
          category: 'life',
        ),
        const Quote(
          id: 4,
          text: 'The future belongs to those who believe in the beauty of their dreams.',
          author: 'Eleanor Roosevelt',
          category: 'wisdom',
        ),
        const Quote(
          id: 5,
          text: 'It is during our darkest moments that we must focus to see the light.',
          author: 'Aristotle',
          category: 'wisdom',
        ),
      ];
      print('Using fallback quotes: ${_quotes.length} quotes');
    }
  }

  Quote getRandomQuote() {
    if (_quotes.isEmpty) {
      return const Quote(
        id: 0,
        text: 'No quotes available',
        author: 'System',
        category: 'error',
      );
    }
    final quote = _quotes[_random.nextInt(_quotes.length)];
    print('Selected quote: "${quote.text}" by ${quote.author}');
    return quote;
  }

  List<Quote> getAllQuotes() => List.unmodifiable(_quotes);

  int get quotesCount => _quotes.length;
}
