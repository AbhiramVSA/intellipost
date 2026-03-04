import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/api_service.dart';
import 'package:app/services/auth_service.dart';

void main() {
  group('ApiResponse', () {
    test('success response has correct state', () {
      final response = ApiResponse<String>.success('data');

      expect(response.isSuccess, true);
      expect(response.data, 'data');
      expect(response.error, isNull);
      expect(response.statusCode, 200);
    });

    test('error response has correct state', () {
      final response = ApiResponse<String>.error('something failed', statusCode: 500);

      expect(response.isSuccess, false);
      expect(response.data, isNull);
      expect(response.error, 'something failed');
      expect(response.statusCode, 500);
    });

    test('error response without status code', () {
      final response = ApiResponse<String>.error('network error');

      expect(response.isSuccess, false);
      expect(response.statusCode, isNull);
    });
  });

  group('AuthResponse', () {
    test('success has data', () {
      final response = AuthResponse<String>.success('token-abc');

      expect(response.isSuccess, true);
      expect(response.data, 'token-abc');
      expect(response.errorMessage, isNull);
    });

    test('error has message', () {
      final response = AuthResponse<String>.error('bad credentials');

      expect(response.isSuccess, false);
      expect(response.errorMessage, 'bad credentials');
    });

    test('validationError has structured details', () {
      final error = ValidationError(details: [
        ValidationErrorDetail(
          location: ['body', 'email'],
          message: 'invalid email format',
          type: 'value_error',
        ),
      ]);
      final response = AuthResponse<String>.validationError(error);

      expect(response.isSuccess, false);
      expect(response.statusCode, 422);
      expect(response.errorMessage, 'invalid email format');
      expect(response.validationError!.details.first.fieldName, 'email');
    });
  });

  group('ValidationError', () {
    test('fromJson parses detail list', () {
      final json = {
        'detail': [
          {'loc': ['body', 'password'], 'msg': 'too short', 'type': 'value_error'},
          {'loc': ['body', 'email'], 'msg': 'required', 'type': 'missing'},
        ],
      };
      final error = ValidationError.fromJson(json);

      expect(error.details.length, 2);
      expect(error.details[0].fieldName, 'password');
      expect(error.message, 'too short, required');
    });

    test('fromJson handles null detail', () {
      final error = ValidationError.fromJson({'detail': null});
      expect(error.details, isEmpty);
      expect(error.message, 'Validation failed');
    });
  });

  group('MailProcessResponse', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'mail-1',
        'user_id': 'user-1',
        'image_s3_key': 'uploads/test.jpg',
        'image_url': 'https://example.com/test.jpg',
        'status': 'processed',
        'sender_name': 'Alice',
        'sender_address': '123 St',
        'sender_pincode': '110001',
        'receiver_name': 'Bob',
        'receiver_address': '456 Ave',
        'receiver_pincode': '220002',
        'assigned_sorting_center': 'Center A',
        'raw_ai_response': {'text': 'extracted'},
        'created_at': '2025-06-15T10:00:00.000',
        'updated_at': '2025-06-15T11:00:00.000',
      };

      final mail = MailProcessResponse.fromJson(json);

      expect(mail.id, 'mail-1');
      expect(mail.status, 'processed');
      expect(mail.senderName, 'Alice');
      expect(mail.receiverPincode, '220002');
      expect(mail.rawAiResponse, contains('extracted'));
      expect(mail.updatedAt, isNotNull);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'mail-2',
        'user_id': 'user-1',
        'image_s3_key': 'key',
        'status': 'pending',
        'created_at': '2025-01-01T00:00:00.000',
      };

      final mail = MailProcessResponse.fromJson(json);

      expect(mail.senderName, isNull);
      expect(mail.rawAiResponse, isNull);
      expect(mail.imageUrl, '');
      expect(mail.updatedAt, isNull);
    });

    test('toScanModel converts correctly', () {
      final mail = MailProcessResponse(
        id: 'm1',
        userId: 'u1',
        imageS3Key: 'key',
        imageUrl: 'https://img.com/1.jpg',
        status: 'processed',
        senderName: 'Sender',
        receiverName: 'Receiver',
        receiverPincode: '123456',
        createdAt: DateTime(2025, 1, 1),
      );

      final scanModel = mail.toScanModel('/local/path.jpg');

      expect(scanModel.id, 'm1');
      expect(scanModel.imagePath, '/local/path.jpg');
      expect(scanModel.senderName, 'Sender');
      expect(scanModel.recipientName, 'Receiver');
      expect(scanModel.pincode, '123456');
    });
  });

  group('UploadUrlResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'upload_url': 'https://s3.amazonaws.com/upload',
        'file_key': 'uploads/file.jpg',
      };

      final response = UploadUrlResponse.fromJson(json);
      expect(response.uploadUrl, 'https://s3.amazonaws.com/upload');
      expect(response.fileKey, 'uploads/file.jpg');
    });
  });

  group('RegisterResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'uuid-123',
        'username': 'testuser',
        'email': 'test@example.com',
      };

      final response = RegisterResponse.fromJson(json);
      expect(response.id, 'uuid-123');
      expect(response.username, 'testuser');
      expect(response.email, 'test@example.com');
    });
  });
}
