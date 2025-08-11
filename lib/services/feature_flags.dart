import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlags {
  static const _kShareToUnlock = 'feature_share_to_unlock';
  static const _kReferralFlow = 'feature_referral_flow';
  static const _kConfettiOnExtract = 'feature_confetti_on_extract';

  bool shareToUnlock;
  bool referralFlow;
  bool confettiOnExtract;

  FeatureFlags({
    this.shareToUnlock = true,
    this.referralFlow = true,
    this.confettiOnExtract = false,
  });

  static Future<FeatureFlags> load() async {
    final prefs = await SharedPreferences.getInstance();
    return FeatureFlags(
      shareToUnlock: prefs.getBool(_kShareToUnlock) ?? true,
      referralFlow: prefs.getBool(_kReferralFlow) ?? true,
      confettiOnExtract: prefs.getBool(_kConfettiOnExtract) ?? false,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShareToUnlock, shareToUnlock);
    await prefs.setBool(_kReferralFlow, referralFlow);
    await prefs.setBool(_kConfettiOnExtract, confettiOnExtract);
  }
}
