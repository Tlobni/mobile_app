// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:tlobni/utils/api.dart';

class Type {
  String? id;
  String? type;

  Type({this.id, this.type});

  Type.fromJson(Map<String, dynamic> json) {
    id = json[Api.id].toString();
    type = json[Api.type];
  }
}

// Define enum for category types
enum CategoryType {
  serviceExperience('service_experience'),
  providers('providers');

  final String value;
  const CategoryType(this.value);

  factory CategoryType.fromString(String? value) {
    return CategoryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CategoryType.serviceExperience,
    );
  }
}

class CategoryModel {
  final int? id;
  final String? name;
  final String? url;
  final List<CategoryModel>? children;
  final String? description;
  final CategoryType? type; // Added type field

  //final String translatedName;
  final int? subcategoriesCount;

  CategoryModel({
    this.id,
    this.name,
    this.url,
    this.description,
    this.children,
    this.subcategoriesCount,
    this.type, // Added type parameter
    //required this.translatedName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    try {
      List<dynamic> childData = json['subcategories'] ?? [];
      List<CategoryModel> children =
          childData.map((child) => CategoryModel.fromJson(child)).toList();

      return CategoryModel(
          id: json['id'],
          //name: json['name'],
          name: json['translated_name'],
          url: json['image'],
          subcategoriesCount: json['subcategories_count'] ?? 0,
          children: children,
          type: CategoryType.fromString(json['type']), // Parse type from JSON
          description: json['description'] ?? "");
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      //'name': name,
      'translated_name': name,
      'image': url,
      'subcategories_count': subcategoriesCount,
      "description": description,
      'type': type?.value, // Convert type to string value
      'subcategories': children!.map((child) => child.toJson()).toList(),
    };
    return data;
  }

  @override
  String toString() {
    return 'CategoryModel( id: $id, translated_name:$name, url: $url, descrtiption:$description, type: ${type?.value}, children: $children,subcategories_count:$subcategoriesCount)';
  }
}
