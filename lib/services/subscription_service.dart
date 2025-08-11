import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const _kActive = 'subscription_active';

  Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kActive) ?? false;
  }

  Future<void> mockPurchase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kActive, true);
  }

  Future<void> cancel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kActive, false);
  }
}
