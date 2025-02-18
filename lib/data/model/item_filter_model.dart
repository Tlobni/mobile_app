import 'dart:convert';

class ItemFilterModel {
  final String? maxPrice;
  final String? minPrice;
  final String? categoryId;
  final String? postedSince;
  final String? city;
  final String? state;
  final String? country;
  final String? area;
  final int? areaId;
  final int? radius;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? customFields;

  ItemFilterModel({
    this.maxPrice,
    this.minPrice,
    this.categoryId,
    this.postedSince,
    this.city,
    this.state,
    this.country,
    this.area,
    this.radius,
    this.areaId,
    this.latitude,
    this.longitude,
    this.customFields = const {},
  });

  ItemFilterModel copyWith({
    String? maxPrice,
    String? minPrice,
    String? categoryId,
    String? postedSince,
    String? city,
    String? state,
    String? country,
    String? area,
    int? areaId,
    int? radius,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? customFields,
  }) {
    return ItemFilterModel(
      maxPrice: maxPrice ?? this.maxPrice,
      minPrice: minPrice ?? this.minPrice,
      categoryId: categoryId ?? this.categoryId,
      postedSince: postedSince ?? this.postedSince,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      area: area ?? this.area,
      radius: radius ?? this.radius,
      areaId: areaId ?? this.areaId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      customFields: customFields ?? this.customFields,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'max_price': maxPrice,
      'min_price': minPrice,
      'category_id': categoryId,
      'posted_since': postedSince,
      'city': city,
      'state': state,
      'country': country,
      'area': area,
      'radius': radius,
      'area_id': areaId,
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  factory ItemFilterModel.fromMap(Map<String, dynamic> map) {
    return ItemFilterModel(
      city: map['city'].toString(),
      state: map['state'].toString(),
      country: map['country'].toString(),
      maxPrice: map['max_price'].toString(),
      minPrice: map['min_price'].toString(),
      categoryId: map['category_id'].toString(),
      postedSince: map['posted_since'].toString(),
      area: map['area']?.toString(),
      radius:
          map['radius'] != null ? int.tryParse(map['radius'].toString()) : null,
      areaId: map['area_id'] != null
          ? int.tryParse(map['area_id'].toString())
          : null,
      latitude: map['latitude'] != null ? map['latitude'] : null,
      longitude: map['longitude'] != null ? map['longitude'] : null,
      customFields: Map<String, dynamic>.from(map['custom_fields'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory ItemFilterModel.fromJson(String source) =>
      ItemFilterModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ItemFilterModel(maxPrice: $maxPrice, minPrice: $minPrice, categoryId: $categoryId, postedSince: $postedSince, city: $city, state: $state, country: $country, area: $area, areaId: $areaId, custom_fields: $customFields,radius:$radius,latitude:$latitude,longitude:$longitude)';
  }

  factory ItemFilterModel.createEmpty() {
    return ItemFilterModel(
      maxPrice: "",
      minPrice: "",
      categoryId: "",
      postedSince: "",
      city: '',
      state: '',
      country: '',
      area: null,
      areaId: null,
      radius: null,
      latitude: null,
      longitude: null,
      customFields: {},
    );
  }

  @override
  bool operator ==(covariant ItemFilterModel other) {
    if (identical(this, other)) return true;

    return other.maxPrice == maxPrice &&
        other.minPrice == minPrice &&
        other.categoryId == categoryId &&
        other.postedSince == postedSince &&
        other.city == city &&
        other.state == state &&
        other.country == country &&
        other.area == area &&
        other.radius == radius &&
        other.areaId == areaId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.customFields == customFields;
  }

  @override
  int get hashCode {
    return maxPrice.hashCode ^
        minPrice.hashCode ^
        categoryId.hashCode ^
        postedSince.hashCode ^
        city.hashCode ^
        state.hashCode ^
        country.hashCode ^
        area.hashCode ^
        radius.hashCode ^
        areaId.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        customFields.hashCode;
  }
}
