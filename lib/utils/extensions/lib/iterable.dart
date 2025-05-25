extension IterableExtension<T> on Iterable<T> {
  T? get onlyOrNull {
    if (length == 1) return first;
    return null;
  }

  bool all(bool Function(T value) test) {
    return !any((e) => !test(e));
  }

  bool containsWhere(bool Function(T t) test) {
    for (T t in this) {
      if (test(t)) return true;
    }
    return false;
  }

  T? directlyAfterOrNull(T? t) {
    final iterator = this.iterator;
    while (iterator.moveNext()) {
      if (iterator.current != t) continue;
      if (!iterator.moveNext()) continue;
      return iterator.current;
    }
    return null;
  }

  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  Map<G, List<T>> group<G>(G Function(T t) groupExtractor) {
    Map<G, List<T>> result = {};
    for (var t in this) {
      final group = groupExtractor(t);
      result[group] ??= [];
      result[group]!.add(t);
    }
    return result;
  }

  Iterable<O> mapIfElse<O>(bool condition, O Function(T input) mapper, O Function(T input) elseMapper) {
    return map(condition ? mapper : elseMapper);
  }

  Iterable<O> mapIndexed<O>(O Function(int index, T e) mapper) sync* {
    final iterator = this.iterator;
    for (int i = 0; i < length; i++) {
      iterator.moveNext();
      yield mapper(i, iterator.current);
    }
  }

  Iterable<O> mapWhereNotNull<O>(O? Function(T t) mapper) sync* {
    for (var t in this) {
      final res = mapper(t);
      if (res != null) yield res;
    }
  }

  bool none(bool Function(T t) test) => !any(test);

  bool notContains(T t) {
    return !contains(t);
  }

  T? reduceOrNull(T Function(T value, T element) reducer) {
    if (isEmpty) return null;
    return reduce(reducer);
  }

  Iterable<T> skipIf(bool skip, int count) => skip ? this.skip(count) : this;

  List<T> sort([int Function(T a, T b)? compare]) {
    return toList()..sort(compare);
  }
}

extension IterableNullableExtension<T> on Iterable<T?> {
  Iterable<T> whereNotNull() sync* {
    for (var e in this) {
      if (e == null) continue;
      yield e;
    }
  }
}
