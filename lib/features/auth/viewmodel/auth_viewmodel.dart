import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../../../services/services.dart';

/// Authentication mode
enum AuthMode { login, register }

/// Authentication ViewModel
/// Handles login and registration with real API calls
/// 
/// Architecture Note: All business logic lives here, keeping the view clean.
/// Uses ChangeNotifier for reactive UI updates.
class AuthViewModel extends ChangeNotifier {
  final StorageService _storageService;
  final AuthService _authService;

  AuthViewModel({
    required StorageService storageService,
    AuthService? authService,
  })  : _storageService = storageService,
        _authService = authService ?? AuthService();

  // Form controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Legacy controllers for backwards compatibility
  TextEditingController get nameController => usernameController;
  TextEditingController get phoneController => TextEditingController(); // Dummy for legacy

  // State
  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isLoginSuccessful = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Getters
  AuthMode get authMode => _authMode;
  bool get isLoginMode => _authMode == AuthMode.login;
  bool get isRegisterMode => _authMode == AuthMode.register;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isLoginSuccessful => _isLoginSuccessful;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  /// Toggle between login and register modes
  void toggleAuthMode() {
    _authMode = _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
    _clearError();
    _clearSuccess();
    notifyListeners();
  }

  /// Set auth mode explicitly
  void setAuthMode(AuthMode mode) {
    if (_authMode != mode) {
      _authMode = mode;
      _clearError();
      notifyListeners();
    }
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  /// Validate username field
  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your username';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Username must be less than 50 characters';
    }
    // Only allow alphanumeric and underscores
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  /// Validate name field (legacy - maps to username)
  String? validateName(String? value) => validateUsername(value);

  /// Validate phone field (legacy - always valid now)
  String? validatePhone(String? value) => null;

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

  /// Validate password field
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate confirm password field
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Attempt registration
  Future<bool> register() async {
    _setLoading(true);
    _clearError();

    // Validate all fields
    final usernameError = validateUsername(usernameController.text);
    final emailError = validateEmail(emailController.text);
    final passwordError = validatePassword(passwordController.text);
    final confirmPasswordError = validateConfirmPassword(confirmPasswordController.text);

    if (usernameError != null || emailError != null || 
        passwordError != null || confirmPasswordError != null) {
      _setError(usernameError ?? emailError ?? passwordError ?? 
                confirmPasswordError ?? 'Validation failed');
      _setLoading(false);
      return false;
    }

    try {
      final response = await _authService.register(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.isSuccess && response.data != null) {
        // Registration successful, now login to get token
        final loginResponse = await _authService.login(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (loginResponse.isSuccess && loginResponse.data != null) {
          // Create user model and save
          final user = UserModel(
            id: response.data!.id,
            name: response.data!.username,
            username: response.data!.username,
            phone: '',
            email: response.data!.email,
            createdAt: DateTime.now(),
            isLoggedIn: true,
            authToken: loginResponse.data,
          );

          await _storageService.saveUser(user);
          _isLoginSuccessful = true;
          _setLoading(false);
          notifyListeners();
          return true;
        } else {
          // Registration succeeded but login failed
          // Still consider it a success, user can login manually
          final user = UserModel(
            id: response.data!.id,
            name: response.data!.username,
            username: response.data!.username,
            phone: '',
            email: response.data!.email,
            createdAt: DateTime.now(),
            isLoggedIn: false,
          );

          await _storageService.saveUser(user);
          _setSuccess('Registration successful! Please login.');
          _authMode = AuthMode.login;
          // Pre-fill email for login
          emailController.text = response.data!.email;
          _setLoading(false);
          notifyListeners();
          return false;
        }
      } else {
        _setError(response.errorMessage ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Attempt login
  Future<bool> login() async {
    // If in register mode, call register instead
    if (_authMode == AuthMode.register) {
      return register();
    }

    _setLoading(true);
    _clearError();

    // For login, we need email/username and password
    final emailError = validateEmail(emailController.text);
    final passwordError = validatePassword(passwordController.text);

    if (emailError != null || passwordError != null) {
      _setError(emailError ?? passwordError ?? 'Validation failed');
      _setLoading(false);
      return false;
    }

    try {
      final response = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.isSuccess && response.data != null) {
        // Clear any old user data and create fresh user from login email
        final email = emailController.text.trim();
        final nameFromEmail = email.split('@').first;
        
        final user = UserModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameFromEmail,
          username: nameFromEmail,
          phone: '',
          email: email,
          createdAt: DateTime.now(),
          isLoggedIn: true,
          authToken: response.data,
        );

        await _storageService.saveUser(user);
        _isLoginSuccessful = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.errorMessage ?? 'Login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
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
    _successMessage = null;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// Clear form and reset state
  void reset() {
    usernameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _isLoading = false;
    _errorMessage = null;
    _successMessage = null;
    _isLoginSuccessful = false;
    _authMode = AuthMode.login;
    _obscurePassword = true;
    _obscureConfirmPassword = true;
    notifyListeners();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
