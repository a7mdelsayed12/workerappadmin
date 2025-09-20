// في models/dispatch_request.dart
class DispatchRequest {
  final String id;
  final String itemId;
  final String userId;
  final int requestedQuantity;
  final String status;
  final DateTime requestDate;
  int? approvedQuantity;
  String? rejectionReason;

  DispatchRequest({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.requestedQuantity,
    required this.status,
    required this.requestDate,
    this.approvedQuantity,
    this.rejectionReason,
  });

  // أضف هذه الدوال
  factory DispatchRequest.fromJson(Map<String, dynamic> json) {
    return DispatchRequest(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      userId: json['userId'] ?? '',
      requestedQuantity: json['requestedQuantity'] ?? 0,
      status: json['status'] ?? '',
      requestDate: DateTime.parse(json['requestDate'] ?? DateTime.now().toString()),
      approvedQuantity: json['approvedQuantity'],
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'userId': userId,
      'requestedQuantity': requestedQuantity,
      'status': status,
      'requestDate': requestDate.toString(),
      'approvedQuantity': approvedQuantity,
      'rejectionReason': rejectionReason,
    };
  }

  DispatchRequest copyWith({
    String? id,
    String? itemId,
    String? userId,
    int? requestedQuantity,
    String? status,
    DateTime? requestDate,
    int? approvedQuantity,
    String? rejectionReason,
  }) {
    return DispatchRequest(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      approvedQuantity: approvedQuantity ?? this.approvedQuantity,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}