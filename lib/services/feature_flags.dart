import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlags {
  static FeatureFlags? _instance;

  bool enableHapticFeedback;
  bool enableSoundEffects;
  bool enableAdvancedAnimations;

  FeatureFlags._({
    this.enableHapticFeedback = true,
    this.enableSoundEffects = false,
    this.enableAdvancedAnimations = true,
  });

  static Future<FeatureFlags> load() async {
    _instance ??= FeatureFlags._();
    final prefs = await SharedPreferences.getInstance();

    _instance!.enableHapticFeedback = prefs.getBool('enableHapticFeedback') ?? true;
    _instance!.enableSoundEffects = prefs.getBool('enableSoundEffects') ?? false;
    _instance!.enableAdvancedAnimations = prefs.getBool('enableAdvancedAnimations') ?? true;

    return _instance!;
  }

  static FeatureFlags get instance {
    if (_instance == null) {
      throw StateError('FeatureFlags not initialized. Call FeatureFlags.load() first.');
    }
    return _instance!;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableHapticFeedback', enableHapticFeedback);
    await prefs.setBool('enableSoundEffects', enableSoundEffects);
    await prefs.setBool('enableAdvancedAnimations', enableAdvancedAnimations);
  }
}
