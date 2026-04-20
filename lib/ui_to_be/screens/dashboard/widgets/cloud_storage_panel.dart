import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hiddify/ui_to_be/models/cloud_storage_access_model.dart';
import 'package:hiddify/ui_to_be/models/cloud_storage_file_model.dart';
import 'package:hiddify/ui_to_be/providers/auth_provider.dart';
import 'package:hiddify/ui_to_be/providers/cloud_storage_provider.dart';
import 'package:hiddify/ui_to_be/services/url_launcher_service.dart';
import 'package:hiddify/ui_to_be/theme/app_colors.dart';
import 'package:hiddify/ui_to_be/theme/app_text_styles.dart';
import 'package:hiddify/ui_to_be/widgets/common/glow_container.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

enum _EntryAction { open, download, copy, move, delete }

class _StorageBreadcrumb {
  final String label;
  final String path;

  const _StorageBreadcrumb({required this.label, required this.path});
}

class _RelocateSelection {
  final String destinationPath;
  final String? newName;

  const _RelocateSelection({required this.destinationPath, required this.newName});
}

class CloudStoragePanel extends StatefulWidget {
  const CloudStoragePanel({super.key});

  @override
  State<CloudStoragePanel> createState() => _CloudStoragePanelState();
}

class _CloudStoragePanelState extends State<CloudStoragePanel> {
  String? _lastToken;

  List<_StorageBreadcrumb> _buildBreadcrumbs(String currentPath) {
    final normalized = currentPath.trim();
    if (normalized.isEmpty) {
      return const [_StorageBreadcrumb(label: 'root', path: '')];
    }

    final segments = normalized.split('/').where((segment) => segment.trim().isNotEmpty).toList(growable: false);
    final breadcrumbs = <_StorageBreadcrumb>[const _StorageBreadcrumb(label: 'root', path: '')];

    var runningPath = '';
    for (final segment in segments) {
      runningPath = runningPath.isEmpty ? segment : '$runningPath/$segment';
      breadcrumbs.add(_StorageBreadcrumb(label: segment, path: runningPath));
    }

    return breadcrumbs;
  }

  Future<void> _handleCreateFolder(String? token, CloudStorageProvider storage) async {
    final controller = TextEditingController();

    final folderName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Folder name', hintText: 'Example: Mods'),
            onSubmitted: (_) => Navigator.of(dialogContext).pop(controller.text.trim()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    final value = folderName?.trim() ?? '';
    if (value.isEmpty) {
      return;
    }

    await storage.createFolder(token, value);
  }

  Future<bool> _confirmDelete(CloudStorageFileModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(entry.isFolder ? 'Delete Folder' : 'Delete File'),
          content: Text(
            entry.isFolder
                ? 'Delete ${entry.name} and all nested contents?'
                : 'Delete ${entry.name}? This cannot be undone.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<_RelocateSelection?> _showRelocateDialog({
    required CloudStorageFileModel entry,
    required String currentPath,
    required bool move,
  }) {
    final destinationController = TextEditingController(text: currentPath);
    final nameController = TextEditingController();

    return showDialog<_RelocateSelection>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${move ? 'Move' : 'Copy'} ${entry.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: destinationController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Destination folder path',
                  hintText: 'Leave empty for root',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'New name (optional)',
                  hintText: 'Keep empty to preserve current name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  _RelocateSelection(
                    destinationPath: destinationController.text.trim(),
                    newName: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                  ),
                );
              },
              child: Text(move ? 'Move' : 'Copy'),
            ),
          ],
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final token = context.read<AuthProvider>().token;
    if (_lastToken == token) {
      return;
    }

    _lastToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<CloudStorageProvider>().refresh(token, force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CloudStorageProvider>(
      builder: (context, auth, storage, _) {
        final token = auth.token;
        final access = storage.access;
        final hasStorage = access?.hasStorageAccess == true;
        final breadcrumbs = _buildBreadcrumbs(storage.currentPath);

        return GlowContainer(
          borderColor: hasStorage ? AppColors.accent.withValues(alpha: 0.5) : AppColors.gold.withValues(alpha: 0.35),
          showGlow: hasStorage,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasStorage ? AppColors.accentGlow : AppColors.goldDim,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      LucideIcons.cloud,
                      color: hasStorage ? AppColors.accentBright : AppColors.gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CLOUD STORAGE',
                          style: AppTextStyles.heading3.copyWith(
                            color: hasStorage ? AppColors.accentBright : AppColors.gold,
                          ),
                        ),
                        Text(
                          hasStorage ? 'Upload and download game files' : 'Visible on all plans, active on Pro',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: storage.isLoading || storage.isBusy ? null : () => storage.refresh(token, force: true),
                    icon: Icon(
                      LucideIcons.refreshCcw,
                      size: 18,
                      color: storage.isLoading ? AppColors.textDim : AppColors.accentBright,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StorageUsageBar(access: access),
              const SizedBox(height: 12),
              if (!hasStorage)
                _ProRequiredBanner(
                  message: access?.message ?? 'Pro plan is required for cloud storage.',
                  onUpgrade: () => UrlLauncherService.openPlans(),
                )
              else
                _StorageActions(
                  onUpload: storage.isBusy ? null : () => storage.uploadFromPicker(token),
                  onCreateFolder: storage.isBusy ? null : () => _handleCreateFolder(token, storage),
                  onNavigateUp: storage.isBusy || storage.isAtRoot ? null : () => storage.navigateUp(token),
                  canNavigateUp: !storage.isAtRoot,
                  loading: storage.isBusy,
                ),
              if (hasStorage) ...[
                const SizedBox(height: 10),
                _StoragePathBar(
                  breadcrumbs: breadcrumbs,
                  onNavigate: (path) => storage.navigateToPath(token, path),
                  busy: storage.isBusy || storage.isLoading,
                ),
              ],
              if (storage.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(storage.errorMessage!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ],
              if (storage.statusMessage != null) ...[
                const SizedBox(height: 8),
                Text(storage.statusMessage!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.success)),
              ],
              const SizedBox(height: 12),
              _StorageFilesList(
                files: storage.files,
                enabled: hasStorage && !storage.isLoading,
                busy: storage.isBusy,
                onOpenFolder: (entry) => storage.openFolder(token, entry),
                onDownload: (entry) => storage.downloadAndShare(token, entry),
                onDelete: (entry) async {
                  final confirmed = await _confirmDelete(entry);
                  if (!confirmed) {
                    return;
                  }
                  await storage.deleteEntry(token, entry);
                },
                onCopy: (entry) async {
                  final selection = await _showRelocateDialog(
                    entry: entry,
                    currentPath: storage.currentPath,
                    move: false,
                  );
                  if (selection == null) {
                    return;
                  }
                  await storage.copyEntry(
                    token,
                    entry,
                    destinationPath: selection.destinationPath,
                    newName: selection.newName,
                  );
                },
                onMove: (entry) async {
                  final selection = await _showRelocateDialog(
                    entry: entry,
                    currentPath: storage.currentPath,
                    move: true,
                  );
                  if (selection == null) {
                    return;
                  }
                  await storage.moveEntry(
                    token,
                    entry,
                    destinationPath: selection.destinationPath,
                    newName: selection.newName,
                  );
                },
              ),
              if (storage.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.accentBright)),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms);
      },
    );
  }
}

