enum GameSessionStatus {
  idle,
  launching,
  active,
  error;

  String get label => switch (this) {
    GameSessionStatus.idle => 'READY',
    GameSessionStatus.launching => 'LAUNCHING...',
    GameSessionStatus.active => 'SESSION ACTIVE',
    GameSessionStatus.error => 'ERROR',
  };
}
