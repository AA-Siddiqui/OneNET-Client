import 'dart:async';

import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

import 'package:hiddify/ui_to_be/services/current_app_bridge.dart';

class NetworkSpeed {
  final double downloadMbps;
  final double uploadMbps;

  const NetworkSpeed({required this.downloadMbps, required this.uploadMbps});

  static const zero = NetworkSpeed(downloadMbps: 0, uploadMbps: 0);
}

class NetworkSpeedService {
  StreamSubscription<SystemInfo>? _statsSubscription;
  bool _running = false;

  final _controller = StreamController<NetworkSpeed>.broadcast();

  Stream<NetworkSpeed> get speedStream => _controller.stream;

  Future<void> start() async {
    if (_running) {
      return;
    }

    _running = true;
    _statsSubscription = CurrentAppBridge.watchStats().listen(
      (stats) {
        if (!_running) {
          return;
        }

        _controller.add(NetworkSpeed(downloadMbps: _toMbps(stats.downlink), uploadMbps: _toMbps(stats.uplink)));
      },
      onError: (error, stackTrace) {
        if (_running) {
          _controller.add(NetworkSpeed.zero);
        }
      },
    );
  }

  void stop() {
    _running = false;
    _statsSubscription?.cancel();
    _statsSubscription = null;
    _controller.add(NetworkSpeed.zero);
  }

  void dispose() {
    stop();
    _controller.close();
  }

  double _toMbps(Object bytesPerSecond) {
    final value = switch (bytesPerSecond) {
      final num n => n.toDouble(),
      _ => (bytesPerSecond as dynamic).toDouble() as double,
    };

    return (value * 8 / 1000000).clamp(0, double.infinity);
  }
}
