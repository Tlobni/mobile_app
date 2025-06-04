import 'package:flutter/material.dart';
import 'package:tlobni/utils/extensions/lib/list.dart';

extension WidgetIterableExtension<T extends Widget> on Iterable<T> {
  List<Widget> mapExpandedPutBetween(Widget putBetween) => map<Widget>((e) => Expanded(child: e)).toList()..putBetweenEach(putBetween);

  List<Widget> mapExpandedSpaceBetween(double space) => mapExpandedPutBetween(SizedBox(height: space, width: space));

  Iterable<Widget> putBetween(Widget putBetween) sync* {
    if (isEmpty) return;

    final iterator = this.iterator;
    iterator.moveNext();
    yield iterator.current;
    while (iterator.moveNext()) {
      yield putBetween;
      yield iterator.current;
    }
  }

  Iterable<Widget> spaceBetween(double space) => putBetween(SizedBox.square(dimension: space));
}

extension WidgetWithFlexIterableExtension<T extends Widget> on Iterable<(int, T)> {
  List<Widget> mapExpandedPutBetween(Widget putBetween) =>
      map<Widget>((e) => e.$1 == 0 ? e.$2 : Expanded(flex: e.$1, child: e.$2)).toList()..putBetweenEach(putBetween);

  List<Widget> mapExpandedSpaceBetween(double space) => mapExpandedPutBetween(SizedBox(height: space, width: space));
}
