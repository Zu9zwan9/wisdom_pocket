import 'package:flutter/material.dart';

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
    // Создаем экстренный репозиторий
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error loading app: $e'),
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
    return MaterialApp(
      title: 'Wisdom Pocket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: HomePage(repository: repo),
      routes: {
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
