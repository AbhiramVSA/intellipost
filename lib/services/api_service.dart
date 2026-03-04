import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../models/scan_model.dart';

/// Contract for mail scanning API operations.
abstract class ApiService {
  Future<ApiResponse<MailProcessResponse>> uploadScan(File image, String authToken);
  Future<ApiResponse<List<MailProcessResponse>>> getMails(String authToken, {int limit = 20, int offset = 0});
  Future<ApiResponse<MailProcessResponse>> getMail(String mailId, String authToken);
  Future<ApiResponse<UploadUrlResponse>> generateUploadUrl(String authToken);
  Future<ApiResponse<MailProcessResponse>> processImage(String fileKey, String authToken);
  Future<void> uploadImageToPresignedUrl(String uploadUrl, File image);
}

class RealApiService extends ApiService {
  final http.Client _client;

  RealApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String authToken) => {
    'Accept': 'application/json',
    'Authorization': authToken,
  };

  /// Three-step upload flow: generate URL -> upload image -> process.
  @override
  Future<ApiResponse<MailProcessResponse>> uploadScan(File image, String authToken) async {
    try {
      // Step 1: Get presigned upload URL
      final uploadUrlResponse = await generateUploadUrl(authToken);
      if (!uploadUrlResponse.isSuccess || uploadUrlResponse.data == null) {
        return ApiResponse.error(
          uploadUrlResponse.error ?? 'Failed to generate upload URL',
          statusCode: uploadUrlResponse.statusCode,
        );
      }

      final urlData = uploadUrlResponse.data!;
      debugPrint('[API] Upload URL generated for key: ${urlData.fileKey}');

      // Step 2: Upload image to presigned URL
      await uploadImageToPresignedUrl(urlData.uploadUrl, image);

      // Step 3: Process the uploaded image
      return await processImage(urlData.fileKey, authToken);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to upload scan: $e');
    }
  }

  @override
  Future<ApiResponse<List<MailProcessResponse>>> getMails(
    String authToken, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/mails/').replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client
          .get(uri, headers: _headers(authToken))
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        final results = jsonList
            .map((json) => MailProcessResponse.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(results);
      }
      return ApiResponse.error('Server error: ${response.statusCode}', statusCode: response.statusCode);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to fetch mails: $e');
    }
  }

  @override
  Future<ApiResponse<MailProcessResponse>> getMail(String mailId, String authToken) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/mails/$mailId');

      final response = await _client
          .get(uri, headers: _headers(authToken))
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(MailProcessResponse.fromJson(json));
      } else if (response.statusCode == 404) {
        return ApiResponse.error('Mail not found', statusCode: 404);
      }
      return ApiResponse.error('Server error: ${response.statusCode}', statusCode: response.statusCode);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to fetch mail: $e');
    }
  }

  @override
  Future<ApiResponse<UploadUrlResponse>> generateUploadUrl(String authToken) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/mails/generate_upload_url');

      final response = await _client
          .post(uri, headers: _headers(authToken))
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(UploadUrlResponse.fromJson(json));
      }
      return ApiResponse.error('Server error: ${response.statusCode}', statusCode: response.statusCode);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to generate upload URL: $e');
    }
  }

  @override
  Future<ApiResponse<MailProcessResponse>> processImage(String fileKey, String authToken) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/v1/mails/process').replace(
        queryParameters: {'file_key': fileKey},
      );

      final response = await _client
          .post(uri, headers: _headers(authToken))
          .timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(MailProcessResponse.fromJson(json));
      } else if (response.statusCode == 422) {
        return ApiResponse.error('Validation error', statusCode: 422);
      }
      return ApiResponse.error('Server error: ${response.statusCode}', statusCode: response.statusCode);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to process image: $e');
    }
  }

  @override
  Future<void> uploadImageToPresignedUrl(String uploadUrl, File image) async {
    final bytes = await image.readAsBytes();

    final response = await _client
        .put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': 'image/jpeg'},
          body: bytes,
        )
        .timeout(AppConfig.uploadTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Upload failed with status: ${response.statusCode}');
    }
  }
}

