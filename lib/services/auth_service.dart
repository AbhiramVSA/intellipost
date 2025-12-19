import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Authentication Service for handling login and registration API calls
/// 
/// Base URL: http://44.222.223.134/
/// Endpoints:
/// - POST /api/v1/auth/register - Register new user
/// - POST /api/v1/auth/login - Login user
class AuthService {
  final http.Client _client;
  static const String baseUrl = 'http://44.222.223.134';
  static const Duration timeout = Duration(seconds: 30);

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  /// Register a new user
  /// 
  /// Request body:
  /// {
  ///   "username": "string",
  ///   "email": "user@example.com",
  ///   "password": "string"
  /// }
  /// 
  /// Returns [AuthResponse] with user data on success
  Future<AuthResponse<RegisterResponse>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/auth/register');
      final requestBody = jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      });
      
      debugPrint('=== REGISTER REQUEST ===');
      debugPrint('URL: $uri');
      debugPrint('Body: $requestBody');
      
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(timeout);

      debugPrint('=== REGISTER RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.success(RegisterResponse.fromJson(json));
      } else if (response.statusCode == 422) {
        // Validation error
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error = ValidationError.fromJson(json);
        return AuthResponse.validationError(error);
      } else {
        // Try to parse error message from response body
        String errorMessage = 'Registration failed: ${response.statusCode}';
        try {
          final json = jsonDecode(response.body);
          if (json is Map<String, dynamic>) {
            errorMessage = json['detail']?.toString() ?? 
                           json['message']?.toString() ?? 
                           json['error']?.toString() ?? 
                           response.body;
          } else {
            errorMessage = response.body;
          }
        } catch (_) {
          errorMessage = response.body.isNotEmpty 
              ? response.body 
              : 'Registration failed: ${response.statusCode}';
        }
        return AuthResponse.error(
          errorMessage,
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return AuthResponse.error('No internet connection');
    } on http.ClientException catch (e) {
      return AuthResponse.error('Network error: ${e.message}');
    } catch (e) {
      return AuthResponse.error('Registration failed: ${e.toString()}');
    }
  }

  /// Login user and get access token
  /// 
  /// Request body:
  /// {
  ///   "email": "user@example.com",
  ///   "password": "string"
  /// }
  /// 
  /// Returns access token string on success
  Future<AuthResponse<String>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/auth/login');
      final requestBody = jsonEncode({
        'email': email,
        'password': password,
      });
      
      debugPrint('=== LOGIN REQUEST ===');
      debugPrint('URL: $uri');
      debugPrint('Body: $requestBody');
      
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(timeout);

      debugPrint('=== LOGIN RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        // Response format: {"access_token": "...", "token_type": "bearer"}
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final token = json['access_token'] as String;
        return AuthResponse.success(token);
      } else if (response.statusCode == 422) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error = ValidationError.fromJson(json);
        return AuthResponse.validationError(error);
      } else if (response.statusCode == 401) {
        return AuthResponse.error('Invalid username or password');
      } else {
        return AuthResponse.error(
          'Login failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return AuthResponse.error('No internet connection');
    } on http.ClientException catch (e) {
      return AuthResponse.error('Network error: ${e.message}');
    } catch (e) {
      return AuthResponse.error('Login failed: ${e.toString()}');
    }
  }
}

/// Generic authentication response wrapper
class AuthResponse<T> {
  final T? data;
  final String? error;
  final ValidationError? validationError;
  final int? statusCode;
  final bool isSuccess;

  AuthResponse._({
    this.data,
    this.error,
    this.validationError,
    this.statusCode,
    required this.isSuccess,
  });

  factory AuthResponse.success(T data) {
    return AuthResponse._(data: data, isSuccess: true, statusCode: 200);
  }

  factory AuthResponse.error(String message, {int? statusCode}) {
    return AuthResponse._(
      error: message,
      isSuccess: false,
      statusCode: statusCode,
    );
  }

  factory AuthResponse.validationError(ValidationError error) {
    return AuthResponse._(
      validationError: error,
      error: error.message,
      isSuccess: false,
      statusCode: 422,
    );
  }

  /// Get error message (either from error string or validation error)
  String? get errorMessage {
    if (validationError != null) {
      return validationError!.message;
    }
    return error;
  }
}

/// Register response model
/// {
///   "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
///   "username": "string",
///   "email": "user@example.com"
/// }
class RegisterResponse {
  final String id;
  final String username;
  final String email;

  RegisterResponse({
    required this.id,
    required this.username,
    required this.email,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}

/// Validation error response model
/// {
///   "detail": [
///     {
///       "loc": ["string", 0],
///       "msg": "string",
///       "type": "string"
///     }
///   ]
/// }
class ValidationError {
  final List<ValidationErrorDetail> details;

  ValidationError({required this.details});

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    final detailList = json['detail'] as List<dynamic>?;
    if (detailList == null) {
      return ValidationError(details: []);
    }
    return ValidationError(
      details: detailList
          .map((e) => ValidationErrorDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get a human-readable error message
  String get message {
    if (details.isEmpty) {
      return 'Validation failed';
    }
    return details.map((d) => d.message).join(', ');
  }
}

/// Single validation error detail
class ValidationErrorDetail {
  final List<dynamic> location;
  final String message;
  final String type;

  ValidationErrorDetail({
    required this.location,
    required this.message,
    required this.type,
  });

  factory ValidationErrorDetail.fromJson(Map<String, dynamic> json) {
    return ValidationErrorDetail(
      location: json['loc'] as List<dynamic>? ?? [],
      message: json['msg'] as String? ?? 'Unknown error',
      type: json['type'] as String? ?? 'unknown',
    );
  }

  /// Get the field name from location
  String? get fieldName {
    if (location.isEmpty) return null;
    // Location is usually like ["body", "email"] or ["body", "password"]
    return location.last.toString();
  }
}
