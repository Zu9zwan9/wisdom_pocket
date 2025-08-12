import 'package:flutter/material.dart';
import '../services/quote_repository.dart';
import '../widgets/pocket_extraction_widget.dart';

class HomePage extends StatelessWidget {
  final QuoteRepository repository;

  const HomePage({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wisdom Pocket'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: PocketExtractionWidget(repository: repository),
    );
  }
}
