import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/custom_field/custom_field_model.dart';
import 'package:eClassify/data/model/seller_ratings_model.dart';

class ItemModel {
  int? id;
  String? name;
  String? slug;
  String? description;
  double? price;
  String? image;
  dynamic watermarkimage;
  double? _latitude;
  double? _longitude;
  String? address;
  String? contact;
  int? totalLikes;
  int? views;
  String? type;
  String? status;
  bool? active;
  String? videoLink;
  User? user;
  List<GalleryImages>? galleryImages;
  List<ItemOffers>? itemOffers;
  CategoryModel? category;
  List<CustomFieldModel>? customFields;
  bool? isLike;
  bool? isFeature;
  String? created;
  String? itemType;
  int? userId;
  int? categoryId;
  bool? isAlreadyOffered;
  bool? isAlreadyReported;
  String? allCategoryIds;
  String? rejectedReason;
  int? areaId;
  String? area;
  String? city;
  String? state;
  String? country;
  int? isPurchased;
  List<UserRatings>? review;

  double? get latitude => _latitude;

  set latitude(dynamic value) {
    if (value is int) {
      _latitude = value.toDouble();
    } else if (value is double) {
      _latitude = value;
    } else {
      _latitude = null;
    }
  }

  double? get longitude => _longitude;

  set longitude(dynamic value) {
    if (value is int) {
      _longitude = value.toDouble();
    } else if (value is double) {
      _longitude = value;
    } else {
      _longitude = null;
    }
  }

  ItemModel(
      {this.id,
      this.name,
      this.slug,
      this.category,
      this.description,
      this.price,
      this.image,
      this.watermarkimage,
      dynamic latitude,
      dynamic longitude,
      this.address,
      this.contact,
      this.type,
      this.status,
      this.active,
      this.totalLikes,
      this.views,
      this.videoLink,
      this.user,
      this.galleryImages,
      this.itemOffers,
      this.customFields,
      this.isLike,
      this.isFeature,
      this.created,
      this.itemType,
      this.userId,
      this.categoryId,
      this.isAlreadyOffered,
      this.isAlreadyReported,
      this.rejectedReason,
      this.allCategoryIds,
      this.areaId,
      this.area,
      this.city,
      this.state,
      this.country,
      this.review,
      this.isPurchased}) {
    this.latitude = latitude;
    this.longitude = longitude;
  }

