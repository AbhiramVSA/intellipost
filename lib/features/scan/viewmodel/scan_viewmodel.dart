import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/models.dart';
import '../../../services/services.dart';

/// Scan ViewModel - Manages the entire scan workflow
/// 
/// Architecture Note: Handles camera state, image capture, API submission,
/// and result processing. All scan-related business logic lives here.
class ScanViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  ScanViewModel({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  // State
  ScanMode _scanMode = ScanMode.postCard;
  File? _capturedImage;
  bool _isProcessing = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  ScanModel? _lastScanResult;
  double _processingProgress = 0.0;

  // Getters
  ScanMode get scanMode => _scanMode;
  File? get capturedImage => _capturedImage;
  bool get isProcessing => _isProcessing;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  ScanModel? get lastScanResult => _lastScanResult;
  double get processingProgress => _processingProgress;
  bool get hasImage => _capturedImage != null;

  /// Set scan mode
  void setScanMode(ScanMode mode) {
    _scanMode = mode;
    notifyListeners();
  }

  /// Set captured image from camera or gallery
  void setImage(File image) {
    _capturedImage = image;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear captured image (retake)
  void clearImage() {
    _capturedImage = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Submit scan to API and save result
  Future<bool> submitScan() async {
    if (_capturedImage == null) {
      _errorMessage = 'No image to submit';
      notifyListeners();
      return false;
    }

    // Get auth token
    final authToken = _storageService.getAuthToken();
    if (authToken == null) {
      _errorMessage = 'Not authenticated. Please login again.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _processingProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate progress updates
      _startProgressSimulation();

      // Call API with the 3-step upload flow
      final response = await _apiService.uploadScan(_capturedImage!, authToken);

      if (response.isSuccess && response.data != null) {
        // Convert API result to local model (with pending status)
        final scanModel = response.data!.toScanModel(_capturedImage!.path);
        
        // Save to local storage
        await _storageService.saveScan(scanModel);
        
        _lastScanResult = scanModel;
        _processingProgress = 1.0;
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.error ?? 'Failed to process scan';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Simulate progress for UX
  void _startProgressSimulation() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_isSubmitting && _processingProgress < 0.3) {
        _processingProgress = 0.3;
        notifyListeners();
      }
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_isSubmitting && _processingProgress < 0.6) {
        _processingProgress = 0.6;
        notifyListeners();
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_isSubmitting && _processingProgress < 0.9) {
        _processingProgress = 0.9;
        notifyListeners();
      }
    });
  }

  /// Create a pending scan (for when image is captured but not submitted)
  Future<ScanModel> createPendingScan(String imagePath) async {
    final scan = ScanModel(
      id: const Uuid().v4(),
      imagePath: imagePath,
      createdAt: DateTime.now(),
      statusIndex: ScanStatus.pending.index,
      scanType: _scanMode.name,
    );
    
    await _storageService.saveScan(scan);
    return scan;
  }

  /// Reset scan state
  void reset() {
    _capturedImage = null;
    _isProcessing = false;
    _isSubmitting = false;
    _errorMessage = null;
    _lastScanResult = null;
    _processingProgress = 0.0;
    _scanMode = ScanMode.postCard;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Scan mode options
enum ScanMode {
  postCard('Post card');

  final String label;
  const ScanMode(this.label);
}
