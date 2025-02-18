import 'package:flutter/material.dart';

abstract class CloudState<T extends StatefulWidget> extends State<T> {
  static Map<dynamic, dynamic> cloudData = {};
  Map<dynamic, dynamic> getCloudDataAll() {
    return cloudData;
  }

  //Global single listener
  static void Function(String key, dynamic value)? onItemAdd;
  static final List<void Function(String key, dynamic value)> _listeners = [];

  void listenOn(String key, Function(dynamic value) callBack) {
    _listeners.add((String addedKey, dynamic addedValue) {
      if (key == addedKey) {
        callBack.call(addedValue);
      } else if (key == "*") {
        callBack.call({addedKey: addedValue});
      }
    });
  }

  void notify(String key, dynamic value) {
    for (var element in _listeners) {
      element.call(key, value);
    }
  }

  void clearCloudData(String key) {
    cloudData.remove(key);
  }

  dynamic getCloudData(String key) {
    return cloudData[key];
  }

  void addCloudData(String key, dynamic value) {
    cloudData.addAll(Map<dynamic, dynamic>.from({key: value}));
    notify(key, value);
  }

  void addScreenValue(String key, dynamic value) {
    cloudData.addAll({key: value});
    notify(key, value);
  }

  void setCloudData(String key, dynamic value) {
    cloudData[key] = value;
    notify(key, value);
  }

  void appendToList<T>(String key, T value, {bool? disableClone}) {
    if (!cloudData.containsKey(key)) {
      cloudData[key] = [value];
    }
    if (cloudData[key] is List<T>) {
      if (disableClone == true) {
        if (!(cloudData[key] as List<T>).contains(value)) {
          (cloudData[key] as List<T>).add(value);
          notify(key, value);
        }
      } else {
        (cloudData[key] as List<T>).add(value);
        notify(key, value);
      }
    }
  }

  void screenData(String key, dynamic value) {
    if (cloudData.containsKey(runtimeType)) {
      (cloudData[runtimeType] as Map).addAll({key: value});
    } else {
      cloudData[runtimeType] = {};
      (cloudData[runtimeType] as Map).addAll({key: value});
    }
  }

  dynamic getScreenData(State screen, String key) {
    return cloudData[screen][key] ?? {};
  }

  @override
  Widget build(BuildContext context);
}
