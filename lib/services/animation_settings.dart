import 'package:shared_preferences/shared_preferences.dart';

class AnimationSettings {
  static AnimationSettings? _instance;

  double cardExtractionSpeed;
  double springBackSpeed;
  double pullThreshold;

  AnimationSettings._({
    this.cardExtractionSpeed = 0.8,
    this.springBackSpeed = 1.2,
    this.pullThreshold = 0.5,
  });

  static Future<AnimationSettings> load() async {
    _instance ??= AnimationSettings._();
    final prefs = await SharedPreferences.getInstance();

    _instance!.cardExtractionSpeed = prefs.getDouble('cardExtractionSpeed') ?? 0.8;
    _instance!.springBackSpeed = prefs.getDouble('springBackSpeed') ?? 1.2;
    _instance!.pullThreshold = prefs.getDouble('pullThreshold') ?? 0.5;

    return _instance!;
  }

  static AnimationSettings get instance {
    if (_instance == null) {
      throw StateError('AnimationSettings not initialized. Call AnimationSettings.load() first.');
    }
    return _instance!;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('cardExtractionSpeed', cardExtractionSpeed);
    await prefs.setDouble('springBackSpeed', springBackSpeed);
    await prefs.setDouble('pullThreshold', pullThreshold);
  }
}
