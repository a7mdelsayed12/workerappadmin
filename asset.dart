// models/asset.dart
class Asset {
  final String id;
  final String assetNumber;
  final String nameEn;
  final String projectNumber;
  final String equipmentId;
  final String employeeName;
  final String employeeId;
  final String nameAr;
  Asset({
    String? id,
    required this.assetNumber,
    required this.nameEn,
    required this.projectNumber,
    required this.equipmentId,
    required this.employeeName,
    required this.employeeId,
    required this.nameAr,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Convert to Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetNumber': assetNumber,
      'nameEn': nameEn,
      'projectNumber': projectNumber,
      'equipmentId': equipmentId,
      'employeeName': employeeName,
      'employeeId': employeeId,
      'nameAr': nameAr,
    };
  }

  // Create from Map
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] ?? '',
      assetNumber: json['assetNumber'] ?? '',
      nameEn: json['nameEn'] ?? '',
      projectNumber: json['projectNumber'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      employeeId: json['employeeId'] ?? '',
      nameAr: json['nameAr'] ?? '',
    );
  }

  Asset copyWith({
    String? id,
    String? assetNumber,
    String? nameEn,
    String? projectNumber,
    String? equipmentId,
    String? employeeName,
    String? employeeId,
    String? nameAr,
  }) {
    return Asset(
      id: id ?? this.id,
      assetNumber: assetNumber ?? this.assetNumber,
      nameEn: nameEn ?? this.nameEn,
      projectNumber: projectNumber ?? this.projectNumber,
      equipmentId: equipmentId ?? this.equipmentId,
      employeeName: employeeName ?? this.employeeName,
      employeeId: employeeId ?? this.employeeId,
      nameAr: nameAr ?? this.nameAr,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Asset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Asset(id: $id, assetNumber: $assetNumber, nameEn: $nameEn)';
  }
}
