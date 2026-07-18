import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiSettingsProvider extends ChangeNotifier {
  static const _apiKeyStorageKey = 'sj_tracking_anthropic_api_key_v1';

  String _apiKey = '';
  bool _loading = true;

  String get apiKey => _apiKey;
  bool get hasApiKey => _apiKey.trim().isNotEmpty;
  bool get isLoading => _loading;

  AiSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyStorageKey) ?? '';
    _loading = false;
    notifyListeners();
  }

  Future<void> saveApiKey(String key) async {
    _apiKey = key.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_apiKey.isEmpty) {
      await prefs.remove(_apiKeyStorageKey);
    } else {
      await prefs.setString(_apiKeyStorageKey, _apiKey);
    }
  }
}
