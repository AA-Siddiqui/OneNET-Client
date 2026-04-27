import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/cloud_drive_mount_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
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
      await CloudDriveMountService.ensureMounted(_token);
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

    final profileData = await AuthService.fetchProfile(storedToken);
    if (profileData != null) {
      _token = storedToken;
      _loginData = profileData;
      _isAuthenticated = true;
      await CloudDriveMountService.ensureMounted(_token);
      notifyListeners();
      return true;
    }

    await CloudDriveMountService.unmount();
    await StorageService.clearToken();
    return false;
  }
}
