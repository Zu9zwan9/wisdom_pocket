import 'package:flutter/cupertino.dart';
import '../services/quote_repository.dart';
import '../widgets/pocket_extraction_widget.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  final QuoteRepository repository;

  const HomePage({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Wisdom Pocket'),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.settings),
          onPressed: () async {
            try {
              await Navigator.pushNamed(context, '/settings');
            } catch (e) {
              // Fallback навигация если маршрут не найден
              if (context.mounted) {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              }
            }
          },
        ),
      ),
      child: PocketExtractionWidget(repository: repository),
    );
  }
}
