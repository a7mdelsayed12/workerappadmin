class Expense {
  final String id;
  final double amount;
  final String description;
  final String category;
  final String employeeName;
  final String employeeId;
  final DateTime date;
  final String status; // 'pending', 'approved', 'spent'

  Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.employeeName,
    required this.employeeId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category': category,
      'employeeName': employeeName,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'status': status,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      employeeName: json['employeeName'] ?? '',
      employeeId: json['employeeId'] ?? '',
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'pending',
    );
  }
}