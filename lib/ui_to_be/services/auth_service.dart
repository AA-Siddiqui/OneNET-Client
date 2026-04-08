import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class AuthService {
  /// Sign in with email/username and password via the login edge function.
  /// Returns a Map with {token, expires_at, user} on success.
  static Future<Map<String, dynamic>> login(String login, String password) async {
    final response = await http.post(
      Uri.parse(AppConstants.loginEndpoint),
      headers: {'Content-Type': 'application/json', 'apikey': AppConstants.supabaseAnonKey},
      body: jsonEncode({'login': login, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || body['success'] != true) {
      throw AuthException(body['error'] as String? ?? 'Login failed');
    }

    return body;
  }

  /// Register a new account via the register edge function.
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String region = 'HK',
  }) async {
    final response = await http.post(
      Uri.parse(AppConstants.registerEndpoint),
      headers: {'Content-Type': 'application/json', 'apikey': AppConstants.supabaseAnonKey},
      body: jsonEncode({'username': username, 'email': email, 'password': password, 'region': region}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 || body['success'] != true) {
      throw AuthException(body['error'] as String? ?? 'Registration failed');
    }

    return body;
  }

  /// Sign out the current session via the logout edge function.
  static Future<void> logout(String token) async {
    await http.post(
      Uri.parse(AppConstants.logoutEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': 'Bearer $token',
        'apikey': AppConstants.supabaseAnonKey,
      },
    );
  }

  /// Fetch user profile and subscription using a stored token.
  /// Returns the full response map on success, or null if the token is invalid.
  static Future<Map<String, dynamic>?> fetchProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.getProfileEndpoint),
        headers: {'x-auth-token': 'Bearer $token', 'apikey': AppConstants.supabaseAnonKey},
      );

      if (response.statusCode == 401) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      return body;
    } catch (_) {
      return null;
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
