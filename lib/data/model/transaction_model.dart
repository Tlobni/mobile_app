class TransactionModel {
  int? id;
  int? userId;
  double? amount;
  String? paymentGateway;
  String? orderId;
  String? paymentId;
  String? paymentSignature;
  String? paymentStatus;
  String? createdAt;
  String? updatedAt;

  TransactionModel(
      {this.id,
      this.userId,
      this.amount,
      this.paymentGateway,
      this.orderId,
      this.paymentId,
      this.paymentSignature,
      this.paymentStatus,
      this.createdAt,
      this.updatedAt});

  TransactionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    amount = (json['amount'] as num).toDouble();
    paymentGateway = json['payment_gateway'];
    orderId = json['order_id'];
    paymentId = json['payment_id'];
    paymentSignature = json['payment_signature'];
    paymentStatus = json['payment_status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['amount'] = this.amount;
    data['payment_gateway'] = this.paymentGateway;
    data['order_id'] = this.orderId;
    data['payment_id'] = this.paymentId;
    data['payment_signature'] = this.paymentSignature;
    data['payment_status'] = this.paymentStatus;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
