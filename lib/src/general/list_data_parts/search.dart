part of '../list_data.dart';

extension _ListDataSearchX<T> on _ListDataComponentState<T> {
  /// Copies the widget's callbacks onto the controller's value. Runs at startup
  /// and whenever the widget is rebuilt with different callbacks, so a parent
  /// that passes a new data source is not ignored.
  void _syncCallbacks() {
    final value = _controller.value;
    value.dataSource = widget.dataSource;
    value.onDataReceived = widget.onDataReceived;
    value.onSelected = widget.onSelected;
    value.onUpdated = widget.onUpdated;
    value.sortFields = widget.sortFields;
  }

  void _attachSearchListener(TextEditingController? c) {
    if (c == null) return;
    _searchListener = () {
      if (mounted) _applyStateChange(() {});
    };
    c.addListener(_searchListener!);
    _attachedSearch = c;
  }

  void _detachSearchListener(TextEditingController? c) {
    if (c == null || _searchListener == null) return;
    try {
      c.removeListener(_searchListener!);
    } catch (_) {}
    _searchListener = null;
    _attachedSearch = null;
  }

  Future<void> _doSearch() async {
    try {
      await _controller.refresh();
    } catch (_) {}
  }
}
