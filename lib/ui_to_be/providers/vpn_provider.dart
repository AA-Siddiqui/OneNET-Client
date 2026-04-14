import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:hiddify/ui_to_be/enums/connection_status.dart';
import 'package:hiddify/ui_to_be/models/server_model.dart';
import 'package:hiddify/ui_to_be/services/current_app_bridge.dart';
import 'package:hiddify/ui_to_be/services/storage_service.dart';
import 'package:hiddify/ui_to_be/services/vpn_service.dart';
import 'package:hiddify/ui_to_be/utils/vpn_trace.dart';

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
  ServerModel? _connectedServerDisplayFallback;

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
      _persistSelectedServer(_selectedServer);
      notifyListeners();
    });

    unawaited(_restorePersistedSessionState());
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
    final resolvedTraceId = (traceId != null && traceId.trim().isNotEmpty)
        ? traceId.trim()
        : VpnTraceLogger.newTraceId();
    _lastTraceId = resolvedTraceId;
    if (_status == ConnectionStatus.connected) {
      await disconnect(traceId: resolvedTraceId);
      return;
    }
    if (_status == ConnectionStatus.disconnected) {
      await connect(authToken: authToken, traceId: resolvedTraceId);
    }
  }

  Future<void> connect({required String? authToken, String? traceId}) async {
    final resolvedTraceId = (traceId != null && traceId.trim().isNotEmpty)
        ? traceId.trim()
        : VpnTraceLogger.newTraceId();
    _lastTraceId = resolvedTraceId;
    _status = ConnectionStatus.connecting;
    _errorMessage = null;
    _needsVpnPermission = false;
    _connectedServerDisplayFallback = _selectedServer;
    _persistSelectedServer(_selectedServer);
    notifyListeners();

    try {
      final normalizedToken = authToken?.trim() ?? '';
      if (normalizedToken.isEmpty) {
        throw const VpnException('Please sign in to connect.');
      }

      final serverIp = _selectedServer.publicIp.trim();
      if (serverIp.isEmpty) {
        throw const VpnException('Please select a VPN server.');
      }

      VpnTraceLogger.log(
        traceId: resolvedTraceId,
        layer: 'client.provider.vpn',
        step: 'vpn_connect_started',
        details: <String, Object?>{'server_ip': serverIp, 'server_id': _selectedServer.id},
      );

      final provisioned = await VpnService.provisionConnection(
        token: normalizedToken,
        serverIp: serverIp,
        traceId: resolvedTraceId,
      );

      _lastTraceId = provisioned.traceId;
      _assignedIp = provisioned.assignedIp;

      await VpnService.applyProvisionedConfig(
        provisioned.config,
        fallbackContent: provisioned.serverConfig,
        preferredProfileName: _selectedServer.name,
      );

      await CurrentAppBridge.connect();
      final refreshed = CurrentAppBridge.currentConnectionStatus();
      if (refreshed == ConnectionStatus.connected) {
        _applyStatus(refreshed);
      } else {
        _status = refreshed;
        _assignedIp = null;
        _errorMessage = 'Unable to establish connection.';
        notifyListeners();
      }
    } on VpnException catch (error) {
      _status = ConnectionStatus.disconnected;
      _assignedIp = null;
      _errorMessage = error.message;
      _connectedServerDisplayFallback = null;
      notifyListeners();
    } catch (_) {
      _status = ConnectionStatus.disconnected;
      _assignedIp = null;
      _errorMessage = 'Unable to establish connection.';
      _connectedServerDisplayFallback = null;
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
      _connectedServerDisplayFallback = null;
      unawaited(StorageService.clearVpnConnectedSince());
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
        final fallbackServer = _connectedServerDisplayFallback;
        _selectedServer = (fallbackServer == null ? null : _findMatchingServer(fallbackServer)) ?? _servers.first;
      }

      _persistSelectedServer(_selectedServer);

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
    _persistSelectedServer(matched);
    notifyListeners();
    unawaited(CurrentAppBridge.selectServerByNode(matched));
  }

  Future<void> _restorePersistedSessionState() async {
    final persistedServer = await StorageService.getLastSelectedVpnServer();
    final persistedConnectedSince = await StorageService.getVpnConnectedSince();

    var hasChanges = false;

    if (persistedServer != null) {
      _connectedServerDisplayFallback ??= persistedServer;
      if (!_matchesServer(_selectedServer, persistedServer)) {
        _selectedServer = persistedServer;
        hasChanges = true;
      }
    }

    if (_status == ConnectionStatus.connected) {
      if (persistedConnectedSince != null) {
        _connectedSince = persistedConnectedSince;
        hasChanges = true;
      } else if (_connectedSince != null) {
        _persistConnectedSince(_connectedSince!);
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  ServerModel _resolveDisplayServer(ServerModel activeServer) {
    for (final server in _servers) {
      if (_matchesServer(server, activeServer)) {
        return ServerModel(
          id: activeServer.id.isNotEmpty ? activeServer.id : server.id,
          name: _resolveDisplayName(activeServer.name, fallback: server.name),
          region: server.region.isNotEmpty ? server.region : activeServer.region,
          nodeId: server.nodeId.isNotEmpty ? server.nodeId : activeServer.nodeId,
          publicIp: server.publicIp.isNotEmpty ? server.publicIp : activeServer.publicIp,
          isAvailable: server.isAvailable,
        );
      }
    }

    final fallbackServer = _connectedServerDisplayFallback;
    if (fallbackServer != null && _isGenericProvisionedName(activeServer.name)) {
      return ServerModel(
        id: activeServer.id.isNotEmpty ? activeServer.id : fallbackServer.id,
        name: _resolveDisplayName(activeServer.name, fallback: fallbackServer.name),
        region: fallbackServer.region.isNotEmpty ? fallbackServer.region : activeServer.region,
        nodeId: fallbackServer.nodeId.isNotEmpty ? fallbackServer.nodeId : activeServer.nodeId,
        publicIp: fallbackServer.publicIp.isNotEmpty ? fallbackServer.publicIp : activeServer.publicIp,
        isAvailable: fallbackServer.isAvailable,
      );
    }

    return activeServer;
  }

  String _resolveDisplayName(String profileName, {required String fallback}) {
    final normalizedProfileName = profileName.trim();
    final normalizedFallback = fallback.trim();

    if (normalizedFallback.isNotEmpty && _isGenericProvisionedName(normalizedProfileName)) {
      return normalizedFallback;
    }

    if (normalizedProfileName.isNotEmpty) {
      return normalizedProfileName;
    }

    return normalizedFallback;
  }

  bool _isGenericProvisionedName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return false;
    }

    final upperCased = normalized.toUpperCase();
    return upperCased.startsWith('ONENET') || upperCased.startsWith('HIDDIFY');
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

  ServerModel? _findMatchingServer(ServerModel target) {
    for (final server in _servers) {
      if (_matchesServer(server, target)) {
        return server;
      }
    }
    return null;
  }

  void _applyStatus(ConnectionStatus status) {
    _status = status;

    if (status == ConnectionStatus.connected) {
      _connectedSince ??= DateTime.now();
      if (_connectedSince != null) {
        _persistConnectedSince(_connectedSince!);
      }
      _errorMessage = null;
      _needsVpnPermission = false;
      _startDurationTimer();
    } else if (status == ConnectionStatus.disconnected) {
      _connectedSince = null;
      _assignedIp = null;
      _durationTimer?.cancel();
      _connectedServerDisplayFallback = null;
      unawaited(StorageService.clearVpnConnectedSince());
    }

    notifyListeners();
  }

  void _persistConnectedSince(DateTime connectedSince) {
    unawaited(StorageService.saveVpnConnectedSince(connectedSince));
  }

  void _persistSelectedServer(ServerModel server) {
    _connectedServerDisplayFallback = server;
    unawaited(StorageService.saveLastSelectedVpnServer(server));
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
