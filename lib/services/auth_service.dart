import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get onAuthStateChange =>
      _supabase.auth.onAuthStateChange;

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
