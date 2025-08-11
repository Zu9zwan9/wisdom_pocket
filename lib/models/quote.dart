class Quote {
  final String id;
  final String text;
  final String author;
  final String category;
  final bool isPremium;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.category,
    required this.isPremium,
  });

  factory Quote.fromMap(Map<String, dynamic> map) => Quote(
    id: map['id'].toString(),
    text: map['text'] ?? '',
    author: map['author'] ?? 'Unknown',
    category: map['category'] ?? 'general',
    isPremium: map['is_premium'] == true,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'author': author,
    'category': category,
    'is_premium': isPremium,
  };
}
