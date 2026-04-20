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

class CloudStoragePanel extends StatefulWidget {
  const CloudStoragePanel({super.key});

  @override
  State<CloudStoragePanel> createState() => _CloudStoragePanelState();
}

class _CloudStoragePanelState extends State<CloudStoragePanel> {
  String? _lastToken;

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
                  loading: storage.isBusy,
                ),
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
                onDownload: (file) => storage.downloadAndShare(token, file),
                onDelete: (file) => storage.deleteFile(token, file),
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
  final bool loading;

  const _StorageActions({required this.onUpload, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
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
  final void Function(CloudStorageFileModel file) onDownload;
  final void Function(CloudStorageFileModel file) onDelete;

  const _StorageFilesList({
    required this.files,
    required this.enabled,
    required this.busy,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return Text(
        enabled ? 'No files yet. Upload your first file.' : 'Cloud storage actions are locked on the free plan.',
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

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.file, size: 16, color: AppColors.accentBright),
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
                    Text(
                      '${_formatBytes(file.sizeBytes)}${_lastUpdated(file.lastModified)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: enabled && !busy ? () => onDownload(file) : null,
                icon: const Icon(LucideIcons.download, size: 16),
                color: AppColors.accentBright,
                tooltip: 'Download',
              ),
              IconButton(
                onPressed: enabled && !busy ? () => onDelete(file) : null,
                icon: const Icon(LucideIcons.trash2, size: 16),
                color: AppColors.error,
                tooltip: 'Delete',
              ),
            ],
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
