import 'package:shared_preferences/shared_preferences.dart';

enum ConsentStatus { accepted, declined, unknown }

class ConsentUtil {
  static const String _consentKey = 'user_consent_status';

  static Future<ConsentStatus> getConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_consentKey);
    if (value == 'accepted') return ConsentStatus.accepted;
    if (value == 'declined') return ConsentStatus.declined;
    return ConsentStatus.unknown;
  }

  static Future<void> setConsentStatus(ConsentStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_consentKey, status.name);
  }

  static Future<bool> isConsentRequired() async {
    final status = await getConsentStatus();
    return status == ConsentStatus.unknown;
  }
} 