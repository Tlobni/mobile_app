class BlogModel {
  int? id;
  String? title;
  String? slug;
  String? description;
  String? image;
  List<String>? tags;
  int? views;
  int? categoryId;
  String? createdAt;
  String? updatedAt;

  BlogModel(
      {this.id,
      this.title,
      this.slug,
      this.description,
      this.image,
      this.tags,
      this.views,
      this.categoryId,
      this.createdAt,
      this.updatedAt});

  BlogModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    slug = json['slug'];
    description = json['description'];
    image = json['image'];
    tags = json['tags'].cast<String>();
    views = json['views'];
    categoryId = json['category_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['slug'] = this.slug;
    data['description'] = this.description;
    data['image'] = this.image;
    data['tags'] = this.tags;
    data['views'] = this.views;
    data['category_id'] = this.categoryId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
