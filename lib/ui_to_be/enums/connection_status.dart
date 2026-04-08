enum ConnectionStatus {
  disconnected,
  connecting,
  connected;

  String get label => switch (this) {
    ConnectionStatus.disconnected => 'DISCONNECTED',
    ConnectionStatus.connecting => 'CONNECTING...',
    ConnectionStatus.connected => 'CONNECTED',
  };
}
