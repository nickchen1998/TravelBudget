import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();

  bool _isLoading = false;
  String? _displayName;
  String? _email;
  StreamSubscription<AuthState>? _authSubscription;

  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isLoading => _isLoading;
  User? get currentUser => _authService.currentUser;
  String? get displayName => _displayName;
  String? get email => _email;

  /// List of linked identity providers (e.g. ['apple', 'google'])
  List<String> get linkedProviders => _authService.getLinkedProviders();

  bool get hasAppleLinked => linkedProviders.contains('apple');
  bool get hasGoogleLinked => linkedProviders.contains('google');

  void initialize() {
    _authSubscription = _authService.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _loadProfile();
        syncNow();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _displayName = null;
        _email = null;
      }
      notifyListeners();
    });

    if (isLoggedIn) {
      _loadProfile();
    }
  }

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> _loadProfile() async {
    final profile = await _authService.getProfile();
    if (profile != null) {
      _displayName = profile['display_name'] as String?;
      _email = profile['email'] as String?;
      notifyListeners();
    }
  }

  Future<void> syncNow() async {
    if (!isLoggedIn || _isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    try {
      await _syncService.syncOnLogin();
      _lastSyncedAt = DateTime.now();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> signInWithApple() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithApple();
      await _loadProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
      await _loadProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Identity Linking ────────────────────────────────────────────────────

  bool _isLinking = false;
  bool get isLinking => _isLinking;

  Future<void> linkWithGoogle() async {
    _isLinking = true;
    notifyListeners();
    try {
      await _authService.linkWithGoogle();
    } finally {
      _isLinking = false;
      notifyListeners();
    }
  }

  Future<void> linkWithApple() async {
    _isLinking = true;
    notifyListeners();
    try {
      await _authService.linkWithApple();
    } finally {
      _isLinking = false;
      notifyListeners();
    }
  }

  // ── Profile & Account ────────────────────────────────────────────────────

  Future<void> updateDisplayName(String name) async {
    await _authService.updateDisplayName(name);
    _displayName = name;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _displayName = null;
      _email = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.deleteAccount();
      _displayName = null;
      _email = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
