import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'services/animation_settings.dart';
import 'services/feature_flags.dart';
import 'services/quote_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await QuoteRepository.init();
  final flags = await FeatureFlags.load();
  final anim = await AnimationSettings.load();
  runApp(MyApp(repo: repo, flags: flags, anim: anim));
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
    const userId = 'local_user';
    return MaterialApp(
      title: 'Wisdom Pocket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) =>
            HomePage(repo: repo, flags: flags, anim: anim, userId: userId),
        '/settings': (_) => SettingsPage(anim: anim, flags: flags),
      },
      initialRoute: '/',
    );
  }
}
