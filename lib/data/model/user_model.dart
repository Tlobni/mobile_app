// ignore_for_file: public_member_api_docs, sort_constructors_first

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
  int? isPersonalDetailShow;
  int? notification;
  String? profile;
  String? token;
  String? updatedAt;
  int? isVerified;

  UserModel(
      {this.address,
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
      this.notification,
      this.profile,
      this.token,
      this.updatedAt,
      this.isPersonalDetailShow,
      this.isVerified});

  UserModel.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    createdAt = json['created_at'];
    customerTotalPost = json['customertotalpost'] as int?;
    email = json['email'];
    fcmId = json['fcm_id'];
    firebaseId = json['firebase_id'];
    id = json['id'];
    isActive = json['isActive'] as int?;
    isProfileCompleted = json['isProfileCompleted'];
    type = json['type'];
    mobile = json['mobile'];
    name = json['name'];

    notification = (json['notification'] != null
        ? (json['notification'] is int)
            ? json['notification']
            : int.parse(json['notification'])
        : null);
    profile = json['profile'];
    token = json['token'];
    updatedAt = json['updated_at'];
    isVerified = json['is_verified'];
    isPersonalDetailShow = (json['show_personal_details'] != null
        ? (json['show_personal_details'] is int)
            ? json['show_personal_details']
            : int.parse(json['show_personal_details'])
        : null);
  }

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
    data['show_personal_details'] = isPersonalDetailShow;
    data['is_verified'] = isVerified;
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
