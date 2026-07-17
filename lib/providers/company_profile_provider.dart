import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company_profile.dart';

class CompanyProfileProvider extends ChangeNotifier {
  static const _storageKey = 'sj_tracking_company_profile_v1';

  CompanyProfile _profile = CompanyProfile();
  bool _loading = true;

  CompanyProfile get profile => _profile;
  bool get isLoading => _loading;

  CompanyProfileProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _profile = CompanyProfile.fromJson(jsonDecode(raw));
      } catch (_) {
        _profile = CompanyProfile();
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> save(CompanyProfile profile) async {
    _profile = profile;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_profile.toJson()));
  }
}
