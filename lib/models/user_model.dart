import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// User model for authentication and profile data
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final bool isLoggedIn;

  @HiveField(6)
  final String? username;

  @HiveField(7)
  final String? authToken;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
    this.isLoggedIn = false,
    this.username,
    this.authToken,
  });

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    DateTime? createdAt,
    bool? isLoggedIn,
    String? username,
    String? authToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      username: username ?? this.username,
      authToken: authToken ?? this.authToken,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'isLoggedIn': isLoggedIn,
      'username': username,
      'authToken': authToken,
    };
  }

  /// Create from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isLoggedIn: json['isLoggedIn'] as bool? ?? false,
      username: json['username'] as String?,
      authToken: json['authToken'] as String?,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, username: $username, email: $email)';
  }
}

/// Manually generated Hive adapter (normally would use build_runner)
class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String,
      email: fields[3] as String,
      createdAt: fields[4] as DateTime,
      isLoggedIn: fields[5] as bool? ?? false,
      username: fields[6] as String?,
      authToken: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isLoggedIn)
      ..writeByte(6)
      ..write(obj.username)
      ..writeByte(7)
      ..write(obj.authToken);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
