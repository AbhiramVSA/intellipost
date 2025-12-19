import 'package:hive/hive.dart';

part 'scan_model.g.dart';

/// Scan status enumeration
enum ScanStatus {
  pending,
  processing,
  processed,
  failed,
}

/// Scan model representing a scanned document
@HiveType(typeId: 1)
class ScanModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final String? thumbnailPath;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final int statusIndex; // Store as int for Hive

  @HiveField(5)
  final String? extractedText;

  @HiveField(6)
  final String? senderName;

  @HiveField(7)
  final String? senderAddress;

  @HiveField(8)
  final String? recipientName;

  @HiveField(9)
  final String? recipientAddress;

  @HiveField(10)
  final String? pincode;

  @HiveField(11)
  final String? apiResponse;

  @HiveField(12)
  final String scanType; // 'document' or 'letter'

  ScanModel({
    required this.id,
    required this.imagePath,
    this.thumbnailPath,
    required this.createdAt,
    required this.statusIndex,
    this.extractedText,
    this.senderName,
    this.senderAddress,
    this.recipientName,
    this.recipientAddress,
    this.pincode,
    this.apiResponse,
    this.scanType = 'document',
  });

  /// Get status as enum
  ScanStatus get status => ScanStatus.values[statusIndex];

  /// Create a copy with updated fields
  ScanModel copyWith({
    String? id,
    String? imagePath,
    String? thumbnailPath,
    DateTime? createdAt,
    int? statusIndex,
    String? extractedText,
    String? senderName,
    String? senderAddress,
    String? recipientName,
    String? recipientAddress,
    String? pincode,
    String? apiResponse,
    String? scanType,
  }) {
    return ScanModel(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      statusIndex: statusIndex ?? this.statusIndex,
      extractedText: extractedText ?? this.extractedText,
      senderName: senderName ?? this.senderName,
      senderAddress: senderAddress ?? this.senderAddress,
      recipientName: recipientName ?? this.recipientName,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      pincode: pincode ?? this.pincode,
      apiResponse: apiResponse ?? this.apiResponse,
      scanType: scanType ?? this.scanType,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'extractedText': extractedText,
      'senderName': senderName,
      'senderAddress': senderAddress,
      'recipientName': recipientName,
      'recipientAddress': recipientAddress,
      'pincode': pincode,
      'apiResponse': apiResponse,
      'scanType': scanType,
    };
  }

  /// Create from JSON map
  factory ScanModel.fromJson(Map<String, dynamic> json) {
    return ScanModel(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      statusIndex: ScanStatus.values
          .indexWhere((e) => e.name == json['status']),
      extractedText: json['extractedText'] as String?,
      senderName: json['senderName'] as String?,
      senderAddress: json['senderAddress'] as String?,
      recipientName: json['recipientName'] as String?,
      recipientAddress: json['recipientAddress'] as String?,
      pincode: json['pincode'] as String?,
      apiResponse: json['apiResponse'] as String?,
      scanType: json['scanType'] as String? ?? 'document',
    );
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case ScanStatus.pending:
        return 'Pending';
      case ScanStatus.processing:
        return 'Processing';
      case ScanStatus.processed:
        return 'Processed';
      case ScanStatus.failed:
        return 'Failed';
    }
  }

  @override
  String toString() {
    return 'ScanModel(id: $id, status: $status, createdAt: $createdAt)';
  }
}

/// Manually generated Hive adapter
class ScanModelAdapter extends TypeAdapter<ScanModel> {
  @override
  final int typeId = 1;

  @override
  ScanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanModel(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      thumbnailPath: fields[2] as String?,
      createdAt: fields[3] as DateTime,
      statusIndex: fields[4] as int,
      extractedText: fields[5] as String?,
      senderName: fields[6] as String?,
      senderAddress: fields[7] as String?,
      recipientName: fields[8] as String?,
      recipientAddress: fields[9] as String?,
      pincode: fields[10] as String?,
      apiResponse: fields[11] as String?,
      scanType: fields[12] as String? ?? 'document',
    );
  }

  @override
  void write(BinaryWriter writer, ScanModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.thumbnailPath)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.statusIndex)
      ..writeByte(5)
      ..write(obj.extractedText)
      ..writeByte(6)
      ..write(obj.senderName)
      ..writeByte(7)
      ..write(obj.senderAddress)
      ..writeByte(8)
      ..write(obj.recipientName)
      ..writeByte(9)
      ..write(obj.recipientAddress)
      ..writeByte(10)
      ..write(obj.pincode)
      ..writeByte(11)
      ..write(obj.apiResponse)
      ..writeByte(12)
      ..write(obj.scanType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
