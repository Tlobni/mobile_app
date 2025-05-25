import 'dart:async';
import 'dart:math';

extension ListExtension<T> on List<T> {
  Future<void> forEachIndexed(FutureOr<void> Function(int index, T element) callback) async {
    for (int i = 0; i < length; i++) {
      await callback(i, this[i]);
    }
  }

  T? getSafe(int i) {
    if (i < 0 || i >= length) return null;
    return this[i];
  }

  O ifNotEmptyOrElse<O>(O Function(List<T> list) ifNotEmpty, O Function() orElse) {
    if (isEmpty) {
      return orElse();
    }
    return ifNotEmpty(this);
  }

  T max(num Function(T t) evaluate) => maxOrNull(evaluate) ?? (throw Exception("max used on empty list"));

  T? maxOrNull(num Function(T t) evaluate) {
    num max = double.negativeInfinity;
    if (isEmpty) {
      return null;
    }
    T maxT = first;
    for (var t in this) {
      num evaluation = evaluate(t);
      if (evaluation > max) {
        maxT = t;
        max = evaluation;
      }
    }
    return maxT;
  }

  Iterable<T> putAfterEvery(int n, T t, {bool exceptFinal = false}) sync* {
    int left = length;
    while (left > 0) {
      for (int i = 0; i < min(left, n); i++) {
        yield this[i];
      }
      left -= n;
      if (left > 0) yield t;
    }
  }

  List<T> putBetweenEach(T item) {
    if (isEmpty) return this;
    List<T> returnList = [];
    for (int i = 0; i < length - 1; i++) {
      returnList.add(this[i]);
      returnList.add(item);
    }
    returnList.add(last);
    clear();
    addAll(returnList);
    return this;
  }

  T? removeFirstSafe() {
    if (isNotEmpty) {
      return removeAt(0);
    }
    return null;
  }

  bool removeIf(bool condition, T t) {
    if (!condition) return false;
    return remove(t);
  }

  Iterable<T> reversedIf(bool reverse) {
    if (reverse) return reversed;
    return this;
  }

  List<T> safeRange(int range) {
    if (length <= range) {
      return this;
    }
    return getRange(0, range).toList();
  }

  void sortComparing<O>(O Function(T input) extractor, int Function(O a, O b) compare) {
    sort((a, b) => compare(extractor(a), extractor(b)));
  }

  List<List<T?>> split(int childListLength) {
    List<List<T?>> result = [];
    for (int i = 0; i < length; i += childListLength) {
      result.add([]);
      for (var t in sublist(i, min(i + childListLength, length))) {
        result.last.add(t);
      }
    }
    int difference = childListLength - (result.lastOrNull?.length ?? childListLength);

    for (int i = 0; i < difference; i++) {
      result.last.add(null);
    }
    return result;
  }
}
