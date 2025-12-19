import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../models/models.dart';
import '../viewmodel/history_viewmodel.dart';
import 'scan_detail_screen.dart';

/// History Screen - List of all scanned documents
/// 
/// Design Note: Shows scan history with thumbnails, status badges,
/// and date/time info. Supports filtering and sorting.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HistoryViewModel(
        storageService: context.read(),
        apiService: context.read(),
      ),
      child: const _HistoryScreenContent(),
    );
  }
}

class _HistoryScreenContent extends StatelessWidget {
  const _HistoryScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryViewModel>();

    return Column(
      children: [
        _buildHeader(context, viewModel),
        Expanded(
          child: _buildContent(context, viewModel),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, HistoryViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'All scans',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Multi-select button
          IconButton(
            onPressed: () {
              // Multi-select functionality placeholder
            },
            icon: const Icon(
              Icons.check_box_outline_blank_rounded,
              color: AppColors.textMuted,
            ),
          ),
          // New folder button
          IconButton(
            onPressed: () {
              // Create folder functionality placeholder
            },
            icon: const Icon(
              Icons.create_new_folder_outlined,
              color: AppColors.textMuted,
            ),
          ),
          // Sort button
          IconButton(
            onPressed: () => _showSortOptions(context, viewModel),
            icon: const Icon(
              Icons.sort_rounded,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HistoryViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (!viewModel.hasScans) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: viewModel.scans.length,
        itemBuilder: (context, index) {
          final scan = viewModel.scans[index];
          return _ScanHistoryItem(
            scan: scan,
            onTap: () => _openScanDetails(context, scan),
            onDelete: () => _confirmDelete(context, viewModel, scan),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ScanIllustration(size: 160),
          const SizedBox(height: 24),
          Text(
            "You don't have any scans",
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start a new scan from your camera or imported photos.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context, HistoryViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SortOptionsSheet(
        currentSort: viewModel.sortOption,
        onSortSelected: (option) {
          viewModel.setSortOption(option);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openScanDetails(BuildContext context, ScanModel scan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanDetailScreen(scan: scan),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    HistoryViewModel viewModel,
    ScanModel scan,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Delete Scan',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this scan? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.deleteScan(scan.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Individual scan history item
class _ScanHistoryItem extends StatelessWidget {
  final ScanModel scan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScanHistoryItem({
    required this.scan,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(scan.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete_rounded,
            color: AppColors.error,
          ),
        ),
        confirmDismiss: (direction) async {
          onDelete();
          return false;
        },
        child: MicroInteractionButton(
          onPressed: onTap,
          backgroundColor: AppColors.cardDark,
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Thumbnail
              _buildThumbnail(),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.senderName ?? 'Scanned Document',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scan.formattedDate,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              _StatusBadge(status: scan.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final isPending = scan.status == ScanStatus.pending || 
                      scan.status == ScanStatus.processing;
    
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColorFiltered(
          colorFilter: isPending
              ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
          child: Opacity(
            opacity: isPending ? 0.5 : 1.0,
            child: _buildImageWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (scan.imagePath.isEmpty) {
      return const Icon(
        Icons.description_rounded,
        color: AppColors.textMuted,
      );
    }

    // Check if it's a URL (from API) or local file path
    if (scan.imagePath.startsWith('http://') || scan.imagePath.startsWith('https://')) {
      return Image.network(
        scan.imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.description_rounded,
            color: AppColors.textMuted,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textMuted,
              ),
            ),
          );
        },
      );
    } else if (File(scan.imagePath).existsSync()) {
      return Image.file(
        File(scan.imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.description_rounded,
            color: AppColors.textMuted,
          );
        },
      );
    } else {
      return const Icon(
        Icons.description_rounded,
        color: AppColors.textMuted,
      );
    }
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final ScanStatus status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case ScanStatus.processed:
        return AppColors.success;
      case ScanStatus.pending:
      case ScanStatus.processing:
        return AppColors.warning;
      case ScanStatus.failed:
        return AppColors.error;
    }
  }

  IconData get _icon {
    switch (status) {
      case ScanStatus.processed:
        return Icons.check_circle_rounded;
      case ScanStatus.pending:
      case ScanStatus.processing:
        return Icons.hourglass_empty_rounded;
      case ScanStatus.failed:
        return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _icon,
        color: _color,
        size: 20,
      ),
    );
  }
}

/// Sort options bottom sheet
class _SortOptionsSheet extends StatelessWidget {
  final HistorySortOption currentSort;
  final Function(HistorySortOption) onSortSelected;

  const _SortOptionsSheet({
    required this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sort by',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 16),
          ...HistorySortOption.values.map((option) {
            final isSelected = option == currentSort;
            return ListTile(
              leading: Icon(
                _getSortIcon(option),
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              title: Text(
                option.label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => onSortSelected(option),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getSortIcon(HistorySortOption option) {
    switch (option) {
      case HistorySortOption.newest:
        return Icons.arrow_downward_rounded;
      case HistorySortOption.oldest:
        return Icons.arrow_upward_rounded;
      case HistorySortOption.status:
        return Icons.filter_list_rounded;
    }
  }
}
