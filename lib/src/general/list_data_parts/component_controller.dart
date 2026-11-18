part of '../list_data.dart';

class ListDataComponentController<T>
    extends ValueNotifier<ListDataComponentValue<T>> {
  ListDataComponentController({ListDataComponentValue<T>? value})
    : super(value ?? ListDataComponentValue<T>());

  /// Bumped by [refresh] and [clear]. A data request that finishes after a
  /// newer refresh or clear was started belongs to a list that no longer
  /// exists, so its result is dropped instead of overwriting the new one.
  int _generation = 0;

  /// Releases the scroll and search controllers that the current value owns.
  /// Without this, each disposed list controller leaked both objects.
  @override
  void dispose() {
    value.scrollController.dispose();
    value.searchController.dispose();
    super.dispose();
  }

  void addAll(List<T> datas) {
    value.data.addAll(datas);
    _applySort();
    commit();
  }

  /// The sort field in use, or `null` when the data is not sorted.
  ListDataSortField<T>? get activeSortField {
    final key = value.sortKey;
    if (key == null) return null;
    for (final field in value.sortFields) {
      if (field.key == key) return field;
    }
    return null;
  }

  /// Sorts the loaded data by the field with [key] (one of the component's
  /// `sortFields`). Pass `null` to stop sorting; the current order is kept
  /// until the next load. Loaded pages are sorted together, and the sort
  /// carries over to pages loaded later.
  void sortBy(String? key, {bool? ascending}) {
    value.sortKey = key;
    if (ascending != null) value.sortAscending = ascending;
    _applySort();
    commit();
  }

  void _applySort() {
    final field = activeSortField;
    if (field == null) return;
    value.data.sort(_comparatorFor(field));
  }

  /// Returns [items] sorted by the active field as a new list. Returns [items]
  /// unchanged when no field is active.
  List<T> _sortedCopy(List<T> items) {
    final field = activeSortField;
    if (field == null) return items;
    return List<T>.of(items)..sort(_comparatorFor(field));
  }

  /// Items without a value for the field go last in both directions.
  Comparator<T> _comparatorFor(ListDataSortField<T> field) {
    final ascending = value.sortAscending;
    return (a, b) {
      final va = field.valueOf(a);
      final vb = field.valueOf(b);
      if (va == null && vb == null) return 0;
      if (va == null) return 1;
      if (vb == null) return -1;
      final result = va.compareTo(vb);
      return ascending ? result : -result;
    };
  }

  Future<void> refresh({int? refreshDelayed}) {
    debugLog('ListDataComponentController.refresh: start');
    final generation = ++_generation;
    value.state = ListDataComponentState.loading;
    value.data = [];
    commit();
    if (value.dataSource == null) {
      debugLog('ListDataComponentController.refresh: no dataSource');
      value.state = ListDataComponentState.loaded;
      commit();
      return Future.value();
    }
    debugLog('ListDataComponentController.refresh: calling dataSource...');
    return Future.delayed(
      Duration(seconds: refreshDelayed ?? value.refreshDelayed),
    ).then((_) async {
      try {
        final datas = await value.dataSource!(0, value.searchController.text);
        if (generation != _generation) return;
        debugLog(
          'ListDataComponentController.refresh: got ${datas.length} items',
        );
        value.data = _sortedCopy(datas);
        if (value.onDataReceived != null) {
          value.onDataReceived!(datas, value.searchController.text);
        }
        value.state = ListDataComponentState.loaded;
        setSelectedData();
        commit();
      } catch (onError) {
        if (generation != _generation) return;
        debugLog('ListDataComponentController.refresh: error: $onError');
        value.state = ListDataComponentState.errorLoaded;
        final mapped = AppDialogService.defaultErrorMapper(onError);
        value.errorMessage = mapped.message;
        commit();
      }
    });
  }

  void clear() {
    _generation++;
    value.data = [];
    commit();
  }

  Future<void> getOther() async {
    // A page is requested at offset `total`. A second request while one is
    // still running would ask for the same offset and append the page twice,
    // so it is ignored. Refresh and load-more both set the loading state.
    if (value.state == ListDataComponentState.loading) return;

    double latPosition = 0;
    try {
      latPosition = value.scrollController.position.pixels;
    } catch (e) {
      debugLog("");
    }
    value.state = ListDataComponentState.loading;
    commit();
    if (value.dataSource == null) {
      value.state = ListDataComponentState.loaded;
      // Default to the first row when there is one. Empty data has no first row.
      if (value.selected == null && value.data.isNotEmpty) {
        value.selected = value.data.first;
      }
      commit();
      return;
    }
    final generation = _generation;
    try {
      debugLog(
        'ListDataComponentController.getOther: calling dataSource at offset $total',
      );
      final datas = await value.dataSource!(total, value.searchController.text);
      // The list was refreshed or cleared while this page was loading.
      if (generation != _generation) return;
      debugLog(
        'ListDataComponentController.getOther: got ${datas.length} items',
      );
      value.data.addAll(List.from(datas));
      _applySort();
      if (value.onDataReceived != null) {
        value.onDataReceived!(datas, value.searchController.text);
      }
      value.state = ListDataComponentState.loaded;
      setSelectedData();
      commit();
      try {
        value.scrollController.jumpTo(latPosition);
      } catch (e) {
        debugLog("");
      }
    } catch (onError) {
      if (generation != _generation) return;
      debugLog('ListDataComponentController.getOther: error: $onError');
      value.state = ListDataComponentState.errorLoaded;
      final mapped = AppDialogService.defaultErrorMapper(onError);
      value.errorMessage = mapped.message;
      commit();
    }
  }

  void setSelectedData() {
    final previous = value.selected;
    T? newSelected;

    if (value.data.isNotEmpty) {
      // Keep previous selection if it still exists in the new data,
      // otherwise pick the first item.
      if (previous == null || !value.data.contains(previous)) {
        newSelected = value.data.first;
      } else {
        newSelected = previous;
      }
    } else {
      newSelected = null;
    }

    // Only notify if selection actually changed.
    if (previous != newSelected) {
      value.selected = newSelected;
      if (value.onSelected != null) {
        try {
          value.onSelected!(value.selected);
        } catch (e) {
          debugLog('ListDataComponentController.onSelected error: $e');
        }
      }
    }
  }

  int get total {
    return value.data.length;
  }

  void commit() {
    void doNotify() {
      try {
        notifyListeners();
      } catch (e) {
        debugLog('ListDataComponentController.notifyListeners error: $e');
      }
      if (value.updateWhenEmpty == true || value.data.isNotEmpty) {
        try {
          value.onUpdated?.call();
        } catch (e) {
          debugLog('ListDataComponentController.onUpdated error: $e');
        }
      }
    }

    // If we're in the middle of the build phase, defer notifying listeners
    // until after the frame to avoid calling setState() during build.
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      doNotify();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => doNotify());
    }
  }

  void startLoading() {
    value.state = ListDataComponentState.loading;
    commit();
  }

  void stopLoading() {
    value.state = ListDataComponentState.loaded;
    commit();
  }
}
