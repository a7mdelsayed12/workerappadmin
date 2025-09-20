class RepairRecord {
  final String id;
  final String assetId;
  final String description;
  final DateTime date;
  final String performedById;
  final String performedByName;
  final String repairType;
  final double cost;

  RepairRecord({
    String? id,
    required this.assetId,
    required this.description,
    required this.date,
    required this.performedById,
    required this.performedByName,
    required this.repairType,
    required this.cost,
  }) : this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  RepairRecord copyWith({
    String? id,
    String? assetId,
    String? description,
    DateTime? date,
    String? performedById,
    String? performedByName,
    String? repairType,
    double? cost,
  }) {
    return RepairRecord(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      description: description ?? this.description,
      date: date ?? this.date,
      performedById: performedById ?? this.performedById,
      performedByName: performedByName ?? this.performedByName,
      repairType: repairType ?? this.repairType,
      cost: cost ?? this.cost,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'assetId': assetId,
    'description': description,
    'date': date.toIso8601String(),
    'performedById': performedById,
    'performedByName': performedByName,
    'repairType': repairType,
    'cost': cost,
  };

  factory RepairRecord.fromJson(Map<String, dynamic> json) => RepairRecord(
    id: json['id'] as String?,
    assetId: json['assetId'] as String,
    description: json['description'] as String,
    date: DateTime.parse(json['date'] as String),
    performedById: json['performedById'] as String,
    performedByName: json['performedByName'] as String,
    repairType: json['repairType'] as String,
    cost: (json['cost'] as num).toDouble(),
  );
}
