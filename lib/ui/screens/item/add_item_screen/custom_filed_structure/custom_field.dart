import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/register.dart';
import 'package:flutter/material.dart';

///Structure
abstract class CustomField {
  abstract String type;

  late BuildContext context;

  void init() {}
  dynamic update;
  Map parameters = {};

  Widget render();
}

class CustomFieldBuilder {
  final Map field;

  CustomFieldBuilder(this.field);

  ////getting its field type
  late CustomField? customField = KRegisteredFields().get(field['type']);

  void init() {
    customField?.parameters = field;
    //Calling init of custom field from here and this init will be called into the UI
    customField?.init();
  }

  void stateUpdater(StateSetter updater) {
    customField?.update = updater;
  }

  Widget build(BuildContext context) {
    ///setting parameters from here
    customField?.parameters = field;

    ///setting context from here
    customField?.context = context;

    //Calling render function so we can get widget
    Widget? render = customField?.render();
    return render ?? Container();
  }
}
