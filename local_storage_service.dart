import 'package:flutter/foundation.dart';

/// Service for local storage or caching logic.
class LocalStorageService extends ChangeNotifier {
  /// Save a string value by key.
  Future<void> saveValue(String key, String value) async {
    // TODO: implement saving to disk or secure storage.
  }

  /// Read a string value by key.
  Future<String?> readValue(String key) async {
    // TODO: implement reading from disk or secure storage.
    return null;
  }
}
