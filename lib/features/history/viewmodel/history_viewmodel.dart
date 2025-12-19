import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/services.dart';

/// History ViewModel - Manages scan history state
/// 
/// Architecture Note: Provides scan history data, filtering,
/// and sorting capabilities to the view. Fetches from API
/// and polls for pending items every 2 minutes.
class HistoryViewModel extends ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;
  Timer? _pollingTimer;
  String? _lastUploadedMailId;

  HistoryViewModel({
    required StorageService storageService,
    required ApiService apiService,
  })  : _storageService = storageService,
        _apiService = apiService {
    loadHistory();
    _startPolling();
  }

  // State
  List<ScanModel> _scans = [];
  List<ScanModel> _filteredScans = [];
  bool _isLoading = false;
  HistorySortOption _sortOption = HistorySortOption.newest;
  HistoryFilterOption _filterOption = HistoryFilterOption.all;

  // Getters
  List<ScanModel> get scans => _filteredScans;
  bool get isLoading => _isLoading;
  bool get hasScans => _filteredScans.isNotEmpty;
  int get totalScans => _scans.length;
  HistorySortOption get sortOption => _sortOption;
  HistoryFilterOption get filterOption => _filterOption;

  /// Set the last uploaded mail ID for polling
  void setLastUploadedMailId(String mailId) {
    _lastUploadedMailId = mailId;
  }

  /// Start polling for pending items every 2 minutes
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _pollPendingItems();
    });
  }

  /// Poll pending items to check for status updates
  Future<void> _pollPendingItems() async {
    final authToken = _storageService.getAuthToken();
    if (authToken == null) return;

    // Poll the last uploaded mail if it exists and is pending
    if (_lastUploadedMailId != null) {
      final response = await _apiService.getMail(_lastUploadedMailId!, authToken);
      if (response.isSuccess && response.data != null) {
        final mail = response.data!;
        if (mail.status != 'pending' && mail.status != 'processing') {
          // Mail is completed or failed, refresh the list
          _lastUploadedMailId = null;
          await loadHistory();
        }
      }
    }

    // Also check any pending items in our current list
    final pendingScans = _scans.where((s) => 
      s.status == ScanStatus.pending || s.status == ScanStatus.processing
    ).toList();

    bool hasUpdates = false;
    for (final scan in pendingScans) {
      final response = await _apiService.getMail(scan.id, authToken);
      if (response.isSuccess && response.data != null) {
        final mail = response.data!;
        if (mail.status != 'pending' && mail.status != 'processing') {
          hasUpdates = true;
          break;
        }
      }
    }

    if (hasUpdates) {
      await loadHistory();
    }
  }

  /// Load scan history from API
  Future<void> loadHistory() async {
    final authToken = _storageService.getAuthToken();
    if (authToken == null) {
      _scans = [];
      _applyFiltersAndSort();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final response = await _apiService.getMails(authToken, limit: 20, offset: 0);
    
    if (response.isSuccess && response.data != null) {
      _scans = response.data!.map((mail) => mail.toScanModel(mail.imageUrl)).toList();
    } else {
      // If API fails, show empty list
      _scans = [];
    }
    
    _applyFiltersAndSort();

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh history
  Future<void> refresh() async {
    await loadHistory();
  }

  /// Set sort option
  void setSortOption(HistorySortOption option) {
    if (_sortOption != option) {
      _sortOption = option;
      _applyFiltersAndSort();
      notifyListeners();
    }
  }

  /// Set filter option
  void setFilterOption(HistoryFilterOption option) {
    if (_filterOption != option) {
      _filterOption = option;
      _applyFiltersAndSort();
      notifyListeners();
    }
  }

  /// Apply current filters and sorting
  void _applyFiltersAndSort() {
    // Apply filter
    _filteredScans = _scans.where((scan) {
      switch (_filterOption) {
        case HistoryFilterOption.all:
          return true;
        case HistoryFilterOption.processed:
          return scan.status == ScanStatus.processed;
        case HistoryFilterOption.pending:
          return scan.status == ScanStatus.pending ||
              scan.status == ScanStatus.processing;
        case HistoryFilterOption.failed:
          return scan.status == ScanStatus.failed;
      }
    }).toList();

    // Apply sort
    switch (_sortOption) {
      case HistorySortOption.newest:
        _filteredScans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case HistorySortOption.oldest:
        _filteredScans.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case HistorySortOption.status:
        _filteredScans.sort((a, b) => a.statusIndex.compareTo(b.statusIndex));
        break;
    }
  }

  /// Delete a scan
  Future<void> deleteScan(String id) async {
    await _storageService.deleteScan(id);
    await loadHistory();
  }

  /// Delete multiple scans
  Future<void> deleteScans(List<String> ids) async {
    for (final id in ids) {
      await _storageService.deleteScan(id);
    }
    await loadHistory();
  }

  /// Get scan by ID from API
  Future<ScanModel?> getScan(String id) async {
    final authToken = _storageService.getAuthToken();
    if (authToken == null) return null;

    final response = await _apiService.getMail(id, authToken);
    if (response.isSuccess && response.data != null) {
      return response.data!.toScanModel(response.data!.imageUrl);
    }
    return null;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

/// Sort options for history
enum HistorySortOption {
  newest('Newest first'),
  oldest('Oldest first'),
  status('By status');

  final String label;
  const HistorySortOption(this.label);
}

/// Filter options for history
enum HistoryFilterOption {
  all('All'),
  processed('Processed'),
  pending('Pending'),
  failed('Failed');

  final String label;
  const HistoryFilterOption(this.label);
}
