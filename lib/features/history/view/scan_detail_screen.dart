import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';

/// Scan Detail Screen - Shows full details of a scanned document
/// 
/// Displays the scan image, extracted text, addresses, and metadata
class ScanDetailScreen extends StatelessWidget {
  final ScanModel scan;

  const ScanDetailScreen({
    super.key,
    required this.scan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.surfaceDark,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // Share functionality placeholder
          },
          icon: const Icon(Icons.share_rounded),
        ),
        IconButton(
          onPressed: () {
            // More options placeholder
          },
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImagePreview(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      color: AppColors.cardDark,
      child: scan.imagePath.isNotEmpty && File(scan.imagePath).existsSync()
          ? Image.file(
              File(scan.imagePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder();
              },
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Icon(
        Icons.description_rounded,
        size: 64,
        color: AppColors.textMuted,
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and date
          Row(
            children: [
              _StatusChip(status: scan.status),
              const Spacer(),
              Text(
                scan.formattedDate,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sender info
          if (scan.senderName != null || scan.senderAddress != null)
            _buildInfoCard(
              title: 'Sender',
              icon: Icons.person_outline_rounded,
              children: [
                if (scan.senderName != null)
                  _InfoRow(label: 'Name', value: scan.senderName!),
                if (scan.senderAddress != null)
                  _InfoRow(label: 'Address', value: scan.senderAddress!),
              ],
            ),

          // Recipient info
          if (scan.recipientName != null || scan.recipientAddress != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Recipient',
              icon: Icons.location_on_outlined,
              children: [
                if (scan.recipientName != null)
                  _InfoRow(label: 'Name', value: scan.recipientName!),
                if (scan.recipientAddress != null)
                  _InfoRow(label: 'Address', value: scan.recipientAddress!),
                if (scan.pincode != null)
                  _InfoRow(label: 'Pincode', value: scan.pincode!),
              ],
            ),
          ],

          // Extracted text
          if (scan.extractedText != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Extracted Text',
              icon: Icons.text_snippet_outlined,
              children: [
                Text(
                  scan.extractedText!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ],

          // No data message
          if (scan.senderName == null &&
              scan.recipientName == null &&
              scan.extractedText == null)
            _buildNoDataMessage(),

          const SizedBox(height: 32),

          // Actions
          _buildActions(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Processing Data',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            'The extracted data will appear here once processing is complete.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.copy_rounded,
            label: 'Copy Text',
            onPressed: () {
              // Copy to clipboard
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.edit_rounded,
            label: 'Edit',
            onPressed: () {
              // Edit functionality
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Export',
            onPressed: () {
              // Export functionality
            },
          ),
        ),
      ],
    );
  }
}

/// Status chip widget
class _StatusChip extends StatelessWidget {
  final ScanStatus status;

  const _StatusChip({required this.status});

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

  String get _label {
    switch (status) {
      case ScanStatus.processed:
        return 'Processed';
      case ScanStatus.pending:
        return 'Pending';
      case ScanStatus.processing:
        return 'Processing';
      case ScanStatus.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: AppTextStyles.caption.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info row widget
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
