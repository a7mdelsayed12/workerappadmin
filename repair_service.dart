// lib/services/repair_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/repair_record.dart';

class RepairService extends ChangeNotifier {
  static const _recordsKey = 'repair_records';

  final List<RepairRecord> _records = [];
  List<RepairRecord> get records => List.unmodifiable(_records);

  /// Load records from SharedPreferences
  Future<void> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_recordsKey);
    if (jsonString != null) {
      final List list = json.decode(jsonString);
      _records
        ..clear()
        ..addAll(list.map((j) => RepairRecord.fromJson(j)));
      notifyListeners();
    }
  }

  Future<void> addRecord(RepairRecord record) async {
    _records.add(record);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateRecord(RepairRecord record) async {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_records.map((r) => r.toJson()).toList());
    await prefs.setString(_recordsKey, jsonString);
  }
}
