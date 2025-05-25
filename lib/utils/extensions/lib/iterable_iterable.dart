extension IterableIterableExtension<T> on Iterable<Iterable<T>> {
  List<T> reduceToSingle() => reduceToSingleIterable().toList();

  Iterable<T> reduceToSingleIterable() sync* {
    for (var e in this) {
      yield* e;
    }
  }
}