class _StoragePathBar extends StatelessWidget {
  final List<_StorageBreadcrumb> breadcrumbs;
  final Future<void> Function(String path) onNavigate;
  final bool busy;

  const _StoragePathBar({required this.breadcrumbs, required this.onNavigate, required this.busy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < breadcrumbs.length; index += 1) ...[
              TextButton(
                onPressed: busy ? null : () => onNavigate(breadcrumbs[index].path),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentBright,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
                child: Text(
                  breadcrumbs[index].label,
                  style: AppTextStyles.monoSmall.copyWith(color: AppColors.accentBright),
                ),
              ),
              if (index < breadcrumbs.length - 1)
                Text('/', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StorageUsageBar extends StatelessWidget {
  final CloudStorageAccessModel? access;

  const _StorageUsageBar({required this.access});

  @override
  Widget build(BuildContext context) {
    final int usedBytes = access?.usedBytes ?? 0;
    final int quotaBytes = access?.quotaBytes ?? 0;
    final double ratio = access?.usageRatio ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('USAGE', style: AppTextStyles.monoSmall.copyWith(color: AppColors.textDim)),
            Text(
              '${_formatBytes(usedBytes)} / ${_formatBytes(quotaBytes)}',
              style: AppTextStyles.monoSmall.copyWith(color: AppColors.textBright),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: AppColors.border.withValues(alpha: 0.4),
            color: ratio > 0.9 ? AppColors.gold : AppColors.accentBright,
          ),
        ),
      ],
    );
  }
}

class _StorageActions extends StatelessWidget {
  final VoidCallback? onUpload;
  final VoidCallback? onCreateFolder;
  final VoidCallback? onNavigateUp;
  final bool canNavigateUp;
  final bool loading;

