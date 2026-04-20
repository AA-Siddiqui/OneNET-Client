import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hiddify/ui_to_be/models/cloud_storage_access_model.dart';
import 'package:hiddify/ui_to_be/models/cloud_storage_file_model.dart';
import 'package:hiddify/ui_to_be/services/cloud_storage_service.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:share_plus/share_plus.dart';

class CloudStorageProvider extends ChangeNotifier {
  CloudStorageAccessModel? _access;
  List<CloudStorageFileModel> _files = const [];
  String _currentPath = '';
  bool _isLoading = false;
  bool _isBusy = false;
  String? _errorMessage;
  String? _statusMessage;
  String? _activeToken;

  CloudStorageAccessModel? get access => _access;
  List<CloudStorageFileModel> get files => _files;
  String get currentPath => _currentPath;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  bool get isAtRoot => _currentPath.trim().isEmpty;

  Future<void> refresh(String? token, {bool force = false, String? path}) async {
    if (_isLoading) {
      return;
    }

    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty) {
      _activeToken = null;
      _access = null;
      _files = const [];
      _currentPath = '';
      _errorMessage = null;
      _statusMessage = null;
      notifyListeners();
      return;
    }

    final requestedPath = _normalizePath(path ?? _currentPath);

    if (!force && _activeToken == normalized && _access != null && requestedPath == _currentPath) {
      return;
    }

    _activeToken = normalized;
    _isLoading = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      final access = await CloudStorageService.fetchAccess(normalized);
      _access = access;

      if (!access.hasStorageAccess) {
        _files = const [];
        _currentPath = '';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final fileState = await CloudStorageService.fetchFiles(normalized, path: requestedPath);
      _files = fileState.files;
      _currentPath = _normalizePath(fileState.currentPath);
      _access = access.copyWith(usedBytes: fileState.usedBytes, quotaBytes: fileState.quotaBytes);
    } on CloudStorageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load cloud storage right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> navigateToPath(String? token, String path) async {
    await refresh(token, force: true, path: path);
  }

  Future<void> navigateUp(String? token) async {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty || _isBusy || _isLoading) {
      return;
    }

