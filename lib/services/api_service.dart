import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/scan_model.dart';

/// API Service for handling all backend communication
/// 
/// Base URL: http://44.222.223.134/
/// Endpoints:
/// - POST /api/v1/mails/generate_upload_url - Get presigned URL for image upload
/// - POST /api/v1/mails/process - Process uploaded image
/// - GET /api/v1/mails/ - Get list of mails with pagination
/// - GET /api/v1/mails/{mail_id} - Get single mail by ID
abstract class ApiService {
  Future<ApiResponse<MailProcessResponse>> uploadScan(File image, String authToken);
  Future<ApiResponse<List<MailProcessResponse>>> getMails(String authToken, {int limit = 20, int offset = 0});
  Future<ApiResponse<MailProcessResponse>> getMail(String mailId, String authToken);
  Future<ApiResponse<UploadUrlResponse>> generateUploadUrl(String authToken);
  Future<ApiResponse<MailProcessResponse>> processImage(String fileKey, String authToken);
  Future<void> uploadImageToPresignedUrl(String uploadUrl, File image);
}

/// API Service implementation
class RealApiService extends ApiService {
  final http.Client _client;
  static const String baseUrl = 'http://44.222.223.134';
  static const Duration timeout = Duration(seconds: 30);

  RealApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Upload scan using the 3-step flow:
  /// 1. Generate presigned upload URL
  /// 2. Upload image to presigned URL
  /// 3. Process the uploaded image
  @override
  Future<ApiResponse<MailProcessResponse>> uploadScan(File image, String authToken) async {
    try {
      debugPrint('=== UPLOAD SCAN FLOW ===');
      
      // Step 1: Generate upload URL
      debugPrint('Step 1: Generating upload URL...');
      final uploadUrlResponse = await generateUploadUrl(authToken);
      if (!uploadUrlResponse.isSuccess || uploadUrlResponse.data == null) {
        return ApiResponse.error(
          uploadUrlResponse.error ?? 'Failed to generate upload URL',
          statusCode: uploadUrlResponse.statusCode,
        );
      }
      
      final uploadUrl = uploadUrlResponse.data!.uploadUrl;
      final fileKey = uploadUrlResponse.data!.fileKey;
      debugPrint('Got upload URL and file key: $fileKey');
      
      // Step 2: Upload image to presigned URL
      debugPrint('Step 2: Uploading image to presigned URL...');
      await uploadImageToPresignedUrl(uploadUrl, image);
      debugPrint('Image uploaded successfully');
      
      // Step 3: Process the uploaded image
      debugPrint('Step 3: Processing image...');
      final processResponse = await processImage(fileKey, authToken);
      
      return processResponse;
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to upload scan: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<List<MailProcessResponse>>> getMails(String authToken, {int limit = 20, int offset = 0}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/mails/')
          .replace(queryParameters: {
            'limit': limit.toString(),
            'offset': offset.toString(),
          });
      
      debugPrint('=== GET MAILS REQUEST ===');
      debugPrint('URL: $uri');
      
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': authToken,
        },
      ).timeout(timeout);

      debugPrint('=== GET MAILS RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        final results = jsonList
            .map((json) => MailProcessResponse.fromJson(json as Map<String, dynamic>))
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
      return ApiResponse.error('Failed to fetch mails: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<MailProcessResponse>> getMail(String mailId, String authToken) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/mails/$mailId');
      
      debugPrint('=== GET MAIL REQUEST ===');
      debugPrint('URL: $uri');
      
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': authToken,
        },
      ).timeout(timeout);

      debugPrint('=== GET MAIL RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(MailProcessResponse.fromJson(json));
      } else if (response.statusCode == 404) {
        return ApiResponse.error('Mail not found', statusCode: 404);
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to fetch mail: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<UploadUrlResponse>> generateUploadUrl(String authToken) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/mails/generate_upload_url');
      
      debugPrint('=== GENERATE UPLOAD URL REQUEST ===');
      debugPrint('URL: $uri');
      
      final response = await _client
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': authToken,
            },
          )
          .timeout(timeout);

      debugPrint('=== GENERATE UPLOAD URL RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(UploadUrlResponse.fromJson(json));
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to generate upload URL: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<MailProcessResponse>> processImage(String fileKey, String authToken) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/mails/process')
          .replace(queryParameters: {'file_key': fileKey});
      
      debugPrint('=== PROCESS IMAGE REQUEST ===');
      debugPrint('URL: $uri');
      
      final response = await _client
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': authToken,
            },
          )
          .timeout(timeout);

      debugPrint('=== PROCESS IMAGE RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(MailProcessResponse.fromJson(json));
      } else if (response.statusCode == 422) {
        return ApiResponse.error('Validation error', statusCode: 422);
      } else {
        return ApiResponse.error(
          'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to process image: ${e.toString()}');
    }
  }

  @override
  Future<void> uploadImageToPresignedUrl(String uploadUrl, File image) async {
    try {
      final bytes = await image.readAsBytes();
      
      debugPrint('=== UPLOAD TO PRESIGNED URL ===');
      debugPrint('URL: $uploadUrl');
      debugPrint('File size: ${bytes.length} bytes');
      
      final response = await _client
          .put(
            Uri.parse(uploadUrl),
            headers: {
              'Content-Type': 'image/jpeg',
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('=== UPLOAD RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
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

/// Response from generate_upload_url endpoint
/// {
///   "upload_url": "https://...",
///   "file_key": "user_uploads/..."
/// }
class UploadUrlResponse {
  final String uploadUrl;
  final String fileKey;

  UploadUrlResponse({
    required this.uploadUrl,
    required this.fileKey,
  });

  factory UploadUrlResponse.fromJson(Map<String, dynamic> json) {
    return UploadUrlResponse(
      uploadUrl: json['upload_url'] as String,
      fileKey: json['file_key'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'upload_url': uploadUrl,
      'file_key': fileKey,
    };
  }
}

/// Response from process endpoint
/// {
///   "id": "...",
///   "user_id": "...",
///   "image_s3_key": "...",
///   "image_url": "",
///   "status": "pending",
///   "sender_name": null,
///   "sender_address": null,
///   "sender_pincode": null,
///   "receiver_name": null,
///   "receiver_address": null,
///   "receiver_pincode": null,
///   "assigned_sorting_center": null,
///   "raw_ai_response": null,
///   "created_at": "...",
///   "updated_at": null
/// }
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
    // Handle raw_ai_response - it can be a Map or null
    String? rawAiResponseStr;
    if (json['raw_ai_response'] != null) {
      if (json['raw_ai_response'] is Map) {
        rawAiResponseStr = jsonEncode(json['raw_ai_response']);
      } else {
        rawAiResponseStr = json['raw_ai_response'].toString();
      }
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

  Map<String, dynamic> toJson() {
    return {
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
  }

  /// Convert to ScanModel for local storage
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

  int _statusToIndex(String status) {
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
