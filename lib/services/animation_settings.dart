import 'package:shared_preferences/shared_preferences.dart';

class AnimationSettings {
  static const _kStiffness = 'anim_stiffness';
  static const _kDamping = 'anim_damping';
  static const _kMaxPull = 'anim_max_pull';

  double stiffness;
  double damping;
  double maxPull;

  AnimationSettings({
    this.stiffness = 200.0,
    this.damping = 15.0,
    this.maxPull = 200.0,
  });

  static Future<AnimationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AnimationSettings(
      stiffness: prefs.getDouble(_kStiffness) ?? 200.0,
      damping: prefs.getDouble(_kDamping) ?? 15.0,
      maxPull: prefs.getDouble(_kMaxPull) ?? 200.0,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kStiffness, stiffness);
    await prefs.setDouble(_kDamping, damping);
    await prefs.setDouble(_kMaxPull, maxPull);
  }
}
