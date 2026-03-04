import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/scan_model.dart';

void main() {
  group('ScanModel', () {
    late ScanModel scan;

    setUp(() {
      scan = ScanModel(
        id: 'test-123',
        imagePath: '/images/test.jpg',
        createdAt: DateTime(2025, 6, 15, 10, 30),
        statusIndex: ScanStatus.processed.index,
        extractedText: 'Hello World',
        senderName: 'John Doe',
        senderAddress: '123 Main St',
        recipientName: 'Jane Smith',
        recipientAddress: '456 Oak Ave',
        pincode: '110001',
        scanType: 'document',
      );
    });

    test('status getter returns correct enum value', () {
      expect(scan.status, ScanStatus.processed);

      final pendingScan = scan.copyWith(statusIndex: ScanStatus.pending.index);
      expect(pendingScan.status, ScanStatus.pending);
    });

    test('statusText returns human-readable string', () {
      expect(scan.statusText, 'Processed');

      final failedScan = scan.copyWith(statusIndex: ScanStatus.failed.index);
      expect(failedScan.statusText, 'Failed');
    });

    test('copyWith preserves unchanged fields', () {
      final updated = scan.copyWith(senderName: 'New Name');

      expect(updated.id, scan.id);
      expect(updated.imagePath, scan.imagePath);
      expect(updated.senderName, 'New Name');
      expect(updated.recipientName, scan.recipientName);
    });

    test('toJson produces correct map', () {
      final json = scan.toJson();

      expect(json['id'], 'test-123');
      expect(json['imagePath'], '/images/test.jpg');
      expect(json['status'], 'processed');
      expect(json['senderName'], 'John Doe');
      expect(json['pincode'], '110001');
      expect(json['scanType'], 'document');
    });

    test('fromJson roundtrips correctly', () {
      final json = scan.toJson();
      final restored = ScanModel.fromJson(json);

      expect(restored.id, scan.id);
      expect(restored.imagePath, scan.imagePath);
      expect(restored.status, scan.status);
      expect(restored.senderName, scan.senderName);
      expect(restored.recipientAddress, scan.recipientAddress);
      expect(restored.pincode, scan.pincode);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'minimal',
        'imagePath': '/test.jpg',
        'createdAt': '2025-01-01T00:00:00.000',
        'status': 'pending',
      };
      final minimal = ScanModel.fromJson(json);

      expect(minimal.id, 'minimal');
      expect(minimal.senderName, isNull);
      expect(minimal.extractedText, isNull);
      expect(minimal.scanType, 'document');
    });

    test('formattedDate returns Yesterday for 1-day-old scans', () {
      final yesterday = ScanModel(
        id: 'y',
        imagePath: '/test.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        statusIndex: 0,
      );
      expect(yesterday.formattedDate, 'Yesterday');
    });

    test('toString includes key fields', () {
      final str = scan.toString();
      expect(str, contains('test-123'));
      expect(str, contains('processed'));
    });
  });

  group('ScanStatus', () {
    test('has expected values', () {
      expect(ScanStatus.values.length, 4);
      expect(ScanStatus.pending.index, 0);
      expect(ScanStatus.processing.index, 1);
      expect(ScanStatus.processed.index, 2);
      expect(ScanStatus.failed.index, 3);
    });
  });
}
