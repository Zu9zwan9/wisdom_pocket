import 'package:flutter/cupertino.dart';

import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'services/animation_settings.dart';
import 'services/feature_flags.dart';
import 'services/quote_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Initializing app services...');

  try {
    final repo = await QuoteRepository.init();
    final flags = await FeatureFlags.load();
    final anim = await AnimationSettings.load();

    print('All services initialized successfully');
    runApp(MyApp(repo: repo, flags: flags, anim: anim));
  } catch (e) {
    print('Error initializing app: $e');
    // Улучшенный экстренный интерфейс
    runApp(CupertinoApp(
      title: 'Wisdom Pocket',
      home: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Error'),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 64,
                  color: CupertinoColors.systemRed,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load app',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  child: const Text('Retry'),
                  onPressed: () {
                    // Перезапуск приложения
                    main();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final QuoteRepository repo;
  final FeatureFlags flags;
  final AnimationSettings anim;

  const MyApp({
    super.key,
    required this.repo,
    required this.flags,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Wisdom Pocket',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.systemBrown,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      home: HomePage(repository: repo),
      routes: {
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
