import 'package:flutter/foundation.dart';
import '../enums/game_session_status.dart';
import '../services/game_service.dart';
import '../services/storage_service.dart';

class GameSessionProvider extends ChangeNotifier {
  GameSessionStatus _status = GameSessionStatus.idle;
  bool _isFirstTimeSetup = true;
  String? _errorMessage;
  DateTime? _sessionStartedAt;

  GameSessionStatus get status => _status;
  bool get isFirstTimeSetup => _isFirstTimeSetup;
  String? get errorMessage => _errorMessage;
  DateTime? get sessionStartedAt => _sessionStartedAt;

  Duration get sessionDuration =>
      _sessionStartedAt != null ? DateTime.now().difference(_sessionStartedAt!) : Duration.zero;

  Future<void> checkFirstTimeStatus() async {
    _isFirstTimeSetup = await StorageService.isFirstTimeGaming();
    notifyListeners();
  }

  Future<void> launchSession() async {
    _status = GameSessionStatus.launching;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Replace mock with real Moonlight session launch
      await GameService.launchSession();
      _status = GameSessionStatus.active;
      _sessionStartedAt = DateTime.now();
    } catch (e) {
      _status = GameSessionStatus.error;
      _errorMessage = 'Failed to launch gaming session.';
    }

    notifyListeners();
  }

  Future<void> endSession() async {
    try {
      await GameService.endSession();
    } finally {
      _status = GameSessionStatus.idle;
      _sessionStartedAt = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> markFirstTimeComplete() async {
    _isFirstTimeSetup = false;
    await StorageService.setFirstTimeGamingComplete();
    notifyListeners();
  }
}
