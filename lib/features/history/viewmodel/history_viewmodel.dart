import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/services.dart';

/// History ViewModel - Manages scan history state
/// 
/// Architecture Note: Provides scan history data, filtering,
/// and sorting capabilities to the view.
class HistoryViewModel extends ChangeNotifier {
  final StorageService _storageService;

  HistoryViewModel({required StorageService storageService})
      : _storageService = storageService {
    loadHistory();
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

  /// Load scan history from storage
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    // TODO: Replace with API call to fetch scans from server
    // For now, show empty list until endpoint is provided
    _scans = [];
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

  /// Get scan by ID
  ScanModel? getScan(String id) {
    return _storageService.getScan(id);
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
