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
  bool isRead = false;
  DateTime? readAt;

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
      this.created,
      this.isRead = false,
      this.readAt});

  NotificationData.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    title = json['title'];
    message = json['message'];
    image = json['image'];
    type = json['type']?.toString() ?? '';
    sendType = json['send_type'] as int?;
    customersId = json['customers_id'];
    itemsId = json['items_id']?.toString() ?? '';
    createdAt = json['created_at'];
    created = json['created'];

    if (json['is_read'] != null) {
      isRead = json['is_read'] == 1 || json['is_read'] == true;
      if (isRead && json['read_at'] != null) {
        try {
          readAt = DateTime.parse(json['read_at']);
        } catch (_) {
          readAt = DateTime.now();
        }
      }
    } else {
      isRead = false;
    }
  }

  void markAsRead() {
    isRead = true;
    readAt = DateTime.now();
  }

  bool isPackageApproval() {
    return type == "payment" &&
        (message?.toLowerCase().contains("approved") == true ||
            message?.toLowerCase().contains("subscription") == true);
  }

  bool isPostApproval() {
    return type == "item-update" &&
        message?.toLowerCase().contains("approved") == true;
  }

  bool isProviderNotification() {
    return isPackageApproval() || isPostApproval();
  }
}
