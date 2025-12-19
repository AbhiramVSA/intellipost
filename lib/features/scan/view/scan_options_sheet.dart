import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../viewmodel/scan_viewmodel.dart';
import 'camera_screen.dart';
import 'preview_screen.dart';

/// Scan Options Bottom Sheet - Adobe Scan style
/// 
/// Shows available scan actions when user taps the scan FAB
class ScanOptionsSheet extends StatefulWidget {
  const ScanOptionsSheet({super.key});

  @override
  State<ScanOptionsSheet> createState() => _ScanOptionsSheetState();
}

class _ScanOptionsSheetState extends State<ScanOptionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late Animation<double> _fadeAnimation;

  final List<_ScanOption> _options = [
    _ScanOption(
      icon: Icons.photo_library_rounded,
      label: 'Create from photos',
      isPremium: false,
      onTap: () {},
    ),
    _ScanOption(
      icon: Icons.camera_alt_rounded,
      label: 'Create scan',
      isPremium: false,
      isHighlighted: true,
      onTap: () {},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Create staggered animations for each option
    _slideAnimations = List.generate(_options.length, (index) {
      final start = index * 0.1;
      final end = start + 0.6;
      return Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        ),
      );
    });

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: _fadeAnimation.value * 0.95),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(),
                // Options list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: List.generate(_options.length, (index) {
                      return SlideTransition(
                        position: _slideAnimations[index],
                        child: _buildOptionItem(_options[index], index),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                // Close button
                _buildCloseButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(_ScanOption option, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MicroInteractionButton(
        onPressed: () {
          Navigator.pop(context);
          if (option.label == 'Create scan') {
            _navigateToCamera();
          } else if (option.label == 'Create from photos') {
            _pickFromGallery();
          }
        },
        backgroundColor: AppColors.cardDark.withValues(alpha: 0.9),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: option.isHighlighted
                  ? AppColors.accent
                  : AppColors.textPrimary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option.label,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  color: option.isHighlighted
                      ? AppColors.textPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (option.isPremium)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.accent,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accentLight, AppColors.accent],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.close_rounded,
          color: AppColors.backgroundDark,
          size: 28,
        ),
      ),
    );
  }

  void _navigateToCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        final File imageFile = File(image.path);
        final viewModel = context.read<ScanViewModel>();
        viewModel.setImage(imageFile);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PreviewScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _ScanOption {
  final IconData icon;
  final String label;
  final bool isPremium;
  final bool isHighlighted;
  final VoidCallback onTap;

  _ScanOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPremium = false,
    this.isHighlighted = false,
  });
}

/// AnimatedBuilder helper
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
