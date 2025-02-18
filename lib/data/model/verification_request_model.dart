class VerificationRequestModel {
  int? id;
  int? userId;
  String? status;
  String? createdAt;
  String? updatedAt;
  String? rejectionReason;
  List<VerificationFieldValues>? verificationFieldValues;

  VerificationRequestModel({
    this.id,
    this.userId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.rejectionReason,
    this.verificationFieldValues,
  });

  VerificationRequestModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    rejectionReason = json['rejection_reason'];
    if (json['verification_field_values'] != null) {
      verificationFieldValues = <VerificationFieldValues>[];
      json['verification_field_values'].forEach((v) {
        verificationFieldValues!.add(new VerificationFieldValues.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['rejection_reason'] = this.rejectionReason;
    if (this.verificationFieldValues != null) {
      data['verification_field_values'] =
          this.verificationFieldValues!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VerificationFieldValues {
  int? id;
  int? verificationFieldId;
  String? value;
  int? userId;
  int? verificationRequestId;
  String? createdAt;
  String? updatedAt;

  VerificationFieldValues(
      {this.id,
      this.verificationFieldId,
      this.value,
      this.userId,
      this.verificationRequestId,
      this.createdAt,
      this.updatedAt});

  VerificationFieldValues.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    verificationFieldId = json['verification_field_id'];
    value = json['value'];
    userId = json['user_id'];
    verificationRequestId = json['verification_request_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['verification_field_id'] = this.verificationFieldId;
    data['value'] = this.value;
    data['user_id'] = this.userId;
    data['verification_request_id'] = this.verificationRequestId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
