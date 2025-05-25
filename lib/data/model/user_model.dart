// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:tlobni/data/model/category_model.dart';

class UserModel {
  String? address;
  String? createdAt;
  int? customerTotalPost;
  String? email;
  String? fcmId;
  String? firebaseId;
  int? id;
  int? isActive;
  bool? isProfileCompleted;
  String? type;
  String? mobile;
  String? name;
  String? bio;
  String? website;
  String? facebook;
  String? twitter;
  String? instagram;
  String? tiktok;
  int? isPersonalDetailShow;
  int? notification;
  String? profile;
  String? token;
  String? updatedAt;
  int? isVerified;
  String? country, city, state;
  List<int>? categoriesIds;
  List<CategoryModel>? categoriesModels;
  int? totalReviews;
  double? averageRating;
  bool? isFeatured;

  UserModel({
    this.address,
    this.createdAt,
    this.customerTotalPost,
    this.email,
    this.fcmId,
    this.firebaseId,
    this.id,
    this.isActive,
    this.isProfileCompleted,
    this.type,
    this.mobile,
    this.name,
    this.bio,
    this.website,
    this.facebook,
    this.twitter,
    this.instagram,
    this.tiktok,
    this.notification,
    this.profile,
    this.token,
    this.updatedAt,
    this.isPersonalDetailShow,
    this.isVerified,
    this.categoriesModels,
    this.totalReviews,
    this.averageRating,
    this.isFeatured,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    createdAt = json['created_at'];
    customerTotalPost = json['customertotalpost'] as int?;
    email = json['email'];
    fcmId = json['fcm_id'];
    firebaseId = json['firebase_id'];
    id = json['id'];
    isActive = json['isActive'] as int? ?? json['status'] as int?;
    isProfileCompleted = json['isProfileCompleted'];
    type = json['type'];
    bio = json['bio'];
    website = json['website'];
    facebook = json['facebook'];
    twitter = json['twitter'];
    instagram = json['instagram'];
    tiktok = json['tiktok'];
    mobile = json['mobile'];
    name = json['name'];
    categoriesModels = json['categories_models'] == null
        ? null
        : (json['categories_models'] as List<dynamic>).map((e) => CategoryModel.fromJson(e)).toList();

    notification = (json['notification'] != null
        ? (json['notification'] is int)
            ? json['notification']
            : int.parse(json['notification'].toString())
        : null);
    profile = json['profile'];
    token = json['token'];
    updatedAt = json['updated_at'];
    categoriesIds = json['categories'] is List
        ? (json['categories'] as List<dynamic>).map((e) => int.parse(e.toString())).toList()
        : (json['categories'] as String?)?.split(',').where((e) => e.isNotEmpty).map(int.parse).toList();
    country = json['country'];
    city = json['city'];
    state = json['state'];
    isVerified = json['is_verified'];
    isPersonalDetailShow = (json['show_personal_details'] != null
        ? (json['show_personal_details'] is int)
            ? json['show_personal_details']
            : int.parse(json['show_personal_details'].toString())
        : null);
    totalReviews = json['total_reviews'];
    averageRating = double.tryParse(json['average_rating'] ?? '');
    isFeatured = json['is_featured'] == 1 || json['is_featured'] == true;
  }

  String? get location => country == null || city == null ? null : '$city, $country';

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['created_at'] = createdAt;
    data['customertotalpost'] = customerTotalPost;
    data['email'] = email;
    data['fcm_id'] = fcmId;
    data['firebase_id'] = firebaseId;
    data['id'] = id;
    data['isActive'] = isActive;
    data['isProfileCompleted'] = isProfileCompleted;
    data['type'] = type;
    data['mobile'] = mobile;
    data['name'] = name;
    data['notification'] = notification;
    data['profile'] = profile;
    data['token'] = token;
    data['updated_at'] = updatedAt;
    data['country'] = country;
    data['city'] = city;
    data['state'] = state;
    data['categories'] = categoriesIds?.join(',');
    data['show_personal_details'] = isPersonalDetailShow;
    data['is_verified'] = isVerified;
    data['bio'] = bio;
    data['website'] = website;
    data['facebook'] = facebook;
    data['twitter'] = twitter;
    data['instagram'] = instagram;
    data['tiktok'] = tiktok;
    data['categories_models'] = categoriesModels?.map((e) => e.toJson()).toList();
    data['total_reviews'] = totalReviews;
    data['average_rating'] = averageRating?.toString();
    data['is_featured'] = isFeatured;
    return data;
  }

  @override
  String toString() {
    return 'UserModel(address: $address, createdAt: $createdAt, customertotalpost: $customerTotalPost, email: $email, fcmId: $fcmId, firebaseId: $firebaseId, id: $id, isActive: $isActive, isProfileCompleted: $isProfileCompleted, type: $type, mobile: $mobile, name: $name, profile: $profile, token: $token, updatedAt: $updatedAt,notification:$notification,isPersonalDetailShow:$isPersonalDetailShow,isVerified:$isVerified)';
  }
}

class BuyerModel {
  int? id;
  String? name;
  String? profile;

  BuyerModel({this.id, this.name, this.profile});

  BuyerModel.fromJson(Map<String, dynamic> json) {
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
