import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Google Sign-In iOS client ID (Android uses google-services.json)
  static const _googleClientId =
      '153883035579-qgp0to8u4o1a7vf67tito0pbjoh57r95.apps.googleusercontent.com';

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get onAuthStateChange =>
      _supabase.auth.onAuthStateChange;

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ── Apple Sign-In ─────────────────────────────────────────────────────────

  Future<AuthResponse> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign-In failed: no identity token');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // Update profile with Apple name if available
    if (credential.givenName != null || credential.familyName != null) {
      final name = [credential.familyName, credential.givenName]
          .where((n) => n != null && n.isNotEmpty)
          .join('');
      if (name.isNotEmpty && response.user != null) {
        await _supabase.from('profiles').update({
          'display_name': name,
        }).eq('id', response.user!.id);
      }
    }

    return response;
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<AuthResponse> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(clientId: _googleClientId);

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('Google Sign-In failed: no ID token');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    // Update profile with Google name if no display name yet
    if (response.user != null) {
      final profile = await getProfile();
      final existingName = profile?['display_name'] as String?;
      if ((existingName == null || existingName.isEmpty) &&
          googleUser.displayName != null &&
          googleUser.displayName!.isNotEmpty) {
        await _supabase.from('profiles').update({
          'display_name': googleUser.displayName,
        }).eq('id', response.user!.id);
      }
    }

    return response;
  }

  // ── Identity Linking (帳號綁定) ──────────────────────────────────────────

  /// Get list of linked identity providers (e.g. ['apple', 'google'])
  List<String> getLinkedProviders() {
    final user = currentUser;
    if (user == null) return [];
    final identities = user.identities;
    if (identities == null) return [];
    return identities.map((i) => i.provider).toList();
  }

  /// Link Google identity to current account
  Future<void> linkWithGoogle() async {
    if (!isLoggedIn) throw Exception('Not logged in');

    final providers = getLinkedProviders();
    if (providers.contains('google')) {
      throw Exception('Google account already linked');
    }

    final googleSignIn = GoogleSignIn(clientId: _googleClientId);

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('Google Sign-In failed: no ID token');
    }

    // Use Supabase Edge Function to link the identity server-side
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('No active session');

    final response = await _supabase.functions.invoke(
      'link-identity',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {
        'provider': 'google',
        'id_token': idToken,
        'access_token': accessToken,
      },
    );

    if (response.status != 200) {
      final body = response.data;
      final message = (body is Map ? body['error'] : null) ?? 'Link failed';
      throw Exception(message);
    }

    // Refresh session to get updated identities
    await _supabase.auth.refreshSession();
  }

  /// Link Apple identity to current account
  Future<void> linkWithApple() async {
    if (!isLoggedIn) throw Exception('Not logged in');

    final providers = getLinkedProviders();
    if (providers.contains('apple')) {
      throw Exception('Apple account already linked');
    }

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign-In failed: no identity token');
    }

    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('No active session');

    final response = await _supabase.functions.invoke(
      'link-identity',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {
        'provider': 'apple',
        'id_token': idToken,
        'nonce': rawNonce,
      },
    );

    if (response.status != 200) {
      final body = response.data;
      final message = (body is Map ? body['error'] : null) ?? 'Link failed';
      throw Exception(message);
    }

    // Refresh session to get updated identities
    await _supabase.auth.refreshSession();
  }

  // ── Profile & Account ─────────────────────────────────────────────────────

  Future<void> updateDisplayName(String name) async {
    final user = currentUser;
    if (user == null) throw Exception('Not logged in');
    if (name.length > 50) throw Exception('Display name too long');
    await _supabase.from('profiles').update({
      'display_name': name,
    }).eq('id', user.id);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> deleteAccount() async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not logged in');
    final response = await _supabase.functions.invoke(
      'delete-account',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (response.status != 200) {
      final body = response.data;
      final message = (body is Map ? body['error'] : null) ?? 'Unknown error';
      throw Exception(message);
    }
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return data;
  }
}
