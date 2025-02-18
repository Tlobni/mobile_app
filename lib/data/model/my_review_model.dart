class MyReviewModel {
  int? id;
  int? sellerId;
  int? buyerId;
  int? itemId;
  String? review;
  double? ratings;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? reportStatus;
  String? reportReason;
  Seller? seller;
  Buyer? buyer;
  Item? item;
  bool? isExpanded; // Add isExpanded property

  MyReviewModel({
    this.id,
    this.sellerId,
    this.buyerId,
    this.itemId,
    this.review,
    this.ratings,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.reportStatus,
    this.reportReason,
    this.seller,
    this.buyer,
    this.item,
    this.isExpanded = false, // Initialize isExpanded with a default value
  });

  MyReviewModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sellerId = json['seller_id'];
    buyerId = json['buyer_id'];
    itemId = json['item_id'];
    review = json['review'];
    ratings = (json['ratings'] as num).toDouble();
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    reportStatus = json['report_status'];
    reportReason = json['report_reason'];
    seller = json['seller'] != null ? Seller.fromJson(json['seller']) : null;
    buyer = json['buyer'] != null ? Buyer.fromJson(json['buyer']) : null;
    item = json['item'] != null ? Item.fromJson(json['item']) : null;
    isExpanded = json['is_expanded'] ?? false; // Deserialize isExpanded
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['seller_id'] = sellerId;
    data['buyer_id'] = buyerId;
    data['item_id'] = itemId;
    data['review'] = review;
    data['ratings'] = ratings;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    data['report_status'] = reportStatus;
    data['report_reason'] = reportReason;
    if (seller != null) {
      data['seller'] = seller!.toJson();
    }
    if (buyer != null) {
      data['buyer'] = buyer!.toJson();
    }
    if (item != null) {
      data['item'] = item!.toJson();
    }
    data['is_expanded'] = isExpanded; // Serialize isExpanded
    return data;
  }

  // Optional: Add a copyWith method for immutability
  MyReviewModel copyWith({
    int? id,
    int? sellerId,
    int? buyerId,
    int? itemId,
    String? review,
    double? ratings,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? reportStatus,
    String? reportReason,
    Seller? seller,
    Buyer? buyer,
    Item? item,
    bool? isExpanded,
  }) {
    return MyReviewModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      itemId: itemId ?? this.itemId,
      review: review ?? this.review,
      ratings: ratings ?? this.ratings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      reportStatus: reportStatus ?? this.reportStatus,
      reportReason: reportReason ?? this.reportReason,
      seller: seller ?? this.seller,
      buyer: buyer ?? this.buyer,
      item: item ?? this.item,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
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
  int? price;
  String? image;
  String? description;

  Item({this.id, this.name, this.price, this.image, this.description});

  Item.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = json['price'];
    image = json['image'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['price'] = this.price;
    data['image'] = this.image;
    data['description'] = this.description;
    return data;
  }
}
