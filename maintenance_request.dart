class MaintenanceRequest {
  final String id;
  final String assetId;
  final String assetNumber;
  final String assetNameEn;
  final String projectNumber;
  final String equipmentId;
  final String employeeName;
  final String employeeId;
  final String assetNameAr;
  final String problemDescription;
  final String requestedBy;
  final String requestedById;
  final String status;
  final DateTime requestDate;
  final String assignedTo;
  final String assignedToId;
  final DateTime? completedDate;
  final DateTime? workerConfirmedDate;
  final String notes;
  final String repairDetails;
  final List<String> partsUsed;
  final double totalCost;
  final String approvedBy;
  final String purchasingApprovedBy;
  final bool workerConfirmed;

  MaintenanceRequest({
    required this.id,
    required this.assetId,
    required this.assetNumber,
    required this.assetNameEn,
    required this.projectNumber,
    required this.equipmentId,
    required this.employeeName,
    required this.employeeId,
    required this.assetNameAr,
    required this.problemDescription,
    required this.requestedBy,
    required this.requestedById,
    required this.status,
    required this.requestDate,
    this.assignedTo = '',
    this.assignedToId = '',
    this.completedDate,
    this.workerConfirmedDate,
    this.notes = '',
    this.repairDetails = '',
    this.partsUsed = const [],
    this.totalCost = 0.0,
    this.approvedBy = '',
    this.purchasingApprovedBy = '',
    this.workerConfirmed = false,
  });

  String get formattedRequestDate =>
      '${requestDate.day}/${requestDate.month}/${requestDate.year}';

  String get statusText {
    switch (status) {
      case 'pending': return 'في انتظار الموافقة';
      case 'purchasing_approved': return 'تمت موافقة المشتريات';
      case 'in_progress': return 'جاري الإصلاح';
      case 'completed': return 'تم الإصلاح';
      case 'worker_confirmed': return 'تم التأكيد من العامل';
      case 'rejected': return 'مرفوض';
      default: return 'غير محدد';
    }
  }

  String get statusArabic {
    switch (status) {
      case 'pending': return 'معلق';
      case 'approved': return 'موافق عليه';
      case 'purchasing_approved': return 'موافق عليه من المشتريات';
      case 'in_progress': return 'جاري التنفيذ';
      case 'completed': return 'مكتمل';
      case 'worker_confirmed': return 'مؤكد من العامل';
      case 'rejected': return 'مرفوض';
      default: return 'غير محدد';
    }
  }

  MaintenanceRequest copyWith({
    String? status,
    String? assignedTo,
    String? assignedToId,
    DateTime? completedDate,
    DateTime? workerConfirmedDate,
    String? notes,
    String? repairDetails,
    List<String>? partsUsed,
    double? totalCost,
    String? approvedBy,
    String? purchasingApprovedBy,
    bool? workerConfirmed,
  }) {
    return MaintenanceRequest(
      id: id,
      assetId: assetId,
      assetNumber: assetNumber,
      assetNameEn: assetNameEn,
      projectNumber: projectNumber,
      equipmentId: equipmentId,
      employeeName: employeeName,
      employeeId: employeeId,
      assetNameAr: assetNameAr,
      problemDescription: problemDescription,
      requestedBy: requestedBy,
      requestedById: requestedById,
      status: status ?? this.status,
      requestDate: requestDate,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToId: assignedToId ?? this.assignedToId,
      completedDate: completedDate ?? this.completedDate,
      workerConfirmedDate: workerConfirmedDate ?? this.workerConfirmedDate,
      notes: notes ?? this.notes,
      repairDetails: repairDetails ?? this.repairDetails,
      partsUsed: partsUsed ?? this.partsUsed,
      totalCost: totalCost ?? this.totalCost,
      approvedBy: approvedBy ?? this.approvedBy,
      purchasingApprovedBy: purchasingApprovedBy ?? this.purchasingApprovedBy,
      workerConfirmed: workerConfirmed ?? this.workerConfirmed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetId': assetId,
      'assetNumber': assetNumber,
      'assetNameEn': assetNameEn,
      'projectNumber': projectNumber,
      'equipmentId': equipmentId,
      'employeeName': employeeName,
      'employeeId': employeeId,
      'assetNameAr': assetNameAr,
      'problemDescription': problemDescription,
      'requestedBy': requestedBy,
      'requestedById': requestedById,
      'status': status,
      'requestDate': requestDate.toIso8601String(),
      'assignedTo': assignedTo,
      'assignedToId': assignedToId,
      'completedDate': completedDate?.toIso8601String(),
      'workerConfirmedDate': workerConfirmedDate?.toIso8601String(),
      'notes': notes,
      'repairDetails': repairDetails,
      'partsUsed': partsUsed,
      'totalCost': totalCost,
      'approvedBy': approvedBy,
      'purchasingApprovedBy': purchasingApprovedBy,
      'workerConfirmed': workerConfirmed,
    };
  }

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'] ?? '',
      assetId: json['assetId'] ?? '',
      assetNumber: json['assetNumber'] ?? '',
      assetNameEn: json['assetNameEn'] ?? '',
      projectNumber: json['projectNumber'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      employeeId: json['employeeId'] ?? '',
      assetNameAr: json['assetNameAr'] ?? '',
      problemDescription: json['problemDescription'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      requestedById: json['requestedById'] ?? '',
      status: json['status'] ?? 'pending',
      requestDate: DateTime.parse(json['requestDate']),
      assignedTo: json['assignedTo'] ?? '',
      assignedToId: json['assignedToId'] ?? '',
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
      workerConfirmedDate: json['workerConfirmedDate'] != null ? DateTime.parse(json['workerConfirmedDate']) : null,
      notes: json['notes'] ?? '',
      repairDetails: json['repairDetails'] ?? '',
      partsUsed: List<String>.from(json['partsUsed'] ?? []),
      totalCost: (json['totalCost'] ?? 0.0).toDouble(),
      approvedBy: json['approvedBy'] ?? '',
      purchasingApprovedBy: json['purchasingApprovedBy'] ?? '',
      workerConfirmed: json['workerConfirmed'] ?? false,
    );
  }
}