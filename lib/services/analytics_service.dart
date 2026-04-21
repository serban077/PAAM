import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  static const String _apiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const String _optOutKey = 'analytics_opt_out';

  bool _initialized = false;
  bool _isOptedOut = false;

  Future<void> initialize() async {
    if (_apiKey.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOptedOut = prefs.getBool(_optOutKey) ?? false;

      final config = PostHogConfig(_apiKey)
        ..host = 'https://eu.i.posthog.com'
        ..debug = kDebugMode
        ..captureApplicationLifecycleEvents = true;
      await Posthog().setup(config);
      _initialized = true;
    } catch (e) {
      debugPrint('AnalyticsService.initialize failed: $e');
    }
  }

  Future<void> identify(String userId) async {
    if (!_initialized || _isOptedOut) return;
    try {
      await Posthog().identify(userId: userId);
    } catch (_) {}
  }

  Future<void> track(String event,
      [Map<String, Object>? properties]) async {
    if (!_initialized || _isOptedOut) return;
    try {
      await Posthog()
          .capture(eventName: event, properties: properties ?? {});
    } catch (_) {}
  }

  /// Fires [event] only once — guarded by a [SharedPreferences] boolean [flagKey].
  Future<void> trackFirstOnce(String event, String flagKey,
      [Map<String, Object>? properties]) async {
    if (!_initialized || _isOptedOut) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(flagKey) == true) return;
      await track(event, properties);
      await prefs.setBool(flagKey, true);
    } catch (_) {}
  }

  Future<void> setOptOut(bool optOut) async {
    _isOptedOut = optOut;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_optOutKey, optOut);
    } catch (e) {
      debugPrint('AnalyticsService.setOptOut failed: $e');
    }
  }

  Future<bool> isOptedOut() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_optOutKey) ?? false;
  }

  Future<void> reset() async {
    if (!_initialized) return;
    try {
      await Posthog().reset();
    } catch (_) {}
  }
}
