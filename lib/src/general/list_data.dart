import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:form_fields/form_fields.dart';
import 'package:skeleton_text/skeleton_text.dart';
import 'package:form_fields/src/utilities/debug_log.dart';
part 'list_data_parts/component_controller.dart';
part 'list_data_parts/component_widget.dart';

part 'list_data_parts/search.dart';
part 'list_data_parts/ui.dart';
part 'list_data_parts/item_views.dart';

class _ListDataComponentState<T> extends State<ListDataComponent<T>> {
  VoidCallback? _searchListener;

  /// The search controller that currently has [_searchListener] attached. It
  /// is tracked directly, because the widget's controller can change.
  TextEditingController? _attachedSearch;

  /// Controller used when the widget was built without one. It belongs to this
  /// state and is disposed with it. Before this, a missing controller crashed
  /// `build`.
  ListDataComponentController<T>? _ownedController;

  ListDataComponentController<T> get _controller {
    final given = widget.controller;
    if (given != null) return given;
    return _ownedController ??= ListDataComponentController<T>();
  }

  @override
  void initState() {
    _syncCallbacks();
    if (widget.initialSortKey != null) {
      _controller.value.sortKey = widget.initialSortKey;
      _controller.value.sortAscending = widget.initialSortAscending;
    }
    super.initState();

    // Listen to search controller text changes to update the clear button state
    _attachSearchListener(_controller.value.searchController);

    // Defer any refresh or state change until after the first frame to avoid
    // calling notifyListeners()/setState() during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoLoad == true) {
        _controller.refresh();
      } else {
        // If autoLoad is disabled, don't show the initial loading skeleton.
        // Switch to `loaded` so the empty view is shown and its controls can
        // trigger loading later.
        if (_controller.value.state == ListDataComponentState.firstLoad) {
          _controller.value.state = ListDataComponentState.loaded;
          _controller.commit();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ListDataComponent<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCallbacks();
    // The controller may have changed (given one, or the owned one). Move the
    // listener to the controller that is in use now.
    final next = _controller.value.searchController;
    if (!identical(next, _attachedSearch)) {
      _detachSearchListener(_attachedSearch);
      _attachSearchListener(next);
    }
  }

  @override
  void dispose() {
    _detachSearchListener(_attachedSearch);
    _ownedController?.dispose();
    super.dispose();
  }

  /// Single entry point for rebuilds requested from the helper extensions in
  /// `*_parts/`. Keeps the protected `setState` call inside this class.
  void _applyStateChange(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: ValueListenableBuilder<ListDataComponentValue<T>>(
        valueListenable: _controller,
        builder: (BuildContext context, value, Widget? child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.header != null ? widget.header! : const SizedBox(),
              // Toolbar area: show search box, extra toolbar, or both.
              widget.showSearchBox
                  ? searchBoxWithFormFields()
                  : const SizedBox(),
              widget.showSortMenu && widget.sortFields.isNotEmpty
                  ? sortBar()
                  : const SizedBox(),
              Container(
                // color: Colors.blue,
                height: 8,
              ),
              [
                    ListDataComponentMode.listView,
                    ListDataComponentMode.tile,
                  ].contains(widget.listViewMode)
                  ? Expanded(child: childBuilder())
                  : childBuilder(),
            ],
          );
        },
      ),
    );
  }
}

class ListDataComponentValue<T> {
  T? droppedItem;
  int? droppedIndexTarget;
  List<T> data = [];
  T? selected;
  ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  int totalAllData = 0;
  ListDataComponentState state = ListDataComponentState.firstLoad;
  FutureObjectBuilderWith2Param<List<T>, int, String?>? dataSource;
  ValueChanged2Param<List<T>, String?>? onDataReceived;
  ValueChanged<T?>? onSelected;
  VoidCallback? onUpdated;
  bool updateWhenEmpty = true;
  String? errorMessage;
  int refreshDelayed = 0;
  List<ListDataSortField<T>> sortFields = [];
  String? sortKey;
  bool sortAscending = true;
}

/// A field the list result can be sorted by. [valueOf] returns the value
/// compared for an item; `null` means the item has no value and sorts last.
class ListDataSortField<T> {
  const ListDataSortField({
    required this.key,
    required this.label,
    required this.valueOf,
  });

  /// Unique id within the component's `sortFields`.
  final String key;

  /// Text shown in the sort menu.
  final String label;

  /// Value compared for an item, e.g. `(item) => item.name.toLowerCase()`.
  final Comparable<dynamic>? Function(T item) valueOf;
}

enum ListDataComponentState { firstLoad, loading, loaded, errorLoaded }

enum ListDataComponentMode { listView, column, tile }

typedef WidgetFromDataBuilder2Param<T, T2> = Widget Function(T value, T2 index);
typedef FutureObjectBuilderWith2Param<T, T2, T3> = Future<T> Function(T2, T3);
typedef ValueChanged2Param<T, T2> = void Function(T value, T2 value2);
typedef ObjectBuilderWith2Param<T, T1, T2> = T Function(T1, T2);
