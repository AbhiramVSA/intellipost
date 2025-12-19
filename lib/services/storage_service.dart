import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

/// Local storage service using Hive for offline data persistence
/// 
/// Architecture Note: This service handles all local data operations,
/// keeping UI layers clean and enabling easy testing through abstraction.
class StorageService {
  static const String _userBoxName = 'users';
  static const String _scansBoxName = 'scans';
  static const String _settingsBoxName = 'settings';

  late Box<UserModel> _userBox;
  late Box<ScanModel> _scanBox;
  late Box<dynamic> _settingsBox;

  bool _isInitialized = false;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ScanModelAdapter());
    }

    // Open boxes
    _userBox = await Hive.openBox<UserModel>(_userBoxName);
    _scanBox = await Hive.openBox<ScanModel>(_scansBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    _isInitialized = true;
  }

  /// Ensure service is initialized
  void _checkInit() {
    if (!_isInitialized) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
  }

  // ==================== User Operations ====================

  /// Save user to local storage
  Future<void> saveUser(UserModel user) async {
    _checkInit();
    await _userBox.put('current_user', user);
  }

  /// Get current logged-in user
  UserModel? getUser() {
    _checkInit();
    return _userBox.get('current_user');
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    _checkInit();
    final user = getUser();
    return user?.isLoggedIn ?? false;
  }

  /// Get auth token
  String? getAuthToken() {
    _checkInit();
    final user = getUser();
    return user?.authToken;
  }

  /// Save auth token to current user
  Future<void> saveAuthToken(String token) async {
    _checkInit();
    final user = getUser();
    if (user != null) {
      await saveUser(user.copyWith(authToken: token));
    }
  }

  /// Logout user
  Future<void> logout() async {
    _checkInit();
    final user = getUser();
    if (user != null) {
      await saveUser(user.copyWith(isLoggedIn: false, authToken: null));
    }
  }

  /// Clear user data
  Future<void> clearUser() async {
    _checkInit();
    await _userBox.clear();
  }

  // ==================== Scan Operations ====================

  /// Save a scan to local storage
  Future<void> saveScan(ScanModel scan) async {
    _checkInit();
    await _scanBox.put(scan.id, scan);
  }

  /// Get all scans sorted by date (newest first)
  List<ScanModel> getAllScans() {
    _checkInit();
    final scans = _scanBox.values.toList();
    scans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return scans;
  }

  /// Get a specific scan by ID
  ScanModel? getScan(String id) {
    _checkInit();
    return _scanBox.get(id);
  }

  /// Update an existing scan
  Future<void> updateScan(ScanModel scan) async {
    _checkInit();
    await _scanBox.put(scan.id, scan);
  }

  /// Delete a scan
  Future<void> deleteScan(String id) async {
    _checkInit();
    await _scanBox.delete(id);
  }

  /// Clear all scans
  Future<void> clearScans() async {
    _checkInit();
    await _scanBox.clear();
  }

  /// Get scans count
  int getScansCount() {
    _checkInit();
    return _scanBox.length;
  }

  /// Stream of scans for reactive updates
  Stream<BoxEvent> watchScans() {
    _checkInit();
    return _scanBox.watch();
  }

  // ==================== Settings Operations ====================

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    _checkInit();
    await _settingsBox.put(key, value);
  }

  /// Get a setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    _checkInit();
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  /// Check if first launch
  bool isFirstLaunch() {
    return getSetting<bool>('first_launch', defaultValue: true) ?? true;
  }

  /// Mark first launch complete
  Future<void> completeFirstLaunch() async {
    await saveSetting('first_launch', false);
  }

  // ==================== Utility Operations ====================

  /// Clear all data
  Future<void> clearAll() async {
    _checkInit();
    await _userBox.clear();
    await _scanBox.clear();
    await _settingsBox.clear();
  }

  /// Close all boxes
  Future<void> close() async {
    if (_isInitialized) {
      await _userBox.close();
      await _scanBox.close();
      await _settingsBox.close();
      _isInitialized = false;
    }
  }
}
