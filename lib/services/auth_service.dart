import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/config.dart';

/// Handles authentication API calls (login and registration).
class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  static const _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<AuthResponse<RegisterResponse>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/register');

      final response = await _client
          .post(uri, headers: _jsonHeaders, body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
          }))
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.success(RegisterResponse.fromJson(json));
      } else if (response.statusCode == 422) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.validationError(ValidationError.fromJson(json));
      } else {
        return AuthResponse.error(
          _extractErrorMessage(response, 'Registration failed'),
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return AuthResponse.error('No internet connection');
    } on http.ClientException catch (e) {
      return AuthResponse.error('Network error: ${e.message}');
    } catch (e) {
      return AuthResponse.error('Registration failed: $e');
    }
  }

  Future<AuthResponse<String>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/auth/login');

      final response = await _client
          .post(uri, headers: _jsonHeaders, body: jsonEncode({
            'email': email,
            'password': password,
          }))
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.success(json['access_token'] as String);
      } else if (response.statusCode == 422) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.validationError(ValidationError.fromJson(json));
      } else if (response.statusCode == 401) {
        return AuthResponse.error('Invalid username or password');
      }
      return AuthResponse.error('Login failed: ${response.statusCode}', statusCode: response.statusCode);
    } on SocketException {
      return AuthResponse.error('No internet connection');
    } on http.ClientException catch (e) {
      return AuthResponse.error('Network error: ${e.message}');
    } catch (e) {
      return AuthResponse.error('Login failed: $e');
    }
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        return json['detail']?.toString() ??
            json['message']?.toString() ??
            json['error']?.toString() ??
            response.body;
      }
      return response.body;
    } catch (_) {
      return response.body.isNotEmpty ? response.body : '$fallback: ${response.statusCode}';
    }
  }
}

/// Generic authentication response wrapper.
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

  factory AuthResponse.success(T data) =>
      AuthResponse._(data: data, isSuccess: true, statusCode: 200);

  factory AuthResponse.error(String message, {int? statusCode}) =>
      AuthResponse._(error: message, isSuccess: false, statusCode: statusCode);

  factory AuthResponse.validationError(ValidationError error) => AuthResponse._(
    validationError: error,
    error: error.message,
    isSuccess: false,
    statusCode: 422,
  );

  String? get errorMessage => validationError?.message ?? error;
}

class RegisterResponse {
  final String id;
  final String username;
  final String email;

  RegisterResponse({required this.id, required this.username, required this.email});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }
}

class ValidationError {
  final List<ValidationErrorDetail> details;

  ValidationError({required this.details});

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    final detailList = json['detail'] as List<dynamic>?;
    if (detailList == null) return ValidationError(details: []);
    return ValidationError(
      details: detailList
          .map((e) => ValidationErrorDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get message {
    if (details.isEmpty) return 'Validation failed';
    return details.map((d) => d.message).join(', ');
  }
}

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

  String? get fieldName => location.isEmpty ? null : location.last.toString();
}
