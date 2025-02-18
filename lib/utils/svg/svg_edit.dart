import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

class SVGEdit {
  XmlDocument? document;

  void changeWhere(XmlNode node,
      {required String id, required String attribute, String? value}) {
    if (node is XmlElement) {
      String? attr = node.getAttribute(attribute);

      if (attr != null && attr.isNotEmpty && id == node.getAttribute("id")) {
        node.setAttribute(attribute, value);
      }
      for (final child in node.children) {
        changeWhere(child, id: id, attribute: attribute, value: value);
      }
    }
  }

  void change(
    String id, {
    required String attribute,
    required String value,
  }) {
    document?.childElements.forEach((element) {
      changeWhere(element, id: id, attribute: attribute, value: value);
    });
  }

  void loadSVG(String? data) {
    document = XmlDocument.parse(data ?? "");
  }

  String? toSVGString() {
    return document?.toXmlString();
  }

  String flutterColorToHexColor(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
