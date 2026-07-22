import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';

/// Manages the app's user accounts: the built-in admin account, sign up,
/// sign in, session expiry, and (for admins) creating other users, approving
/// pending sign-ups, and editing permissions.
class AuthProvider extends ChangeNotifier {
  static const _usersKey = 'sj_tracking_users_v1';
  static const _sessionKey = 'sj_tracking_session_username_v1';
  static const _sessionExpiryKey = 'sj_tracking_session_expiry_v1';

  static const adminUsername = 'SJTRACKING';
  static const _adminSeedPassword = 'Bismillah';

  /// How long a signed-in session stays valid before requiring login again.
  static const sessionDuration = Duration(hours: 12);

  List<AppUser> _users = [];
  AppUser? _currentUser;
  bool _isLoading = true;
  String? _error;
  Timer? _expiryTimer;

  List<AppUser> get users => List.unmodifiable(_users);
  List<AppUser> get pendingUsers =>
      _users.where((u) => !u.isAdmin && !u.isApproved).toList();
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get currentUserIsAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    _init();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  String _hash(String password) => sha256.convert(utf8.encode(password)).toString();

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_usersKey);

    if (raw == null || raw.isEmpty) {
      // First run: seed the built-in admin account.
      _users = [
        AppUser(
          id: const Uuid().v4(),
          username: adminUsername,
          passwordHash: _hash(_adminSeedPassword),
          isAdmin: true,
          isApproved: true,
          permissions: Permission.values.toSet(),
        ),
      ];
      await _persistUsers(prefs);
    } else {
      _users = raw.map((s) => AppUser.fromJson(jsonDecode(s))).toList();
      // Safety net: guarantee an admin account always exists, in case of
      // corrupted or edited local storage.
      if (!_users.any((u) => u.isAdmin)) {
        _users.add(AppUser(
          id: const Uuid().v4(),
          username: adminUsername,
          passwordHash: _hash(_adminSeedPassword),
          isAdmin: true,
          isApproved: true,
          permissions: Permission.values.toSet(),
        ));
        await _persistUsers(prefs);
      }
    }

    await _restoreSession(prefs);

    _isLoading = false;
    notifyListeners();
    _startExpiryWatch();
  }

  Future<void> _restoreSession(SharedPreferences prefs) async {
    final sessionUsername = prefs.getString(_sessionKey);
    final expiryRaw = prefs.getString(_sessionExpiryKey);
    if (sessionUsername == null || expiryRaw == null) return;

    final expiry = DateTime.tryParse(expiryRaw);
    if (expiry == null || DateTime.now().isAfter(expiry)) {
      // Session expired while the app was closed.
      await prefs.remove(_sessionKey);
      await prefs.remove(_sessionExpiryKey);
      return;
    }

    final match = _findByUsername(sessionUsername);
    if (match != null && (match.isAdmin || match.isApproved)) {
      _currentUser = match;
    }
  }

  /// Periodically checks whether the current session has expired while the
  /// app is open, and logs the user out automatically if so.
  void _startExpiryWatch() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (_currentUser == null) return;
      final prefs = await SharedPreferences.getInstance();
      final expiryRaw = prefs.getString(_sessionExpiryKey);
      final expiry = expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        await logout(expired: true);
      }
    });
  }

  Future<void> _persistUsers([SharedPreferences? prefsIn]) async {
    final prefs = prefsIn ?? await SharedPreferences.getInstance();
    await prefs.setStringList(
      _usersKey,
      _users.map((u) => jsonEncode(u.toJson())).toList(),
    );
  }

  AppUser? _findByUsername(String username) {
    final normalized = username.trim().toLowerCase();
    for (final u in _users) {
      if (u.username.toLowerCase() == normalized) return u;
    }
    return null;
  }

  // --- Sign in / sign up / sign out -------------------------------------

  Future<bool> login(String username, String password) async {
    final user = _findByUsername(username);
    if (user == null || user.passwordHash != _hash(password)) {
      _error = 'Incorrect username or password';
      notifyListeners();
      return false;
    }
    if (!user.isAdmin && !user.isApproved) {
      _error = 'Your account is awaiting admin approval. Please check back later.';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    _error = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now().add(sessionDuration);
    await prefs.setString(_sessionKey, user.username);
    await prefs.setString(_sessionExpiryKey, expiry.toIso8601String());
    return true;
  }

  /// Self-service sign up. New accounts are created **unapproved** and
  /// cannot log in until an admin approves them from the Manage Users
  /// screen. This does NOT sign the new account in.
  Future<bool> signUp(String username, String password) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      _error = 'Username and password are required';
      notifyListeners();
      return false;
    }
    if (_findByUsername(trimmed) != null) {
      _error = 'That username is already taken';
      notifyListeners();
      return false;
    }

    final newUser = AppUser(
      id: const Uuid().v4(),
      username: trimmed,
      passwordHash: _hash(password),
      isAdmin: false,
      isApproved: false,
      permissions: <Permission>{},
    );
    _users.add(newUser);
    _error = null;
    notifyListeners();

    await _persistUsers();
    return true;
  }

  Future<void> logout({bool expired = false}) async {
    _currentUser = null;
    _error = expired ? 'Your session expired. Please sign in again.' : null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_sessionExpiryKey);
  }

  // --- Admin: manage other users ------------------------------------------

  /// Creates a new user directly (admin action). Admin-created accounts are
  /// approved immediately. Returns null on success, or an error message.
  Future<String?> createUser({
    required String username,
    required String password,
    Set<Permission> permissions = const {},
  }) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      return 'Username and password are required';
    }
    if (_findByUsername(trimmed) != null) {
      return 'That username is already taken';
    }

    _users.add(AppUser(
      id: const Uuid().v4(),
      username: trimmed,
      passwordHash: _hash(password),
      isAdmin: false,
      isApproved: true,
      permissions: permissions.toSet(),
    ));
    notifyListeners();
    await _persistUsers();
    return null;
  }

  Future<void> updatePermissions(String userId, Set<Permission> permissions) async {
    final user = _users.where((u) => u.id == userId).cast<AppUser?>().firstOrNull;
    if (user == null || user.isAdmin) return; // Admin permissions are fixed.
    user.permissions = permissions.toSet();
    notifyListeners();
    await _persistUsers();
  }

  /// Approves (or revokes approval for) a self-signed-up user, controlling
  /// whether they're allowed to log in at all.
  Future<void> setApproved(String userId, bool approved) async {
    final user = _users.where((u) => u.id == userId).cast<AppUser?>().firstOrNull;
    if (user == null || user.isAdmin) return;
    user.isApproved = approved;
    notifyListeners();
    await _persistUsers();
  }

  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId && !u.isAdmin);
    notifyListeners();
    await _persistUsers();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
