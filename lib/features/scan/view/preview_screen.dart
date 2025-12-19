import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodel/scan_viewmodel.dart';

/// Preview Screen - Review captured image before submission
/// 
/// Shows the captured document with retake and confirm options.
/// Handles API submission with loading state.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ScanViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Image preview
          _buildImagePreview(viewModel),

          // Controls overlay
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(viewModel),
                const Spacer(),
                if (!viewModel.isSubmitting) _buildBottomControls(viewModel),
              ],
            ),
          ),

          // Loading overlay
          if (viewModel.isSubmitting) _buildLoadingOverlay(viewModel),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ScanViewModel viewModel) {
    if (viewModel.capturedImage == null) {
      return const Center(
        child: Text(
          'No image captured',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          viewModel.capturedImage!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTopBar(ScanViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () {
              viewModel.clearImage();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardDark.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          // Edit options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDark.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildToolButton(Icons.crop_rotate_rounded, 'Crop'),
                const SizedBox(width: 16),
                _buildToolButton(Icons.tune_rounded, 'Adjust'),
                const SizedBox(width: 16),
                _buildToolButton(Icons.auto_fix_high_rounded, 'Enhance'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        // Tool functionality placeholder
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label - Coming soon'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ScanViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.backgroundDark.withValues(alpha: 0.8),
            AppColors.backgroundDark,
          ],
        ),
      ),
      child: Row(
        children: [
          // Retake button
          Expanded(
            child: _ActionButton(
              icon: Icons.replay_rounded,
              label: 'Retake',
              onPressed: () {
                viewModel.clearImage();
                Navigator.pop(context);
              },
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 16),
          // Confirm button
          Expanded(
            child: _ActionButton(
              icon: Icons.check_rounded,
              label: 'Confirm & Send',
              onPressed: () => _submitScan(viewModel),
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(ScanViewModel viewModel) {
    return Container(
      color: AppColors.backgroundDark.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Processing scan...',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: viewModel.processingProgress,
                      backgroundColor: AppColors.cardDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(viewModel.processingProgress * 100).toInt()}%',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Extracting text and addresses...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitScan(ScanViewModel viewModel) async {
    final success = await viewModel.submitScan();

    if (!mounted) return;

    if (success) {
      // Show success and navigate to history
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan processed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate back to home (history will show the new scan)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Failed to process scan'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _submitScan(viewModel),
          ),
        ),
      );
    }
  }
}

/// Action button for preview screen
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
                    colors: [AppColors.accentLight, AppColors.accent],
                  )
                : null,
            color: widget.isPrimary ? null : AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.isPrimary
                    ? AppColors.backgroundDark
                    : AppColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.button.copyWith(
                  color: widget.isPrimary
                      ? AppColors.backgroundDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
