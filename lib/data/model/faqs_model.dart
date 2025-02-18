class FaqsModel {
  int? id;
  String? question;
  String? answer;
  String? createdAt;
  String? updatedAt;
  bool isExpanded;

  FaqsModel({
    this.id,
    this.question,
    this.answer,
    this.createdAt,
    this.updatedAt,
    this.isExpanded = false,
  });

  FaqsModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        question = json['question'],
        answer = json['answer'],
        createdAt = json['created_at'],
        updatedAt = json['updated_at'],
        isExpanded = json['is_expanded'] ?? false;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['question'] = question;
    data['answer'] = answer;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_expanded'] = isExpanded;
    return data;
  }
}