  const _StorageActions({
    required this.onUpload,
    required this.onCreateFolder,
    required this.onNavigateUp,
    required this.canNavigateUp,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onUpload,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentBright,
            side: BorderSide(color: AppColors.accent.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accentBright),
                )
              : const Icon(LucideIcons.upload, size: 16),
          label: Text('Upload File', style: AppTextStyles.mono.copyWith(color: AppColors.accentBright)),
        ),
        OutlinedButton.icon(
          onPressed: onCreateFolder,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentBright,
            side: BorderSide(color: AppColors.accent.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: const Icon(LucideIcons.folderPlus, size: 16),
          label: Text('New Folder', style: AppTextStyles.mono.copyWith(color: AppColors.accentBright)),
        ),
        OutlinedButton.icon(
          onPressed: canNavigateUp ? onNavigateUp : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textBright,
            side: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          icon: const Icon(LucideIcons.arrowUp, size: 16),
          label: Text('Up', style: AppTextStyles.mono.copyWith(color: AppColors.textBright)),
        ),
      ],
    );
  }
}

class _ProRequiredBanner extends StatelessWidget {
  final String message;
  final VoidCallback onUpgrade;

  const _ProRequiredBanner({required this.message, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.goldDim,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onUpgrade,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: Text('View Pro Plan', style: AppTextStyles.mono.copyWith(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }
}

class _StorageFilesList extends StatelessWidget {
  final List<CloudStorageFileModel> files;
  final bool enabled;
  final bool busy;
  final Future<void> Function(CloudStorageFileModel file) onOpenFolder;
  final Future<void> Function(CloudStorageFileModel file) onDownload;
  final Future<void> Function(CloudStorageFileModel file) onDelete;
  final Future<void> Function(CloudStorageFileModel file) onCopy;
  final Future<void> Function(CloudStorageFileModel file) onMove;

  const _StorageFilesList({
    required this.files,
    required this.enabled,
    required this.busy,
    required this.onOpenFolder,
    required this.onDownload,
    required this.onDelete,
    required this.onCopy,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Text(
        enabled
            ? 'Folder is empty. Upload files or create a new folder.'
            : 'Cloud storage actions are locked on the free plan.',
        style: AppTextStyles.bodySmall,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = files[index];
        final icon = file.isFolder ? LucideIcons.folder : LucideIcons.file;

        final details = file.isFolder
            ? 'Folder${_lastUpdated(file.lastModified)}'
            : '${_formatBytes(file.sizeBytes)}${_lastUpdated(file.lastModified)}';

        return InkWell(
          onTap: enabled && !busy && file.isFolder ? () => onOpenFolder(file) : null,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: file.isFolder ? AppColors.gold : AppColors.accentBright),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textBright),
                      ),
                      Text(details, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                if (file.isFolder)
                  IconButton(
                    onPressed: enabled && !busy ? () => onOpenFolder(file) : null,
                    icon: const Icon(LucideIcons.folderOpen, size: 16),
                    color: AppColors.gold,
                    tooltip: 'Open Folder',
                  ),
                IconButton(
                  onPressed: enabled && !busy ? () => onDownload(file) : null,
                  icon: Icon(file.isFolder ? LucideIcons.archive : LucideIcons.download, size: 16),
                  color: AppColors.accentBright,
                  tooltip: file.isFolder ? 'Download ZIP' : 'Download',
                ),
                PopupMenuButton<_EntryAction>(
                  enabled: enabled && !busy,
                  tooltip: 'More actions',
                  onSelected: (action) async {
                    switch (action) {
                      case _EntryAction.open:
                        await onOpenFolder(file);
                      case _EntryAction.download:
                        await onDownload(file);
                      case _EntryAction.copy:
                        await onCopy(file);
                      case _EntryAction.move:
                        await onMove(file);
                      case _EntryAction.delete:
                        await onDelete(file);
                    }
                  },
                  itemBuilder: (_) {
                    final items = <PopupMenuEntry<_EntryAction>>[];
                    if (file.isFolder) {
                      items.add(
                        const PopupMenuItem<_EntryAction>(value: _EntryAction.open, child: Text('Open Folder')),
                      );
                    }
                    items.addAll([
                      PopupMenuItem<_EntryAction>(
                        value: _EntryAction.download,
                        child: Text(file.isFolder ? 'Download ZIP' : 'Download'),
                      ),
                      const PopupMenuItem<_EntryAction>(value: _EntryAction.copy, child: Text('Copy')),
                      const PopupMenuItem<_EntryAction>(value: _EntryAction.move, child: Text('Move')),
                      const PopupMenuDivider(),
                      const PopupMenuItem<_EntryAction>(value: _EntryAction.delete, child: Text('Delete')),
                    ]);
                    return items;
                  },
                  icon: const Icon(LucideIcons.moreVertical, size: 16),
                  color: AppColors.surface,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _lastUpdated(DateTime? value) {
    if (value == null) {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return ' · just now';
    if (diff.inHours < 1) return ' · ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return ' · ${diff.inHours}h ago';
    return ' · ${diff.inDays}d ago';
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }

  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double value = bytes.toDouble();
  int unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }

  final hasFraction = value < 10 && unitIndex > 0;
  final formatted = hasFraction ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
  return '$formatted ${units[unitIndex]}';
}
