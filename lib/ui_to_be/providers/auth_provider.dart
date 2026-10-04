import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hiddify/ui_to_be/services/auth_service.dart';
import 'package:hiddify/ui_to_be/services/cloud_drive_mount_service.dart';
import 'package:hiddify/ui_to_be/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _autoLoginRetryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isAutoLoginRetrying = false;
  String? _token;
  String? _errorMessage;
  Map<String, dynamic>? _loginData;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  /// The full login response data (user + subscription).
  /// Available immediately after a successful [login] call.
  Map<String, dynamic>? get loginData => _loginData;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.login(email, password);
      _token = result['token'] as String;
      _loginData = result;
      _isAuthenticated = true;
      await StorageService.saveToken(_token!);
      await StorageService.saveLoginData(result);
      _mountCloudDriveInBackground(_token);
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Connection error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_token != null) {
        await AuthService.logout(_token!);
      }
    } finally {
      await CloudDriveMountService.unmount();
      _isAuthenticated = false;
      _token = null;
      _errorMessage = null;
      _loginData = null;
      await StorageService.clearToken();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> tryAutoLogin() async {
    final storedToken = await StorageService.getToken();
    if (storedToken == null) return false;

    try {
      final profileData = await AuthService.fetchProfile(storedToken);
      if (profileData != null) {
        await _applyAuthenticatedSession(
          storedToken,
          profileData,
          persistLoginData: true,
        );
        return true;
      }

      await _clearStoredSession();
      return false;
    } on AuthException {
      final cachedLoginData = await StorageService.getLoginData();
      if (cachedLoginData == null) {
        return false;
      }

      await _applyAuthenticatedSession(
        storedToken,
        cachedLoginData,
        persistLoginData: false,
      );
      unawaited(_retryAutoLoginInBackground(storedToken));
      return true;
    }
  }

  Future<void> _retryAutoLoginInBackground(String token) async {
    if (_isAutoLoginRetrying) return;
    _isAutoLoginRetrying = true;

    try {
      for (final delay in _autoLoginRetryDelays) {
        await Future<void>.delayed(delay);
        if (_token != token || !_isAuthenticated) return;

        try {
          final profileData = await AuthService.fetchProfile(token);
          if (profileData != null) {
            await _applyAuthenticatedSession(
              token,
              profileData,
              persistLoginData: true,
            );
            return;
          }

          await _clearStoredSession();
          return;
        } on AuthException {
          // Retry transient refresh failures while keeping the cached session active.
        }
      }
    } finally {
      _isAutoLoginRetrying = false;
    }
  }

  Future<void> _applyAuthenticatedSession(
    String token,
    Map<String, dynamic> loginData, {
    required bool persistLoginData,
  }) async {
    _token = token;
    _loginData = loginData;
    _isAuthenticated = true;
    if (persistLoginData) {
      await StorageService.saveLoginData(loginData);
    }
    _mountCloudDriveInBackground(_token);
    notifyListeners();
  }

  Future<void> _clearStoredSession() async {
    await CloudDriveMountService.unmount();
    _isAuthenticated = false;
    _token = null;
    _loginData = null;
    await StorageService.clearToken();
    notifyListeners();
  }

  void _mountCloudDriveInBackground(String? token) {
    unawaited(CloudDriveMountService.ensureMounted(token).catchError((_) {}));
  }
}
