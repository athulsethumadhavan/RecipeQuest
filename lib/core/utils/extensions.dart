extension StringExtension on String {
  String toTitleCase() {
    return split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }
}

extension ListExtension<T> on List<T> {
  List<T> safeSublist(int start, [int? end]) {
    final safeEnd = end == null
        ? length
        : end > length
            ? length
            : end;
    final safeStart = start > length ? length : start;
    return sublist(safeStart, safeEnd);
  }
}