    final parent = _parentPath(_currentPath);
    await refresh(normalized, force: true, path: parent);
  }

  Future<void> openFolder(String? token, CloudStorageFileModel folder) async {
    if (!folder.isFolder) {
      return;
    }

    await refresh(token, force: true, path: folder.key);
  }

  Future<void> uploadFromPicker(String? token) async {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty || _isBusy) {
      return;
    }

    final access = _access;
    if (access == null || !access.hasStorageAccess) {
      _errorMessage = access?.message ?? 'Pro plan is required for cloud storage.';
      notifyListeners();
      return;
    }

    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      final latestAccess = await _ensureProAccess(normalized);

      final picked = await FilePicker.platform.pickFiles(withData: true);
      if (picked == null || picked.files.isEmpty) {
        _statusMessage = 'Upload cancelled.';
        return;
      }

      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const CloudStorageException('Unable to read selected file.');
      }

      if (bytes.length > latestAccess.remainingBytes) {
        throw const CloudStorageException('Not enough storage left in your 10GB Pro quota.');
      }

      final fileName = (file.name.isEmpty ? 'upload.bin' : file.name).trim();
      await CloudStorageService.uploadFile(token: normalized, fileName: fileName, bytes: bytes, path: _currentPath);

      _statusMessage = '$fileName uploaded successfully.';
      await refresh(normalized, force: true, path: _currentPath);
    } on CloudStorageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Upload failed. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> createFolder(String? token, String folderName) async {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty || _isBusy) {
      return;
    }

    final trimmedName = folderName.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Folder name cannot be empty.';
      notifyListeners();
      return;
    }

    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      await _ensureProAccess(normalized);
      await CloudStorageService.createFolder(token: normalized, path: _joinPath(_currentPath, trimmedName));
      _statusMessage = 'Created folder $trimmedName';
      await refresh(normalized, force: true, path: _currentPath);
    } on CloudStorageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Failed to create folder. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> downloadToLocal(String? token, CloudStorageFileModel entry) async {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty || _isBusy) {
      return;
    }

    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      await _ensureProAccess(normalized);
      final downloaded = await _downloadEntry(normalized, entry);
      final bytes = Uint8List.fromList(downloaded.bytes);

      final outputFile = await FilePicker.platform.saveFile(fileName: downloaded.fileName, bytes: bytes);

      if (outputFile == null) {
        _statusMessage = 'Download cancelled.';
        return;
      }

      if (PlatformUtils.isDesktop) {
        final file = File(outputFile);
        if (!await file.exists()) {
          await file.parent.create(recursive: true);
        }
        await file.writeAsBytes(bytes);
      }

      _statusMessage = outputFile.trim().isEmpty
          ? 'Saved ${downloaded.fileName} locally.'
          : 'Saved ${downloaded.fileName} to $outputFile';
    } on CloudStorageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Download failed. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> shareEntry(String? token, CloudStorageFileModel entry) async {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty || _isBusy) {
      return;
    }

    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      await _ensureProAccess(normalized);
      final downloaded = await _downloadEntry(normalized, entry);
      final xFile = XFile.fromData(
        Uint8List.fromList(downloaded.bytes),
        name: downloaded.fileName,
        mimeType: downloaded.contentType,
      );
      final result = await Share.shareXFiles([xFile], text: 'Shared from OneNET cloud storage');
      _statusMessage = result.status == ShareResultStatus.dismissed
          ? 'Share cancelled.'
          : 'Shared ${downloaded.fileName}';
    } on CloudStorageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Share failed. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<DownloadedCloudFile> _downloadEntry(String token, CloudStorageFileModel entry) {
    if (entry.isFolder) {
      return CloudStorageService.downloadFolderAsZip(token: token, folderPath: entry.key);
    }
    return CloudStorageService.downloadFile(token: token, fileKey: entry.key);
  }

  Future<void> deleteEntry(String? token, CloudStorageFileModel entry) async {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty || _isBusy) {
      return;
    }

    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      await _ensureProAccess(normalized);
      if (entry.isFolder) {
        await CloudStorageService.deleteFolder(token: normalized, path: entry.key);
      } else {
        await CloudStorageService.deleteFile(token: normalized, fileKey: entry.key);
      }
      _statusMessage = 'Deleted ${entry.name}';
      await refresh(normalized, force: true, path: _currentPath);
    } on CloudStorageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Delete failed. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> copyEntry(
    String? token,
    CloudStorageFileModel entry, {
    required String destinationPath,
    String? newName,
  }) async {
    await _relocateEntry(token, entry, destinationPath: destinationPath, newName: newName, move: false);
  }

  Future<void> moveEntry(
    String? token,
    CloudStorageFileModel entry, {
    required String destinationPath,
    String? newName,
  }) async {
    await _relocateEntry(token, entry, destinationPath: destinationPath, newName: newName, move: true);
  }

  Future<void> _relocateEntry(
    String? token,
    CloudStorageFileModel entry, {
    required String destinationPath,
    String? newName,
    required bool move,
  }) async {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty || _isBusy) {
      return;
    }

    _isBusy = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      await _ensureProAccess(normalized);
      final destination = _normalizePath(destinationPath);
      if (move) {
        await CloudStorageService.moveItem(
          token: normalized,
          itemType: entry.isFolder ? 'folder' : 'file',
          sourcePath: entry.key,
          destinationPath: destination,
          newName: newName,
        );
      } else {
        await CloudStorageService.copyItem(
          token: normalized,
          itemType: entry.isFolder ? 'folder' : 'file',
          sourcePath: entry.key,
          destinationPath: destination,
          newName: newName,
        );
      }

      final action = move ? 'Moved' : 'Copied';
      _statusMessage = '$action ${entry.name}';
      await refresh(normalized, force: true, path: _currentPath);
    } on CloudStorageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '${move ? 'Move' : 'Copy'} failed. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<CloudStorageAccessModel> _ensureProAccess(String token) async {
    final freshAccess = await CloudStorageService.fetchAccess(token);
    _access = freshAccess;

    if (!freshAccess.hasStorageAccess) {
      throw CloudStorageException(freshAccess.message);
    }

    return _access!;
  }

  static String _normalizePath(String path) {
    final trimmed = path.trim().replaceAll('\\\\', '/');
    if (trimmed.isEmpty) {
      return '';
    }

    final segments = trimmed
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty && segment != '.' && segment != '..')
        .toList(growable: false);

    return segments.join('/');
  }

  static String _joinPath(String parent, String child) {
    final safeParent = _normalizePath(parent);
    final safeChild = _normalizePath(child);
    if (safeParent.isEmpty) {
      return safeChild;
    }
    if (safeChild.isEmpty) {
      return safeParent;
    }
    return '$safeParent/$safeChild';
  }

  static String _parentPath(String path) {
    final normalized = _normalizePath(path);
    if (normalized.isEmpty) {
      return '';
    }

    final divider = normalized.lastIndexOf('/');
    if (divider <= 0) {
      return '';
    }
    return normalized.substring(0, divider);
  }
}
