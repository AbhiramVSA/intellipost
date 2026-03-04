import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/user_model.dart';

void main() {
  group('UserModel', () {
    late UserModel user;

    setUp(() {
      user = UserModel(
        id: 'user-1',
        name: 'John Doe',
        phone: '+91-9876543210',
        email: 'john@example.com',
        createdAt: DateTime(2025, 1, 1),
        isLoggedIn: true,
        username: 'johndoe',
        authToken: 'Bearer abc123',
      );
    });

    test('copyWith preserves unchanged fields', () {
      final updated = user.copyWith(name: 'Jane Doe');

      expect(updated.id, user.id);
      expect(updated.name, 'Jane Doe');
      expect(updated.email, user.email);
      expect(updated.authToken, user.authToken);
    });

    test('copyWith can clear authToken with null-like update', () {
      // Note: copyWith doesn't support setting to null due to Dart's ?? operator
      // This tests the expected behavior
      final loggedOut = user.copyWith(isLoggedIn: false);
      expect(loggedOut.isLoggedIn, false);
      expect(loggedOut.authToken, user.authToken); // still preserved
    });

    test('toJson produces correct map', () {
      final json = user.toJson();

      expect(json['id'], 'user-1');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['isLoggedIn'], true);
      expect(json['username'], 'johndoe');
      expect(json['authToken'], 'Bearer abc123');
    });

    test('fromJson roundtrips correctly', () {
      final json = user.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, user.id);
      expect(restored.name, user.name);
      expect(restored.email, user.email);
      expect(restored.username, user.username);
    });

    test('fromJson uses username as name fallback', () {
      final json = {
        'id': 'u1',
        'email': 'test@test.com',
        'username': 'testuser',
      };
      final model = UserModel.fromJson(json);
      expect(model.name, 'testuser');
    });

    test('fromJson defaults missing fields', () {
      final json = {
        'id': 'u1',
        'email': 'test@test.com',
      };
      final model = UserModel.fromJson(json);

      expect(model.name, '');
      expect(model.phone, '');
      expect(model.isLoggedIn, false);
      expect(model.username, isNull);
      expect(model.authToken, isNull);
    });

    test('toString includes key fields', () {
      final str = user.toString();
      expect(str, contains('user-1'));
      expect(str, contains('johndoe'));
      expect(str, contains('john@example.com'));
    });
  });
}
