import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:app/services/storage_service.dart';

void main() {
  // Note: These tests require Hive initialization in a real Flutter test
  // environment. They verify the validation logic is correct.

  group('AuthViewModel validation', () {
    late AuthViewModel viewModel;

    setUp(() {
      // StorageService.init() requires Flutter environment.
      // For pure validation tests, we test the static validation methods.
    });

    // Testing validation logic directly without full DI setup.
    // In integration tests, use a properly initialized StorageService.

    group('email validation', () {
      test('rejects empty email', () {
        final vm = _createMinimalViewModel();
        expect(vm.validateEmail(''), isNotNull);
        expect(vm.validateEmail(null), isNotNull);
      });

      test('rejects invalid email formats', () {
        final vm = _createMinimalViewModel();
        expect(vm.validateEmail('notanemail'), isNotNull);
        expect(vm.validateEmail('missing@'), isNotNull);
        expect(vm.validateEmail('@nodomain.com'), isNotNull);
      });

      test('accepts valid email', () {
        final vm = _createMinimalViewModel();
        expect(vm.validateEmail('user@example.com'), isNull);
        expect(vm.validateEmail('first.last@domain.org'), isNull);
      });
    });

    group('username validation', () {
      test('rejects empty username', () {
        final vm = _createMinimalViewModel();
        expect(vm.validateUsername(''), isNotNull);
        expect(vm.validateUsername(null), isNotNull);
      });

      test('rejects short username', () {
        final vm = _createMinimalViewModel();
        expect(vm.validateUsername('ab'), isNotNull);
      });

      test('rejects username with special characters', () {
        final vm = _createMinimalViewModel();
        expect(vm.validateUsername('user@name'), isNotNull);
        expect(vm.validateUsername('user name'), isNotNull);
      });

      test('accepts valid username', () {
        final vm = _createMinimalViewModel();
        expect(vm.validateUsername('john_doe'), isNull);
        expect(vm.validateUsername('user123'), isNull);
      });
    });

    group('password validation', () {
      test('rejects empty password', () {
        final vm = _createMinimalViewModel();
        expect(vm.validatePassword(''), isNotNull);
        expect(vm.validatePassword(null), isNotNull);
      });

      test('rejects short password', () {
        final vm = _createMinimalViewModel();
        expect(vm.validatePassword('12345'), isNotNull);
      });

      test('accepts valid password', () {
        final vm = _createMinimalViewModel();
        expect(vm.validatePassword('password123'), isNull);
      });
    });
  });
}

/// Creates a minimal AuthViewModel for testing validation methods.
/// Note: StorageService won't be fully initialized without Hive,
/// but validation methods don't touch storage.
AuthViewModel _createMinimalViewModel() {
  // This will work for validation-only tests since those methods
  // don't interact with StorageService.
  return AuthViewModel(storageService: StorageService());
}
