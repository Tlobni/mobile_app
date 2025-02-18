class CityModel {
  int? id;
  String? name;
  int? stateId;
  String? stateCode;
  int? countryId;
  String? countryCode;
  String? latitude;
  String? longitude;
  String? createdAt;
  String? updatedAt;
  int? flag;
  String? wikiDataId;

  CityModel(
      {this.id,
      this.name,
      this.stateId,
      this.stateCode,
      this.countryId,
      this.countryCode,
      this.latitude,
      this.longitude,
      this.createdAt,
      this.updatedAt,
      this.flag,
      this.wikiDataId});

  CityModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    stateId = json['state_id'];
    stateCode = json['state_code'];
    countryId = json['country_id'];
    countryCode = json['country_code'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    flag = json['flag'];
    wikiDataId = json['wikiDataId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['state_id'] = this.stateId;
    data['state_code'] = this.stateCode;
    data['country_id'] = this.countryId;
    data['country_code'] = this.countryCode;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['flag'] = this.flag;
    data['wikiDataId'] = this.wikiDataId;
    return data;
  }
}
