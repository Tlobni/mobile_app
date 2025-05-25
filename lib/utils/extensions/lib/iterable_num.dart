extension DoubleIterable on Iterable<double?> {
  double sum() => isEmpty ? 0.0 : reduce((r, e) => ((r ?? 0) + (e ?? 0))) ?? 0;
}

extension IntIterable on Iterable<int?> {
  int sum() => isEmpty ? 0 : (reduce((r, e) => ((r ?? 0) + (e ?? 0))) ?? 0);
}
