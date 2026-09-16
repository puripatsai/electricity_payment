class BillingRecordModel {
  String userId;
  String month;
  int units;
  double amount;
  String paidStatus; // 'Paid' หรือ 'Unpaid'
  String? referenceId;

  static const CollectionName = 'electricity_bills';

  BillingRecordModel({
    required this.userId,
    required this.month,
    required this.units,
    required this.amount,
    required this.paidStatus,
    this.referenceId,
  });

  factory BillingRecordModel.fromJson(Map<String, dynamic> json) {
    return BillingRecordModel(
      userId: json['userId'] ?? '',
      month: json['month'] ?? '',
      units: json['units'] ?? 0,
      // ใช้ .toDouble() กับ amount เสมอ ไม่ว่าค่าจาก Firestore จะเป็น int หรือ double
      amount: (json['amount'] as num).toDouble(),
      paidStatus: json['paidStatus'] ?? 'Unpaid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'month': month,
      'units': units,
      'amount': amount,
      'paidStatus': paidStatus,
    };
  }
}