  ItemModel copyWith(
      {int? id,
      String? name,
      String? slug,
      String? description,
      double? price,
      String? image,
      dynamic watermarkimage,
      dynamic latitude,
      dynamic longitude,
      String? address,
      String? contact,
      int? totalLikes,
      int? views,
      String? type,
      String? status,
      bool? active,
      String? videoLink,
      User? user,
      List<GalleryImages>? galleryImages,
      List<ItemOffers>? itemOffers,
      CategoryModel? category,
      List<CustomFieldModel>? customFields,
      bool? isLike,
      bool? isFeature,
      String? created,
      String? itemType,
      int? userId,
      bool? isAlreadyOffered,
      bool? isAlreadyReported,
      String? allCategoryIds,
      int? categoryId,
      int? areaId,
      String? area,
      String? city,
      String? state,
      String? country,
      int? isPurchased,
      List<UserRatings>? review}) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      watermarkimage: watermarkimage ?? this.watermarkimage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      type: type ?? this.type,
      status: status ?? this.status,
      active: active ?? this.active,
      totalLikes: totalLikes ?? this.totalLikes,
      views: views ?? this.views,
      videoLink: videoLink ?? this.videoLink,
      user: user ?? this.user,
      galleryImages: galleryImages ?? this.galleryImages,
      itemOffers: itemOffers ?? this.itemOffers,
      customFields: customFields ?? this.customFields,
      isLike: isLike ?? this.isLike,
      isFeature: isFeature ?? this.isFeature,
      created: created ?? this.created,
      itemType: itemType ?? this.itemType,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      isAlreadyOffered: isAlreadyOffered ?? this.isAlreadyOffered,
      isAlreadyReported: isAlreadyReported ?? this.isAlreadyReported,
      allCategoryIds: allCategoryIds ?? this.allCategoryIds,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      areaId: areaId ?? this.areaId,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      isPurchased: isPurchased ?? this.isPurchased,
      review: review ?? this.review,
    );
  }

  ItemModel.fromJson(Map<String, dynamic> json) {
    if (json['area'] != null) {
      areaId = json['area']['id'];
      area = json['area']['name'];
    }

    // Ensure price is formatted to 2 decimal places
    /* if (json['price'] is int) {
      price = double.parse((json['price'] as int).toStringAsFixed(2));
    } else if (json['price'] is double) {
      price = double.parse((json['price'] as double).toStringAsFixed(2));
    } else {
      price = 0.00;
    }*/

    if (json['price'] is int) {
      price = (json['price'] as int).toDouble();
    } else {
      price = json['price'];
    }

    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    category = json['category'] != null
        ? CategoryModel.fromJson(json['category'])
        : null;
    totalLikes = json['total_likes'];
    views = json['clicks'];
    description = json['description'];

    image = json['image'];
    watermarkimage = json['watermark_image'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    address = json['address'];
    contact = json['contact'];
    type = json['type'];
    status = json['status'];
    active = json['active'] == 0 ? false : true;
    videoLink = json['video_link'];
    isLike = json['is_liked'];
    isFeature = json['is_feature'];
    created = json['created_at'];
    itemType = json['item_type'];
    userId = json['user_id'];
    categoryId = json['category_id'];
    isAlreadyOffered = json['is_already_offered'];
    isAlreadyReported = json['is_already_reported'];
    allCategoryIds = json['all_category_ids'];
    rejectedReason = json['rejected_reason'];
    city = json['city'];
    state = json['state'];
    country = json['country'];
    isPurchased = json['is_purchased'];
    if (json['review'] != null) {
      review = <UserRatings>[];
      json['review'].forEach((v) {
        review!.add(UserRatings.fromJson(v));
      });
    }
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    if (json['gallery_images'] != null) {
      galleryImages = <GalleryImages>[];
      json['gallery_images'].forEach((v) {
        galleryImages!.add(GalleryImages.fromJson(v));
      });
    }
    if (json['item_offers'] != null) {
      itemOffers = <ItemOffers>[];
      json['item_offers'].forEach((v) {
        itemOffers!.add(ItemOffers.fromJson(v));
      });
    }
    if (json['custom_fields'] != null) {
      customFields = <CustomFieldModel>[];
      json['custom_fields'].forEach((v) {
        customFields!.add(CustomFieldModel.fromMap(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['description'] = description;
    data['price'] = price;
    data['total_likes'] = totalLikes;
    data['clicks'] = views;
    data['image'] = image;
    data['watermark_image'] = watermarkimage;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['address'] = address;
    data['contact'] = contact;
    data['type'] = type;
    data['status'] = status;
    data['active'] = active;
    data['video_link'] = videoLink;
    data['is_liked'] = isLike;
    data['is_feature'] = isFeature;
    data['created_at'] = created;
    data['item_type'] = itemType;
    data['user_id'] = userId;
    data['category_id'] = categoryId;
    data['is_already_offered'] = isAlreadyOffered;
    data['is_already_reported'] = isAlreadyReported;
    data['all_category_ids'] = allCategoryIds;
    data['rejected_reason'] = rejectedReason;
    data['is_purchased'] = isPurchased;
    if (review != null) {
      data['review'] = review!.map((v) => v.toJson()).toList();
    }
    data['city'] = city;
    data['state'] = state;
    data['country'] = country;
    data['category'] = category!.toJson();
    if (areaId != null && area != null) {
      data['area'] = {
        'id': areaId,
        'name': area,
      };
    }
    data['user'] = user!.toJson();

    if (galleryImages != null) {
      data['gallery_images'] = galleryImages!.map((v) => v.toJson()).toList();
    }
    if (itemOffers != null) {
      data['item_offers'] = itemOffers!.map((v) => v.toJson()).toList();
    }
    if (customFields != null) {
      data['custom_fields'] = customFields!.map((v) => v.toMap()).toList();
    }
    return data;
  }

  @override
  String toString() {
    return 'ItemModel{id: $id, name: $name,slug:$slug, description: $description, price: $price, image: $image, watermarkimage: $watermarkimage, latitude: $latitude, longitude: $longitude, address: $address, contact: $contact, total_likes: $totalLikes,isLiked: $isLike, isFeature: $isFeature,views: $views, type: $type, status: $status, active: $active, videoLink: $videoLink, user: $user, galleryImages: $galleryImages,itemOffers:$itemOffers, category: $category, customFields: $customFields,createdAt:$created,itemType:$itemType,userId:$userId,categoryId:$categoryId,isAlreadyOffered:$isAlreadyOffered,isAlreadyReported:$isAlreadyReported,allCategoryId:$allCategoryIds,rejected_reason:$rejectedReason,area_id:$areaId,area:$area,city:$city,state:$state,country:$country,is_purchased:$isPurchased,review:$review}';
  }
}

class User {
  int? id;
  String? name;
  String? mobile;
  String? email;
  String? type;
  String? profile;
  String? fcmId;
  String? firebaseId;
  int? status;
  String? apiToken;
  dynamic address;
  String? createdAt;
  String? updatedAt;
  int? showPersonalDetails;
  int? isVerified;

  User(
      {this.id,
      this.name,
      this.mobile,
      this.email,
      this.type,
      this.profile,
      this.fcmId,
      this.firebaseId,
      this.status,
      this.apiToken,
      this.address,
      this.createdAt,
      this.updatedAt,
      this.isVerified,
      this.showPersonalDetails});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    mobile = json['mobile'];
    email = json['email'];
    type = json['type'];
    profile = json['profile'];
    fcmId = json['fcm_id'];
    firebaseId = json['firebase_id'];
    status = json['status'];
    apiToken = json['api_token'];
    address = json['address'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isVerified = json['is_verified'];
    showPersonalDetails = json['show_personal_details'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['mobile'] = mobile;
    data['email'] = email;
    data['type'] = type;
    data['profile'] = profile;
    data['fcm_id'] = fcmId;
    data['firebase_id'] = firebaseId;
    data['status'] = status;
    data['api_token'] = apiToken;
    data['address'] = address;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_verified'] = isVerified;
    data['show_personal_details'] = showPersonalDetails;
    return data;
  }
}

class GalleryImages {
  int? id;
  String? image;
  String? createdAt;
  String? updatedAt;
  int? itemId;

  GalleryImages(
      {this.id, this.image, this.createdAt, this.updatedAt, this.itemId});

  GalleryImages.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    image = json['image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    itemId = json['item_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['image'] = image;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['item_id'] = itemId;
    return data;
  }
}

class ItemOffers {
  int? id;
  int? sellerId;
  int? buyerId;
  String? createdAt;
  String? updatedAt;
  double? amount;

  ItemOffers(
      {this.id,
      this.sellerId,
      this.createdAt,
      this.updatedAt,
      this.buyerId,
      this.amount});

  ItemOffers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    buyerId = json['buyer_id'];
    sellerId = json['seller_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];

    // Handle amount being int or double
    if (json['amount'] is int) {
      amount = (json['amount'] as int).toDouble();
    } else if (json['amount'] is double) {
      amount = json['amount'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['buyer_id'] = buyerId;
    data['seller_id'] = sellerId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['amount'] = amount;
    return data;
  }
}

/*class ItemOffers {
  int? id;
  int? sellerId;
  int? buyerId;
  String? createdAt;
  String? updatedAt;
  double? amount;

  ItemOffers(
      {this.id,
      this.sellerId,
      this.createdAt,
      this.updatedAt,
      this.buyerId,
      this.amount});

  ItemOffers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    buyerId = json['buyer_id'];
    sellerId = json['seller_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    amount = json['amount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['buyer_id'] = buyerId;
    data['seller_id'] = sellerId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['amount'] = amount;
    return data;
  }
}*/
