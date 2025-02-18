// ignore_for_file: public_member_api_docs, sort_constructors_first

class SubscriptionPackageModel {
  int? id;
  String? iosProductId;
  String? name;
  double? price;
  double? finalPrice;
  double? discount;
  String? duration;
  String? limit;
  String? type;
  String? icon;
  String? description;
  int? status;
  String? createdAt;
  String? updatedAt;
  bool? isActive;
  List<UserPurchasedPackages>? userPurchasedPackages;

  SubscriptionPackageModel(
      {this.id,
      this.iosProductId,
      this.name,
      this.price,
      this.finalPrice,
      this.discount,
      this.duration,
      this.limit,
      this.type,
      this.icon,
      this.description,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.isActive,
      this.userPurchasedPackages});

  SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    iosProductId = json['ios_product_id'];
    name = json['name'];
    price = json['price'] != null ? json['price'].toDouble() : null;
    discount = json['discount_in_percentage'] != null
        ? json['discount_in_percentage'].toDouble()
        : null;
    finalPrice =
        json['final_price'] != null ? json['final_price'].toDouble() : null;
    duration = json['duration'];
    limit = json['item_limit'];
    type = json['type'];
    icon = json['icon'];
    description = json['description'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isActive = json['is_active'];
    if (json['user_purchased_packages'] != null) {
      userPurchasedPackages = <UserPurchasedPackages>[];
      json['user_purchased_packages'].forEach((v) {
        userPurchasedPackages!.add(UserPurchasedPackages.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['ios_product_id'] = iosProductId;
    data['name'] = name;
    data['price'] = price;
    data['discount_in_percentage'] = discount;
    data['final_price'] = finalPrice;
    data['duration'] = duration;
    data['item_limit'] = limit;
    data['type'] = type;
    data['icon'] = icon;
    data['description'] = description;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_active'] = isActive;
    if (userPurchasedPackages != null) {
      data['user_purchased_packages'] =
          userPurchasedPackages!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  @override
  String toString() {
    return 'SubscriptionPackageModel(id: $id, name: $name, duration: $duration, price: $price,final_price: $finalPrice,discount_in_percentage:$discount, status: $status, item_limit: $limit, type: $type, createdAt: $createdAt, updatedAt: $updatedAt, icon: $icon,description: $description,is_active: $isActive)';
  }
}

class UserPurchasedPackages {
  int? id;
  int? userId;
  int? packageId;
  String? startDate;
  String? endDate;
  int? totalLimit;
  int? usedLimit;
  String? createdAt;
  String? updatedAt;
  String? remainingDays;
  String? remainingItemLimit;

  UserPurchasedPackages(
      {this.id,
      this.userId,
      this.packageId,
      this.startDate,
      this.endDate,
      this.totalLimit,
      this.usedLimit,
      this.createdAt,
      this.updatedAt,
      this.remainingDays,
      this.remainingItemLimit});

  UserPurchasedPackages.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    packageId = json['package_id'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    totalLimit = json['total_limit'];
    usedLimit = json['used_limit'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    remainingDays = json['remaining_days'].toString();
    remainingItemLimit = json['remaining_item_limit'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['package_id'] = this.packageId;
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    data['total_limit'] = this.totalLimit;
    data['used_limit'] = this.usedLimit;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['remaining_days'] = this.remainingDays;
    data['remaining_item_limit'] = this.remainingItemLimit;
    return data;
  }
}

/*
class SubscriptionPackageModel {
  int? id;
  String? name;
  int? duration;
  int? price;
  int? di;
  int? status;
  dynamic itemLimit;
  dynamic advertisementlimit;
  String? createdAt;
  String? updatedAt;

  SubscriptionPackageModel(
      {this.id,
      this.name,
      this.duration,
      this.price,
      this.status,
      this.itemLimit,
      this.advertisementlimit,
      this.createdAt,
      this.updatedAt});

  SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    itemLimit = json['item_limit'];
    advertisementlimit = json['advertisement_limit'];
    id = json['id'];
    name = json['name'];
    duration = json['duration'];
    price = json['price'];
    status = Adapter.forceInt(json['status']);
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['duration'] = duration;
    data['price'] = price;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;

    data['item_limit'] = itemLimit;
    data['advertisement_limit'] = advertisementlimit;
    return data;
  }

  @override
  String toString() {
    return 'SubscriptionPackageModel(id: $id, name: $name, duration: $duration, price: $price, status: $status, itemLimit: $itemLimit, advertisementlimit: $advertisementlimit, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
*/
