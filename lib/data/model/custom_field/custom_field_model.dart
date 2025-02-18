class CustomFieldModel {
  int? id;
  String? name;
  List? value;
  String? type;
  String? image;
  int? required;
  int? minLength;
  int? maxLength;
  dynamic values;

  CustomFieldModel(
      {this.id,
      this.name,
      this.type,
      this.values,
      this.image,
      this.required,
      this.maxLength,
      this.minLength,
      this.value});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'values': values,
      'image': image,
      'required': required,
      'min_length': minLength,
      'max_length': maxLength,
      'value': value,
    };
  }

  factory CustomFieldModel.fromMap(Map<String, dynamic> map) {
    return CustomFieldModel(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      values: map['values'] as dynamic,
      image: map['image'],
      required: map['required'],
      maxLength: map['max_length'],
      minLength: map['min_length'],
      value: map['value'],
    );
  }

  @override
  String toString() {
    return 'CustomFieldModel(id: $id, name: $name, type: $type, image: $image, required: $required, minLength: $minLength, maxLength: $maxLength, values: $values,value:$value)';
  }
}

class VerificationFieldModel {
  int? id;
  String? name;
  String? type;
  int? required;
  int? minLength;
  int? maxLength;
  String? status;
  dynamic values;

  VerificationFieldModel({
    this.id,
    this.name,
    this.type,
    this.values,
    this.required,
    this.maxLength,
    this.minLength,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'values': values,
      'required': required,
      'min_length': minLength,
      'max_length': maxLength,
      'status': status,
    };
  }

  factory VerificationFieldModel.fromMap(Map<String, dynamic> map) {
    return VerificationFieldModel(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      values: map['values'] as dynamic,
      required: map['is_required'],
      maxLength: map['max_length'],
      minLength: map['min_length'],
      status: map['status'],
    );
  }

  @override
  String toString() {
    return 'VerificationFieldModel(id: $id, name: $name, type: $type, required: $required, minLength: $minLength, maxLength: $maxLength, values: $values,status:$status)';
  }
}
