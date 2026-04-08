import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:hiddify/ui_to_be/enums/connection_status.dart';
import 'package:hiddify/ui_to_be/models/server_model.dart';
import 'package:hiddify/ui_to_be/services/current_app_bridge.dart';
import 'package:hiddify/ui_to_be/services/vpn_service.dart';

class VpnProvider extends ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.disconnected;
  DateTime? _connectedSince;
  String? _assignedIp;
  String? _errorMessage;
  String? _nodesErrorMessage;
  String? _lastTraceId;
  bool _needsVpnPermission = false;
  bool _isLoadingServers = false;
  bool _hasLoadedServers = false;
  List<ServerModel> _servers = <ServerModel>[ServerModel.malaysia()];
  ServerModel _selectedServer = ServerModel.malaysia();

  StreamSubscription<ConnectionStatus>? _statusSubscription;
  StreamSubscription<ServerModel?>? _activeServerSubscription;
  Timer? _durationTimer;

  VpnProvider() {
    _status = CurrentAppBridge.currentConnectionStatus();
    if (_status == ConnectionStatus.connected) {
      _connectedSince = DateTime.now();
      _startDurationTimer();
    }

    _statusSubscription = CurrentAppBridge.watchConnectionStatus().listen(_applyStatus);
    _activeServerSubscription = CurrentAppBridge.watchActiveServer().listen((server) {
      if (server == null) {
        return;
      }
      _selectedServer = _resolveDisplayServer(server);
      notifyListeners();
    });
  }

  ConnectionStatus get status => _status;
  DateTime? get connectedSince => _connectedSince;
  String? get assignedIp => _assignedIp;
  String? get errorMessage => _errorMessage;
  String? get nodesErrorMessage => _nodesErrorMessage;
  String? get lastTraceId => _lastTraceId;
  bool get needsVpnPermission => _needsVpnPermission;
  bool get isLoadingServers => _isLoadingServers;
  List<ServerModel> get servers => List.unmodifiable(_servers);
  ServerModel get server => _selectedServer;

  Duration get connectedDuration =>
      _connectedSince != null ? DateTime.now().difference(_connectedSince!) : Duration.zero;

  Future<void> toggleConnection({required String? authToken, String? traceId}) async {
    _lastTraceId = traceId;
    if (_status == ConnectionStatus.connected) {
      await disconnect(traceId: traceId);
      return;
    }
    if (_status == ConnectionStatus.disconnected) {
      await connect(authToken: authToken, traceId: traceId);
    }
  }

  Future<void> connect({required String? authToken, String? traceId}) async {
    _lastTraceId = traceId;
    _status = ConnectionStatus.connecting;
    _errorMessage = null;
    _needsVpnPermission = false;
    notifyListeners();

    try {
      await CurrentAppBridge.connect();
      final refreshed = CurrentAppBridge.currentConnectionStatus();
      if (refreshed == ConnectionStatus.connected) {
        _applyStatus(refreshed);
      } else {
        _status = refreshed;
        _errorMessage = 'Unable to establish connection.';
        notifyListeners();
      }
    } catch (_) {
      _status = ConnectionStatus.disconnected;
      _errorMessage = 'Unable to establish connection.';
      notifyListeners();
    }
  }

  Future<void> disconnect({String? traceId}) async {
    _lastTraceId = traceId;
    _durationTimer?.cancel();

    try {
      await CurrentAppBridge.disconnect();
    } finally {
      _status = ConnectionStatus.disconnected;
      _connectedSince = null;
      _assignedIp = null;
      _errorMessage = null;
      _needsVpnPermission = false;
      notifyListeners();
    }
  }

  Future<void> preloadVpnNodes() async {
    if (_hasLoadedServers || _isLoadingServers) {
      return;
    }

    _isLoadingServers = true;
    _nodesErrorMessage = null;
    notifyListeners();

    try {
      final loadedServers = await VpnService.fetchVpnNodes();
      if (loadedServers.isNotEmpty) {
        _servers = loadedServers;
      }

      final activeServer = await CurrentAppBridge.currentActiveServer();
      if (activeServer != null) {
        _selectedServer = _resolveDisplayServer(activeServer);
      } else if (_servers.isNotEmpty) {
        _selectedServer = _servers.first;
      }

      _hasLoadedServers = true;
    } on VpnException catch (error) {
      _nodesErrorMessage = error.message;
    } catch (_) {
      _nodesErrorMessage = 'Failed to load VPN nodes';
    } finally {
      _isLoadingServers = false;
      notifyListeners();
    }
  }

  void selectServer(String serverId) {
    if (_status != ConnectionStatus.disconnected) {
      return;
    }

    ServerModel? matched;
    for (final server in _servers) {
      if (server.id == serverId) {
        matched = server;
        break;
      }
    }

    if (matched == null || matched.id == _selectedServer.id) {
      return;
    }

    _selectedServer = matched;
    notifyListeners();
    unawaited(CurrentAppBridge.selectServerByNode(matched));
  }

  ServerModel _resolveDisplayServer(ServerModel activeServer) {
    for (final server in _servers) {
      if (_matchesServer(server, activeServer)) {
        return server;
      }
    }
    return activeServer;
  }

  bool _matchesServer(ServerModel left, ServerModel right) {
    final leftId = left.id.trim().toLowerCase();
    final rightId = right.id.trim().toLowerCase();
    if (leftId.isNotEmpty && rightId.isNotEmpty && leftId == rightId) {
      return true;
    }

    final leftIp = left.publicIp.trim().toLowerCase();
    final rightIp = right.publicIp.trim().toLowerCase();
    if (leftIp.isNotEmpty && rightIp.isNotEmpty && leftIp == rightIp) {
      return true;
    }

    final leftName = left.name.trim().toLowerCase();
    final rightName = right.name.trim().toLowerCase();
    if (leftName.isNotEmpty && rightName.isNotEmpty && leftName == rightName) {
      return true;
    }

    final leftNode = left.nodeId.trim().toLowerCase();
    final rightNode = right.nodeId.trim().toLowerCase();
    return leftNode.isNotEmpty && rightNode.isNotEmpty && leftNode == rightNode;
  }

  void _applyStatus(ConnectionStatus status) {
    final wasConnected = _status == ConnectionStatus.connected;
    _status = status;

    if (status == ConnectionStatus.connected) {
      _connectedSince ??= DateTime.now();
      _errorMessage = null;
      _needsVpnPermission = false;
      _startDurationTimer();
    } else if (wasConnected || status == ConnectionStatus.disconnected) {
      _connectedSince = null;
      _assignedIp = null;
      _durationTimer?.cancel();
    }

    notifyListeners();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _statusSubscription?.cancel();
    _activeServerSubscription?.cancel();
    super.dispose();
  }
}
