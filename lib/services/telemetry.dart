import 'dart:developer' as developer;

class Telemetry {
  static void log(String event, Map<String, dynamic> props) {
    developer.log('[telemetry] $event ${props.toString()}');
  }

  static void appOpen({required String userId, required String source}) =>
      log('app_open', {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'source': source,
      });

  static void quoteView({
    required String quoteId,
    required String location,
    required String userId,
  }) => log('quote_view', {
    'quote_id': quoteId,
    'location': location,
    'user_id': userId,
    'timestamp': DateTime.now().toIso8601String(),
  });

  static void share({
    required String quoteId,
    required String channel,
    required String shareType,
    required String userId,
  }) => log('share', {
    'quote_id': quoteId,
    'channel': channel,
    'share_type': shareType,
    'user_id': userId,
  });

  static void referralInviteSent({
    required String userId,
    required String code,
  }) => log('referral_invite_sent', {'user_id': userId, 'code': code});

  static void referralRedeemed({
    required String referrerId,
    required String refereeId,
  }) => log('referral_redeemed', {
    'referrer_id': referrerId,
    'referee_id': refereeId,
  });

  static void subscriptionPurchase({
    required String userId,
    required String plan,
    required double price,
    required String platform,
  }) => log('subscription_purchase', {
    'user_id': userId,
    'plan': plan,
    'price': price,
    'platform': platform,
  });

  static void subscriptionCancel({
    required String userId,
    required String reason,
  }) => log('subscription_cancel', {'user_id': userId, 'reason': reason});

  static void streakIncrement({
    required String userId,
    required int streakLength,
  }) => log('streak_increment', {
    'user_id': userId,
    'streak_length': streakLength,
  });
}
