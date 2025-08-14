import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wisdom_pocket/pages/handwriting_test_page.dart';
import 'package:wisdom_pocket/pages/animated_quote_page.dart';
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
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.pen),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HandwritingTestPage(),
              ),
            );
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.sparkles),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => AnimatedQuotePage(repository: repository),
                  ),
                );
              },
            ),
            CupertinoButton(
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
          ],
        ),
      ),
      child: PocketExtractionWidget(repository: repository),
    );
  }
}
