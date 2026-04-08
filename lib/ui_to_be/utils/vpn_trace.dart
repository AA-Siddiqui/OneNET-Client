import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

class VpnTraceLogger {
  static final Random _random = Random.secure();

  static String newTraceId() {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch.toRadixString(36);
    final randomPart = _random.nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
    return 'vpn-$timestamp-$randomPart';
  }

  static void log({
    required String traceId,
    required String layer,
    required String step,
    Map<String, Object?> details = const <String, Object?>{},
  }) {
    final Map<String, Object?> payload = <String, Object?>{
      'scope': 'vpn_connect_trace',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'trace_id': traceId,
      'layer': layer,
      'step': step,
      if (details.isNotEmpty) 'details': details,
    };

    debugPrint('[VPN-TRACE] ${jsonEncode(payload)}');
  }

  static Map<String, Object?> describeError(Object error, [StackTrace? stackTrace]) {
    return <String, Object?>{
      'error_type': error.runtimeType.toString(),
      'error': error.toString(),
      if (kDebugMode && stackTrace != null)
        'stack': stackTrace.toString().split('\n').where((line) => line.trim().isNotEmpty).take(3).join(' | '),
    };
  }
}

class VpnTraceSession {
  final String traceId;
  final String layer;
  final Stopwatch _stopwatch = Stopwatch();
  bool _completed = false;

  VpnTraceSession({required this.traceId, required this.layer}) {
    _stopwatch.start();
    log('session_started');
  }

  void log(String step, {Map<String, Object?> details = const <String, Object?>{}}) {
    final Map<String, Object?> detailPayload = <String, Object?>{
      'elapsed_ms': _stopwatch.elapsedMilliseconds,
      ...details,
    };

    VpnTraceLogger.log(traceId: traceId, layer: layer, step: step, details: detailPayload);
  }

  void complete({required String outcome, Map<String, Object?> details = const <String, Object?>{}}) {
    if (_completed) {
      return;
    }
    _completed = true;

    final Map<String, Object?> detailPayload = <String, Object?>{
      'outcome': outcome,
      'total_ms': _stopwatch.elapsedMilliseconds,
      ...details,
    };

    VpnTraceLogger.log(traceId: traceId, layer: layer, step: 'session_completed', details: detailPayload);
  }
}
