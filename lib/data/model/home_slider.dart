class HomeSlider {
  int? id;
  String? sequence;
  String? thirdPartyLink;
  String? modelType;
  String? image;
  int? modelId;
  CategorySlider? model;

  HomeSlider(
      {this.id,
      this.sequence,
      this.thirdPartyLink,
      this.modelId,
      this.image,
      this.modelType,
      this.model});

  HomeSlider.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sequence = json['sequence'];
    thirdPartyLink = json['third_party_link'];
    modelId = json['model_id'];
    image = json['image'];
    modelType = json['model_type'];
    if (json['model'] != null &&
        modelType != null &&
        modelType!.contains("Category")) {
      model = CategorySlider.fromJson(json['model']);
    } else {
      model = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sequence'] = sequence;
    data['third_party_link'] = thirdPartyLink;
    data['model_id'] = modelId;
    data['model_type'] = modelType;
    data['image'] = image;

    if (model != null) {
      data['model'] = model!.toJson();
    }
    return data;
  }
}

class CategorySlider {
  int? id;
  String? name;
  int? subCategoriesCount;
  int? parentCategoryId;

  CategorySlider(
      {this.id, this.name, this.subCategoriesCount, this.parentCategoryId});

  CategorySlider.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['translated_name'];
    subCategoriesCount = json['subcategories_count'];
    parentCategoryId = json['parent_category_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['translated_name'] = name;
    data['subcategories_count'] = subCategoriesCount;
    data['parent_category_id'] = parentCategoryId;

    return data;
  }
}
