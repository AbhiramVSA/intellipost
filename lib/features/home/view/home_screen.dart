import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../history/view/history_screen.dart';
import '../../scan/view/scan_options_sheet.dart';
import '../viewmodel/home_viewmodel.dart';

/// Home Screen - Main hub of the application
/// 
/// Design Note: Dark UI inspired by Adobe Scan with empty state
/// illustration and floating scan button.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animate FAB entrance
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(viewModel),
            const Divider(color: AppColors.primary, height: 1),
            Expanded(
              child: _buildBody(viewModel),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: viewModel.currentNavIndex,
        onTap: viewModel.setNavIndex,
        onScanPressed: () => _showScanOptions(context),
      ),
    );
  }

  Widget _buildAppBar(HomeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mail_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          // Search button
          IconButton(
            onPressed: () {
              // TODO: Implement search
            },
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textPrimary,
            ),
          ),
          // Profile button
          GestureDetector(
            onTap: () => _showProfileMenu(context, viewModel),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textMuted,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(HomeViewModel viewModel) {
    // Show different screens based on nav index
    if (viewModel.currentNavIndex == 1) {
      return const HistoryScreen();
    }

    return _buildHomeContent(viewModel);
  }

  Widget _buildHomeContent(HomeViewModel viewModel) {
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

    return _buildRecentScans(viewModel);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ScanIllustration(size: 180),
          const SizedBox(height: 32),
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

  Widget _buildRecentScans(HomeViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${viewModel.greeting}, ${viewModel.firstName}',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 4),
          Text(
            '${viewModel.totalScans} scan${viewModel.totalScans != 1 ? 's' : ''} total',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Scans',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...viewModel.recentScans.take(5).map((scan) => _ScanListItem(
                scan: scan,
                onTap: () => _openScanDetails(scan),
              )),
        ],
      ),
    );
  }

  void _showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ScanOptionsSheet(),
    );
  }

  void _showProfileMenu(BuildContext context, HomeViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        // Store navigator reference before async operation
        final navigator = Navigator.of(sheetContext);
        return _ProfileSheet(
          viewModel: viewModel,
          onLogout: () async {
            await viewModel.logout();
            if (mounted) {
              navigator.pushReplacementNamed('/login');
            }
          },
        );
      },
    );
  }

  void _openScanDetails(dynamic scan) {
    Navigator.of(context).pushNamed('/scan-details', arguments: scan);
  }
}

/// Scan list item widget
class _ScanListItem extends StatelessWidget {
  final dynamic scan;
  final VoidCallback onTap;

  const _ScanListItem({
    required this.scan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MicroInteractionButton(
        onPressed: onTap,
        backgroundColor: AppColors.cardDark,
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Thumbnail placeholder
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanned Document',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scan.formattedDate,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            _StatusBadge(status: scan.statusText),
          ],
        ),
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'processed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: AppTextStyles.caption.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Profile bottom sheet
class _ProfileSheet extends StatelessWidget {
  final HomeViewModel viewModel;
  final VoidCallback onLogout;

  const _ProfileSheet({
    required this.viewModel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = viewModel.currentUser;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Profile info
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: AppTextStyles.h1.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onLogout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.2),
                foregroundColor: AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
