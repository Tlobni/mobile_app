import 'dart:convert';

class SubscriptionPackageLimit {
  SubscriptionPackageLimit({
    required this.totalLimitOfAdvertisement,
    required this.totalLimitOfItem,
    required this.usedLimitOfAdvertisement,
    required this.usedLimitOfItem,
  });

  final dynamic totalLimitOfAdvertisement;
  final dynamic totalLimitOfItem;
  final dynamic usedLimitOfAdvertisement;
  final dynamic usedLimitOfItem;

  SubscriptionPackageLimit copyWith({
    dynamic totalLimitOfAdvertisement,
    dynamic totalLimitOfItem,
    dynamic usedLimitOfAdvertisement,
    dynamic usedLimitOfItem,
  }) {
    return SubscriptionPackageLimit(
      totalLimitOfAdvertisement:
          totalLimitOfAdvertisement ?? this.totalLimitOfAdvertisement,
      totalLimitOfItem: totalLimitOfItem ?? this.totalLimitOfItem,
      usedLimitOfAdvertisement:
          usedLimitOfAdvertisement ?? this.usedLimitOfAdvertisement,
      usedLimitOfItem: usedLimitOfItem ?? this.usedLimitOfItem,
    );
  }

  factory SubscriptionPackageLimit.fromJson(String str) =>
      SubscriptionPackageLimit.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SubscriptionPackageLimit.fromMap(Map<String, dynamic> json) =>
      SubscriptionPackageLimit(
        totalLimitOfAdvertisement: json["total_limit_of_advertisement"],
        totalLimitOfItem: json["total_limit_of_item"],
        usedLimitOfAdvertisement: json["used_limit_of_advertisement"],
        usedLimitOfItem: json["used_limit_of_item"],
      );

  Map<String, dynamic> toMap() => {
        "total_limit_of_advertisement": totalLimitOfAdvertisement,
        "total_limit_of_item": totalLimitOfItem,
        "used_limit_of_advertisement": usedLimitOfAdvertisement,
        "used_limit_of_item": usedLimitOfItem,
      };

  @override
  String toString() {
    return 'SubcriptionPackageLimit(totalLimitOfAdvertisement: $totalLimitOfAdvertisement, totalLimitOfItem: $totalLimitOfItem, usedLimitOfAdvertisement: $usedLimitOfAdvertisement, usedLimitOfItem: $usedLimitOfItem)';
  }
}
