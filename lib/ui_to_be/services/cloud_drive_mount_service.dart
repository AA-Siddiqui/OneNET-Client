import 'dart:io';

import 'package:hiddify/ui_to_be/config/app_constants.dart';
import 'package:hiddify/ui_to_be/services/cloud_storage_service.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:path_provider/path_provider.dart';

Future<void> writeToFile(String text) async {
  // 1. Get the application documents directory
  final directory = await getApplicationDocumentsDirectory();

  // 2. Create a reference to the file
  final file = File('${directory.path}/my_file.txt');

  // 3. Write the string to the file
  await file.writeAsString(text);
}

class CloudDriveMountService {
  static const String _mountUser = 'onenet';
  static const Duration _commandTimeout = Duration(seconds: 20);

  static Future<void> ensureMounted(String? token) async {
    if (!PlatformUtils.isWindows) {
      return;
    }

    final normalizedToken = token?.trim() ?? '';
    if (normalizedToken.isEmpty) {
      return;
    }

    final driveLetter = _normalizedDriveLetter();
    if (driveLetter == null) {
      return;
    }

    try {
      final access = await CloudStorageService.fetchAccess(normalizedToken);
      if (!access.hasStorageAccess) {
        await _deleteMapping(driveLetter);
        return;
      }
    } catch (_) {
      await _deleteMapping(driveLetter);
      return;
    }

    await _deleteMapping(driveLetter);
    await _createMapping(driveLetter, normalizedToken);
  }

  static Future<void> unmount() async {
    if (!PlatformUtils.isWindows) {
      return;
    }

    final driveLetter = _normalizedDriveLetter();
    if (driveLetter == null) {
      return;
    }

    await _deleteMapping(driveLetter);
  }

  static String? _normalizedDriveLetter() {
    final raw = AppConstants.cloudDriveLetter.trim().toUpperCase();
    final driveLetterPattern = RegExp(r'^[A-Z]$');
    if (!driveLetterPattern.hasMatch(raw)) {
      return null;
    }
    return raw;
  }

  static Future<void> _createMapping(String driveLetter, String token) async {
    final mountEndpoint = AppConstants.storageWebDavEndpoint.trim();
    if (mountEndpoint.isEmpty) {
      return;
    }

    final parsedEndpoint = Uri.tryParse(mountEndpoint);
    final targets = <String>[mountEndpoint];
    final uncTarget = parsedEndpoint == null ? null : _toWebDavUncPath(parsedEndpoint);
    if (uncTarget != null && uncTarget != mountEndpoint) {
      targets.add(uncTarget);
    }

    for (final target in targets) {
      await Process.run(
        'schtasks /create /tn "CreateTask" /tr "cmd.exe /c net use $driveLetter: $target /user:$_mountUser $token /persistent:no" /sc once /st 00:00 /rl LIMITED',
        [],
        runInShell: true,
      ).timeout(_commandTimeout, onTimeout: () => ProcessResult(0, 124, '', 'timeout'));
      final result = await Process.run(
        'schtasks /run /tn "CreateTask"',
        [],
        runInShell: true,
      ).timeout(_commandTimeout, onTimeout: () => ProcessResult(0, 124, '', 'timeout'));

      writeToFile(
        "net use $driveLetter: $target /user:$_mountUser $token /persistent:no => ${result.exitCode} ${result.stdout} ${result.stderr}",
      );

      if (result.exitCode == 0) {
        return;
      }
    }
  }

  static Future<void> _deleteMapping(String driveLetter) async {
    try {
      await Process.run(
        'schtasks /create /tn "DeleteTask" /tr "cmd.exe /c net use $driveLetter: /delete /y" /sc once /st 00:00 /rl LIMITED',
        [],
        runInShell: true,
      ).timeout(_commandTimeout, onTimeout: () => ProcessResult(0, 124, '', 'timeout'));
      await Process.run(
        'schtasks /run /tn "DeleteTask"',
        [],
        runInShell: true,
      ).timeout(_commandTimeout, onTimeout: () => ProcessResult(0, 124, '', 'timeout'));
    } catch (_) {}
  }

  static String? _toWebDavUncPath(Uri endpoint) {
    final scheme = endpoint.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return null;
    }

    final host = endpoint.host.trim();
    if (host.isEmpty) {
      return null;
    }

    final isHttps = scheme == 'https';
    final defaultPort = isHttps ? 443 : 80;
    final hostPart = StringBuffer()..write(host);
    if (isHttps) {
      hostPart.write('@SSL');
    }
    if (endpoint.hasPort && endpoint.port != defaultPort) {
      hostPart.write('@${endpoint.port}');
    }

    final pathSegments = endpoint.pathSegments.where((segment) => segment.trim().isNotEmpty).toList(growable: false);
    final pathSuffix = pathSegments.isEmpty ? '' : '\\${pathSegments.join('\\')}';
    return '\\\\$hostPart\\DavWWWRoot$pathSuffix';
  }
}
