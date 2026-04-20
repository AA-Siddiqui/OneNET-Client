import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hiddify/ui_to_be/models/cloud_storage_access_model.dart';
import 'package:hiddify/ui_to_be/models/cloud_storage_file_model.dart';
import 'package:hiddify/ui_to_be/services/cloud_storage_service.dart';
import 'package:share_plus/share_plus.dart';

class CloudStorageProvider extends ChangeNotifier {
  CloudStorageAccessModel? _access;
  List<CloudStorageFileModel> _files = const [];
  bool _isLoading = false;
  bool _isBusy = false;
  String? _errorMessage;
  String? _statusMessage;
  String? _activeToken;

  CloudStorageAccessModel? get access => _access;
  List<CloudStorageFileModel> get files => _files;
  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  Future<void> refresh(String? token, {bool force = false}) async {
    if (_isLoading) {
      return;
    }

    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty) {
      _activeToken = null;
      _access = null;
      _files = const [];
      _errorMessage = null;
      _statusMessage = null;
      notifyListeners();
      return;
    }

    if (!force && _activeToken == normalized && _access != null) {
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
        _isLoading = false;
        notifyListeners();
        return;
      }

      final fileState = await CloudStorageService.fetchFiles(normalized);
      _files = fileState.files;
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
      await CloudStorageService.uploadFile(token: normalized, fileName: fileName, bytes: bytes);

      _statusMessage = '$fileName uploaded successfully.';
      await refresh(normalized, force: true);
    } on CloudStorageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Upload failed. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> downloadAndShare(String? token, CloudStorageFileModel file) async {
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
      final downloaded = await CloudStorageService.downloadFile(token: normalized, fileKey: file.key);
      final xFile = XFile.fromData(
        Uint8List.fromList(downloaded.bytes),
        name: file.name,
        mimeType: downloaded.contentType,
      );
      await Share.shareXFiles([xFile], text: 'Downloaded from OneNET cloud storage');
      _statusMessage = 'Downloaded ${file.name}';
    } on CloudStorageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Download failed. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> deleteFile(String? token, CloudStorageFileModel file) async {
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
      await CloudStorageService.deleteFile(token: normalized, fileKey: file.key);
      _statusMessage = 'Deleted ${file.name}';
      await refresh(normalized, force: true);
    } on CloudStorageException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Delete failed. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<CloudStorageAccessModel> _ensureProAccess(String token) async {
    final freshAccess = await CloudStorageService.fetchAccess(token);
    final previousUsed = _access?.usedBytes ?? 0;
    _access = freshAccess.copyWith(usedBytes: previousUsed);

    if (!freshAccess.hasStorageAccess) {
      throw CloudStorageException(freshAccess.message);
    }

    return _access!;
  }
}
