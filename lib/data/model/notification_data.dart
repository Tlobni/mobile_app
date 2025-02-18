class NotificationData {
  String? id;
  String? title;
  String? message;
  String? image;
  String? type;
  int? sendType;
  String? customersId;
  String? itemsId;
  String? createdAt;
  String? created;

  NotificationData(
      {this.id,
      this.title,
      this.message,
      this.image,
      this.type,
      this.sendType,
      this.customersId,
      this.itemsId,
      this.createdAt,
      this.created});

  NotificationData.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    title = json['title'];
    message = json['message'];
    image = json['image'];
    type = json['type'].toString();
    sendType = json['send_type'] as int?;
    customersId = json['customers_id'];
    itemsId = json['items_id'].toString();
    createdAt = json['created_at'];
    created = json['created'];
  }
}
