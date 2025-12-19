import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/services.dart';

/// Home ViewModel - Manages state for the home screen
/// 
/// Architecture Note: Provides scan data and user info to the view,
/// handles navigation state for bottom nav.
class HomeViewModel extends ChangeNotifier {
  final StorageService _storageService;

  HomeViewModel({required StorageService storageService})
      : _storageService = storageService {
    _loadData();
  }

  // State
  int _currentNavIndex = 0;
  List<ScanModel> _recentScans = [];
  UserModel? _currentUser;
  bool _isLoading = false;

  // Getters
  int get currentNavIndex => _currentNavIndex;
  List<ScanModel> get recentScans => _recentScans;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get hasScans => _recentScans.isNotEmpty;
  int get totalScans => _recentScans.length;

  /// Load initial data
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = _storageService.getUser();
    _recentScans = _storageService.getAllScans();

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh data
  Future<void> refresh() async {
    await _loadData();
  }

  /// Update navigation index
  void setNavIndex(int index) {
    if (_currentNavIndex != index) {
      _currentNavIndex = index;
      notifyListeners();
    }
  }

  /// Get greeting based on time of day
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Get user's first name
  String get firstName {
    if (_currentUser == null) return 'User';
    final name = _currentUser!.name;
    return name.split(' ').first;
  }

  /// Logout user
  Future<void> logout() async {
    await _storageService.logout();
    notifyListeners();
  }
}
