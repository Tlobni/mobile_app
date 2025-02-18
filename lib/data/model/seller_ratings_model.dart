class SellerRatingsModel {
  Seller? seller;
  Ratings? ratings;

  SellerRatingsModel({this.seller, this.ratings});

  SellerRatingsModel.fromJson(Map<String, dynamic> json) {
    seller = json['seller'] != null ? Seller.fromJson(json['seller']) : null;
    ratings =
        json['ratings'] != null ? Ratings.fromJson(json['ratings']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (this.seller != null) {
      data['seller'] = this.seller!.toJson();
    }
    if (this.ratings != null) {
      data['ratings'] = this.ratings!.toJson();
    }
    return data;
  }
}

class Seller {
  int? id;
  String? name;
  String? email;
  String? mobile;
  String? profile;
  int? isVerified;
  String? createdAt;
  double? averageRating;

  Seller({
    this.id,
    this.name,
    this.email,
    this.mobile,
    this.profile,
    this.isVerified,
    this.createdAt,
    this.averageRating,
  });

  Seller.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    mobile = json['mobile'];
    profile = json['profile'];
    isVerified = json['is_verified'];
    createdAt = json['created_at'];
    if (json['average_rating'] is int) {
      averageRating = (json['average_rating'] as int).toDouble();
    } else if (json['average_rating'] is double) {
      averageRating = json['average_rating'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = this.id;
    data['name'] = this.name;
    data['email'] = this.email;
    data['mobile'] = this.mobile;
    data['profile'] = this.profile;
    data['is_verified'] = this.isVerified;
    data['created_at'] = this.createdAt;
    data['average_rating'] = this.averageRating;
    return data;
  }
}

class Ratings {
  int? currentPage;
  List<UserRatings>? userRatings;
  int? total;

  Ratings({
    this.currentPage,
    this.userRatings,
    this.total,
  });

  Ratings.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    total = json['total'];
    if (json['data'] != null) {
      userRatings = [];
      json['data'].forEach((v) {
        userRatings!.add(UserRatings.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['current_page'] = this.currentPage;
    data['total'] = this.total;
    if (this.userRatings != null) {
      data['data'] = this.userRatings!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UserRatings {
  int? id;
  int? sellerId;
  int? buyerId;
  int? itemId;
  String? review;
  double? ratings;
  String? createdAt;
  String? updatedAt;
  Buyer? buyer;
  bool? isExpanded;

  UserRatings({
    this.id,
    this.sellerId,
    this.buyerId,
    this.itemId,
    this.review,
    this.ratings,
    this.createdAt,
    this.updatedAt,
    this.buyer,
    this.isExpanded = false,
  });

  UserRatings.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sellerId = json['seller_id'];
    buyerId = json['buyer_id'];
    itemId = json['item_id'];
    review = json['review'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    buyer = json['buyer'] != null ? Buyer.fromJson(json['buyer']) : null;
    if (json['ratings'] is int) {
      ratings = (json['ratings'] as int).toDouble();
    } else if (json['ratings'] is double) {
      ratings = json['ratings'];
    }
    isExpanded = json['is_expanded'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = this.id;
    data['seller_id'] = this.sellerId;
    data['buyer_id'] = this.buyerId;
    data['item_id'] = this.itemId;
    data['review'] = this.review;
    data['ratings'] = this.ratings;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.buyer != null) {
      data['buyer'] = this.buyer!.toJson();
    }
    data['is_expanded'] = this.isExpanded;
    return data;
  }

  UserRatings copyWith({
    int? id,
    int? sellerId,
    int? buyerId,
    int? itemId,
    String? review,
    double? ratings,
    String? createdAt,
    String? updatedAt,
    Buyer? buyer,
    bool? isExpanded,
  }) {
    return UserRatings(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      itemId: itemId ?? this.itemId,
      review: review ?? this.review,
      ratings: ratings ?? this.ratings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      buyer: buyer ?? this.buyer,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

/*class UserRatings {
  int? id;
  int? sellerId;
  int? buyerId;
  int? itemId;
  String? review;
  double? ratings;
  String? createdAt;
  String? updatedAt;
  Buyer? buyer;
  bool? isExpanded;

  UserRatings({
    this.id,
    this.sellerId,
    this.buyerId,
    this.itemId,
    this.review,
    this.ratings,
    this.createdAt,
    this.updatedAt,
    this.buyer,
    this.isExpanded = false
  });

  UserRatings.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sellerId = json['seller_id'];
    buyerId = json['buyer_id'];
    itemId = json['item_id'];
    review = json['review'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    buyer = json['buyer'] != null ? Buyer.fromJson(json['buyer']) : null;
    if (json['ratings'] is int) {
      ratings = (json['ratings'] as int).toDouble();
    } else if (json['ratings'] is double) {
      ratings = json['ratings'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = this.id;
    data['seller_id'] = this.sellerId;
    data['buyer_id'] = this.buyerId;
    data['item_id'] = this.itemId;
    data['review'] = this.review;
    data['ratings'] = this.ratings;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.buyer != null) {
      data['buyer'] = this.buyer!.toJson();
    }
    return data;
  }
}*/

class Buyer {
  int? id;
  String? name;
  String? profile;

  Buyer({
    this.id,
    this.name,
    this.profile,
  });

  Buyer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profile = json['profile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = this.id;
    data['name'] = this.name;
    data['profile'] = this.profile;
    return data;
  }
}