/// Generic API response wrapper.
class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  ApiResponse._({this.data, this.error, this.statusCode, required this.isSuccess});

  factory ApiResponse.success(T data) =>
      ApiResponse._(data: data, isSuccess: true, statusCode: 200);

  factory ApiResponse.error(String message, {int? statusCode}) =>
      ApiResponse._(error: message, isSuccess: false, statusCode: statusCode);
}

/// Presigned upload URL response.
class UploadUrlResponse {
  final String uploadUrl;
  final String fileKey;

  UploadUrlResponse({required this.uploadUrl, required this.fileKey});

  factory UploadUrlResponse.fromJson(Map<String, dynamic> json) {
    return UploadUrlResponse(
      uploadUrl: json['upload_url'] as String,
      fileKey: json['file_key'] as String,
    );
  }
}

/// Mail processing response from the API.
class MailProcessResponse {
  final String id;
  final String userId;
  final String imageS3Key;
  final String imageUrl;
  final String status;
  final String? senderName;
  final String? senderAddress;
  final String? senderPincode;
  final String? receiverName;
  final String? receiverAddress;
  final String? receiverPincode;
  final String? assignedSortingCenter;
  final String? rawAiResponse;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MailProcessResponse({
    required this.id,
    required this.userId,
    required this.imageS3Key,
    required this.imageUrl,
    required this.status,
    this.senderName,
    this.senderAddress,
    this.senderPincode,
    this.receiverName,
    this.receiverAddress,
    this.receiverPincode,
    this.assignedSortingCenter,
    this.rawAiResponse,
    required this.createdAt,
    this.updatedAt,
  });

  factory MailProcessResponse.fromJson(Map<String, dynamic> json) {
    String? rawAiResponseStr;
    if (json['raw_ai_response'] != null) {
      rawAiResponseStr = json['raw_ai_response'] is Map
          ? jsonEncode(json['raw_ai_response'])
          : json['raw_ai_response'].toString();
    }

    return MailProcessResponse(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageS3Key: json['image_s3_key'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      status: json['status'] as String,
      senderName: json['sender_name'] as String?,
      senderAddress: json['sender_address'] as String?,
      senderPincode: json['sender_pincode'] as String?,
      receiverName: json['receiver_name'] as String?,
      receiverAddress: json['receiver_address'] as String?,
      receiverPincode: json['receiver_pincode'] as String?,
      assignedSortingCenter: json['assigned_sorting_center'] as String?,
      rawAiResponse: rawAiResponseStr,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'image_s3_key': imageS3Key,
    'image_url': imageUrl,
    'status': status,
    'sender_name': senderName,
    'sender_address': senderAddress,
    'sender_pincode': senderPincode,
    'receiver_name': receiverName,
    'receiver_address': receiverAddress,
    'receiver_pincode': receiverPincode,
    'assigned_sorting_center': assignedSortingCenter,
    'raw_ai_response': rawAiResponse,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  /// Convert to ScanModel for local storage.
  ScanModel toScanModel(String imagePath) {
    return ScanModel(
      id: id,
      imagePath: imagePath,
      createdAt: createdAt,
      statusIndex: _statusToIndex(status),
      extractedText: rawAiResponse,
      senderName: senderName,
      senderAddress: senderAddress,
      recipientName: receiverName,
      recipientAddress: receiverAddress,
      pincode: receiverPincode,
      apiResponse: jsonEncode(toJson()),
    );
  }

  static int _statusToIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ScanStatus.pending.index;
      case 'processing':
        return ScanStatus.processing.index;
      case 'processed':
      case 'completed':
        return ScanStatus.processed.index;
      case 'failed':
        return ScanStatus.failed.index;
      default:
        return ScanStatus.pending.index;
    }
  }
}
