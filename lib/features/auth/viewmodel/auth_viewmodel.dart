import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/models.dart';
import '../../../services/services.dart';

/// Authentication ViewModel
/// Handles login validation and state management for the auth flow
/// 
/// Architecture Note: All business logic lives here, keeping the view clean.
/// Uses ChangeNotifier for reactive UI updates.
class AuthViewModel extends ChangeNotifier {
  final StorageService _storageService;

  AuthViewModel({required StorageService storageService})
      : _storageService = storageService;

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // State
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoginSuccessful = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoginSuccessful => _isLoginSuccessful;

  /// Validate name field
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate phone field
  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    // Indian phone number validation (10 digits)
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  /// Validate email field
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Attempt login with form validation
  Future<bool> login() async {
    _setLoading(true);
    _clearError();

    // Validate all fields
    final nameError = validateName(nameController.text);
    final phoneError = validatePhone(phoneController.text);
    final emailError = validateEmail(emailController.text);

    if (nameError != null || phoneError != null || emailError != null) {
      _setError(nameError ?? phoneError ?? emailError ?? 'Validation failed');
      _setLoading(false);
      return false;
    }

    try {
      // Simulate network delay for realistic UX
      await Future.delayed(const Duration(seconds: 2));

      // Create user model
      final user = UserModel(
        id: const Uuid().v4(),
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        createdAt: DateTime.now(),
        isLoggedIn: true,
      );

      // Save to local storage
      await _storageService.saveUser(user);

      _isLoginSuccessful = true;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Login failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Check if user is already logged in
  bool checkExistingSession() {
    return _storageService.isLoggedIn();
  }

  /// Get current user
  UserModel? getCurrentUser() {
    return _storageService.getUser();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear form and reset state
  void reset() {
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    _isLoading = false;
    _errorMessage = null;
    _isLoginSuccessful = false;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
