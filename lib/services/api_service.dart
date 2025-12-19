import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/scan_model.dart';

/// API Service for handling all backend communication
/// Currently uses mock/placeholder responses for development
/// 
/// Architecture Note: This service is abstracted to allow easy swap
/// to real API endpoints when backend is ready.
abstract class ApiService {
  Future<ApiResponse<ScanResult>> uploadScan(File image);
  Future<ApiResponse<List<ScanResult>>> getScanHistory();
  Future<ApiResponse<ScanResult>> getScanDetails(String scanId);
}

/// Mock implementation of API Service
/// Replace with real implementation when backend is ready
class MockApiService implements ApiService {
  // API Configuration - Update these when real backend is available
  static const String baseUrl = 'https://api.intellipost.example.com/v1';
  static const Duration timeout = Duration(seconds: 30);

  /// Simulates network delay for realistic UX testing
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Future<ApiResponse<ScanResult>> uploadScan(File image) async {
    try {
      await _simulateNetworkDelay();

      // In production, this would be:
      // final uri = Uri.parse('$baseUrl/scan');
      // final request = http.MultipartRequest('POST', uri)
      //   ..files.add(await http.MultipartFile.fromPath('image', image.path));
      // final response = await request.send().timeout(timeout);

      // Mock successful response
      final mockResult = ScanResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        extractedText: 'Sample extracted text from the scanned letter.\n\n'
            'From: John Doe\n'
            '123 Main Street\n'
            'Mumbai, Maharashtra 400001\n\n'
            'To: Jane Smith\n'
            '456 Park Avenue\n'
            'Delhi, NCR 110001',
        senderName: 'John Doe',
        senderAddress: '123 Main Street, Mumbai, Maharashtra',
        recipientName: 'Jane Smith',
        recipientAddress: '456 Park Avenue, Delhi, NCR',
        pincode: '110001',
        confidence: 0.92,
        processedAt: DateTime.now(),
      );

      return ApiResponse.success(mockResult);
    } catch (e) {
      return ApiResponse.error('Failed to upload scan: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<List<ScanResult>>> getScanHistory() async {
    try {
      await _simulateNetworkDelay();

      // Mock history response
      final mockHistory = [
        ScanResult(
          id: '1',
          extractedText: 'Previous scan content...',
          senderName: 'Previous Sender',
          recipientName: 'Previous Recipient',
          processedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      return ApiResponse.success(mockHistory);
    } catch (e) {
      return ApiResponse.error('Failed to fetch history: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<ScanResult>> getScanDetails(String scanId) async {
    try {
      await _simulateNetworkDelay();

      // Mock scan details
      final mockResult = ScanResult(
        id: scanId,
        extractedText: 'Detailed scan content...',
        senderName: 'Sender Name',
        senderAddress: 'Sender Full Address',
        recipientName: 'Recipient Name',
        recipientAddress: 'Recipient Full Address',
        pincode: '400001',
        confidence: 0.95,
        processedAt: DateTime.now(),
      );

      return ApiResponse.success(mockResult);
    } catch (e) {
      return ApiResponse.error('Failed to fetch scan details: ${e.toString()}');
    }
  }
}

/// Real API Service implementation (for future use)
class RealApiService implements ApiService {
  final http.Client _client;
  static const String baseUrl = 'https://api.intellipost.example.com/v1';
  static const Duration timeout = Duration(seconds: 30);

  RealApiService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<ApiResponse<ScanResult>> uploadScan(File image) async {
    try {
      final uri = Uri.parse('$baseUrl/scan');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', image.path));

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(ScanResult.fromJson(json));
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to upload scan: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<List<ScanResult>>> getScanHistory() async {
    try {
      final uri = Uri.parse('$baseUrl/scans');
      final response = await _client.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        final results = jsonList
            .map((json) => ScanResult.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(results);
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to fetch history: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<ScanResult>> getScanDetails(String scanId) async {
    try {
      final uri = Uri.parse('$baseUrl/scans/$scanId');
      final response = await _client.get(uri).timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(ScanResult.fromJson(json));
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to fetch scan details: ${e.toString()}');
    }
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  ApiResponse._({
    this.data,
    this.error,
    this.statusCode,
    required this.isSuccess,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(data: data, isSuccess: true, statusCode: 200);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse._(
      error: message,
      isSuccess: false,
      statusCode: statusCode,
    );
  }
}

/// Scan result from API
class ScanResult {
  final String id;
  final String? extractedText;
  final String? senderName;
  final String? senderAddress;
  final String? recipientName;
  final String? recipientAddress;
  final String? pincode;
  final double? confidence;
  final DateTime processedAt;

  ScanResult({
    required this.id,
    this.extractedText,
    this.senderName,
    this.senderAddress,
    this.recipientName,
    this.recipientAddress,
    this.pincode,
    this.confidence,
    required this.processedAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] as String,
      extractedText: json['extractedText'] as String?,
      senderName: json['senderName'] as String?,
      senderAddress: json['senderAddress'] as String?,
      recipientName: json['recipientName'] as String?,
      recipientAddress: json['recipientAddress'] as String?,
      pincode: json['pincode'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      processedAt: DateTime.parse(json['processedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'extractedText': extractedText,
      'senderName': senderName,
      'senderAddress': senderAddress,
      'recipientName': recipientName,
      'recipientAddress': recipientAddress,
      'pincode': pincode,
      'confidence': confidence,
      'processedAt': processedAt.toIso8601String(),
    };
  }

  /// Convert API result to local ScanModel
  ScanModel toScanModel(String imagePath) {
    return ScanModel(
      id: id,
      imagePath: imagePath,
      createdAt: processedAt,
      statusIndex: ScanStatus.processed.index,
      extractedText: extractedText,
      senderName: senderName,
      senderAddress: senderAddress,
      recipientName: recipientName,
      recipientAddress: recipientAddress,
      pincode: pincode,
      apiResponse: jsonEncode(toJson()),
    );
  }
}
