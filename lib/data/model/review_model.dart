class UserReviewModel {
  int? id;
  int? userId; // ID of the expert/business being reviewed
  int? reviewerId; // ID of the user leaving the review
  int?
      serviceId; // Optional: ID of the specific service being reviewed (null if profile review)
  String? review;
  double? ratings;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? reportStatus;
  String? reportReason;
  UserDetails? user; // The expert/business being reviewed
  UserDetails? reviewer; // The user leaving the review
  ServiceDetails?
      service; // Optional: Details about the service (null if profile review)
  bool? isExpanded;

  UserReviewModel({
    this.id,
    this.userId,
    this.reviewerId,
    this.serviceId,
    this.review,
    this.ratings,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.reportStatus,
    this.reportReason,
    this.user,
    this.reviewer,
    this.service,
    this.isExpanded = false,
  });

  UserReviewModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    reviewerId = json['reviewer_id'];
    serviceId = json['service_id'];
    review = json['review'];
    ratings = (json['ratings'] as num?)?.toDouble();
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    reportStatus = json['report_status'];
    reportReason = json['report_reason'];
    user = json['user'] != null ? UserDetails.fromJson(json['user']) : null;
    reviewer = json['reviewer'] != null
        ? UserDetails.fromJson(json['reviewer'])
        : null;
    service = json['service'] != null
        ? ServiceDetails.fromJson(json['service'])
        : null;
    isExpanded = json['is_expanded'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['reviewer_id'] = reviewerId;
    data['service_id'] = serviceId;
    data['review'] = review;
    data['ratings'] = ratings;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    data['report_status'] = reportStatus;
    data['report_reason'] = reportReason;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (reviewer != null) {
      data['reviewer'] = reviewer!.toJson();
    }
    if (service != null) {
      data['service'] = service!.toJson();
    }
    data['is_expanded'] = isExpanded;
    return data;
  }
}

class UserDetails {
  int? id;
  String? name;
  String? profile;
  String? userType; // 'expert' or 'business'

  UserDetails({this.id, this.name, this.profile, this.userType});

  UserDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    profile = json['profile'];
    userType = json['user_type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['profile'] = profile;
    data['user_type'] = userType;
    return data;
  }
}

class ServiceDetails {
  int? id;
  String? name;
  int? price;
  String? image;
  String? description;
  String? type; // 'service' or 'experience'

  ServiceDetails(
      {this.id,
      this.name,
      this.price,
      this.image,
      this.description,
      this.type});

  ServiceDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = json['price'];
    image = json['image'];
    description = json['description'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['price'] = price;
    data['image'] = image;
    data['description'] = description;
    data['type'] = type;
    return data;
  }
}
