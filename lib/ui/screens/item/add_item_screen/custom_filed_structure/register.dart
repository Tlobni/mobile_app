import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/custom_field.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_checkbox_field.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_dropdown_field.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_file_field.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_number_field.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_radio_field.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_text_field.dart';

class KRegisteredFields {
  ///ADD NEW FIELD HERE
  final List<CustomField> _fields = [
    CustomFieldText(), //text field
    CustomFieldDropdown(), //dropdown field
    CustomNumberField(),
    CustomCheckboxField(),
    CustomRadioField(),
    CustomFileField()
  ];

  CustomField? get(String type) {
    CustomField? selectedField;
    for (CustomField field in _fields) {
      if (field.type == type) {
        selectedField = field;
      }
    }

    return selectedField;
  }
}
