/// {@category Extension}
/// Extension of [Iterable] :
///
/// - [firstWhereOrNull] : Return the first element that satisfies a predicate, else return a null value.
///
extension IterableUtils<T> on Iterable<T> {
  /// Return the first element that satisfies a predicate, else return a null value.
  ///
  /// [Function] predicate: Function to test each element for a condition.
  ///
  T? firstWhereOrNull(bool Function(T) predicate) {
    for (T element in this) {
      if (predicate(element)) {
        return element;
      }
    }
    return null;
  }

  T? mostRecentByDate(DateTime Function(T) getDate) {
    T? mostRecent;
    DateTime? latestDate;
    for (T element in this) {
      final date = getDate(element);
      if (latestDate == null || date.isAfter(latestDate)) {
        mostRecent = element;
        latestDate = date;
      }
    }
    return mostRecent;
  }

  T? oldestByDate(DateTime Function(T) getDate) {
    T? mostOld;
    DateTime? oldestDate;
    for (T element in this) {
      final date = getDate(element);
      if (oldestDate == null || date.isBefore(oldestDate)) {
        mostOld = element;
        oldestDate = date;
      }
    }
    return mostOld;
  }

  /// Return the last element that satisfies a predicate, else return a null value.
  ///
  /// [Function] predicate: Function to test each element for a condition.
  ///
  T? lastWhereOrNull(bool Function(T) predicate) {
    final val = where((element) => predicate(element));
    return val.isNotEmpty ? val.last : null;
  }
}

extension ListUtils<U> on List<U> {
  bool doesNotContain(U element) => !contains(element);
}

abstract class ListUtilsFunctions {
  static List<T> removeFromList<T>(
    List<T> originalList,
    List<T> elementsToRemove,
    bool Function(T element, T elementToRemove) compareFunction,
  ) {
    if (originalList.isEmpty) {
      return [];
    }
    if (elementsToRemove.isEmpty) {
      return originalList;
    }
    // Filter the original list to remove elements that match any in elementsToRemove
    return originalList
        .where((element) => !elementsToRemove.any(
            (elementToRemove) => compareFunction(element, elementToRemove)))
        .toList();
  }
}
