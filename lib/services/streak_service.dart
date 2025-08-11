import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const _lastOpenKey = 'streak_last_open';
  static const _streakKey = 'streak_length';

  Future<int> incrementIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final last =
        DateTime.tryParse(prefs.getString(_lastOpenKey) ?? '') ??
        now.subtract(const Duration(days: 2));

    int streak = prefs.getInt(_streakKey) ?? 0;
    if (now.year == last.year &&
        now.month == last.month &&
        now.day == last.day) {
      // same day, no change
    } else if (last.add(const Duration(days: 1)).year == now.year &&
        last.add(const Duration(days: 1)).month == now.month &&
        last.add(const Duration(days: 1)).day == now.day) {
      streak += 1;
    } else {
      streak = 1; // reset
    }

    await prefs.setString(_lastOpenKey, now.toIso8601String());
    await prefs.setInt(_streakKey, streak);
    return streak;
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }
}
