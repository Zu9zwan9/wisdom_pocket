class Quote {
  final int id;
  final String text;
  final String author;
  final String category;
  final bool isPremium;

  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
    this.isPremium = false,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
      category: json['category'] ?? 'wisdom',
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'category': category,
      'is_premium': isPremium,
    };
  }

  @override
  String toString() {
    return '"$text" - $author';
  }
}
