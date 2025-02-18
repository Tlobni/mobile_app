//import 'package:eClassify/data/model/item/item_model.dart';

import 'package:eClassify/data/model/seller_ratings_model.dart';

class ChatUser {
  int? id;
  int? sellerId;
  int? buyerId;
  int? itemId;
  String? createdAt;
  String? updatedAt;
  double? amount;
  Seller? seller;
  Buyer? buyer;
  Item? item;
  bool? userBlocked;
  int? unreadCount;

  ChatUser({
    this.id,
    this.sellerId,
    this.buyerId,
    this.itemId,
    this.createdAt,
    this.updatedAt,
    this.amount,
    this.seller,
    this.buyer,
    this.userBlocked,
    this.item,
    this.unreadCount,
  });

  ChatUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sellerId = json['seller_id'];
    buyerId = json['buyer_id'];
    itemId = json['item_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    amount = (json['amount'] as num?)?.toDouble();
    userBlocked = json['user_blocked'];
    seller = json['seller'] != null ? Seller.fromJson(json['seller']) : null;
    buyer = json['buyer'] != null ? Buyer.fromJson(json['buyer']) : null;
    item = json['item'] != null ? Item.fromJson(json['item']) : null;
    unreadCount = json['unread_chat_count'] as int?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = id;
    data['seller_id'] = sellerId;
    data['buyer_id'] = buyerId;
    data['item_id'] = itemId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['amount'] = amount;
    data['user_blocked'] = userBlocked;
    if (seller != null) {
      data['seller'] = seller!.toJson();
    }
    if (buyer != null) {
      data['buyer'] = this.buyer!.toJson();
    }
    if (item != null) {
      data['item'] = item!.toJson();
    }
    return data;
  }

  ChatUser copyWith({
    int? unreadCount,
    String? createdAt,
    String? updatedAt,
  }) =>
      ChatUser(
          id: id,
          itemId: itemId,
          item: item,
          sellerId: sellerId,
          seller: seller,
          buyerId: buyerId,
          buyer: buyer,
          amount: amount,
          userBlocked: userBlocked,
          unreadCount: unreadCount,
          createdAt: createdAt ?? this.createdAt,
          updatedAt: updatedAt ?? this.updatedAt);
}

class Seller {
  int? id;
  String? name;
  String? profile;

  Seller({this.id, this.name, this.profile});

  Seller.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profile = json['profile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['profile'] = this.profile;
    return data;
  }
}

class Buyer {
  int? id;
  String? name;
  String? profile;

  Buyer({this.id, this.name, this.profile});

  Buyer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profile = json['profile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['profile'] = this.profile;
    return data;
  }
}

class Item {
  int? id;
  String? name;
  String? description;
  double? price;
  String? image;
  String? status;
  int? isPurchased;
  UserRatings? review;

  Item(
      {this.id,
      this.name,
      this.description,
      this.price,
      this.image,
      this.status,
      this.review,
      this.isPurchased});

  Item.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    price = (json['price'] as num?)?.toDouble();
    image = json['image'];
    status = json['status'];
    status = json['status'];
    isPurchased = json['is_purchased'];
    review =
        json['review'] != null ? UserRatings.fromJson(json['review']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['price'] = this.price;
    data['image'] = this.image;
    data['status'] = this.status;
    data['is_purchased'] = this.isPurchased;
    data['review'] = review!.toJson();
    return data;
  }
}

class BlockedUserModel {
  int? id;
  String? name;
  String? profile;

  BlockedUserModel({this.id, this.name, this.profile});

  BlockedUserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profile = json['profile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['profile'] = this.profile;
    return data;
  }
}
