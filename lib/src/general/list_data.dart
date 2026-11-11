import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:form_fields/form_fields.dart';
import 'package:skeleton_text/skeleton_text.dart';
import 'package:form_fields/src/utils/debug_log.dart';

class ListDataComponent<T> extends StatefulWidget {
  final ListDataComponentController<T>? controller;
  final WidgetFromDataBuilder2Param<T?, int>? itemBuilder;
  final Widget? emptyWidget;
  final FutureObjectBuilderWith2Param<List<T>, int, String?>? dataSource;
  final ValueChanged2Param<List<T>, String?>? onDataReceived;
  final bool showSearchBox;
  final Widget? extraToolbar;
  final String? searchHint;
  final ListDataComponentMode listViewMode;
  final Widget? header;
  final ValueChanged<T?>? onSelected;
  final bool enableGetMore;
  final ObjectBuilderWith2Param<bool, T, int>? onWillReceiveDropedData;
  final ValueChanged2Param<T, int>? onReceiveDropedData;
  final WidgetFromDataBuilder2Param<T?, int>? dragFeedbackBuilder;
  final ObjectBuilderWith2Param<Object, T?, int>? dragDataBuilder;
  final bool enableDrag;
  final Widget? loaderWidget;
  final int? loaderCount;
  final bool autoSearch;
  final TextStyle? searchStyle;
  final Widget? searchIcon;

  /// Minimum characters required to perform a search. Default: 3
  final int minSearchChars;

  /// When true the search icon is shown inside the input field. When false
  /// a separate search button is shown to the right of the input.
  final bool searchIconInside;

  /// When true, the default empty-state text is shown below the inbox icon.
  /// Defaults to `false` to keep an icon-only empty state.
  final bool showEmptyText;

  /// When true the search icon is shown inside the input field. When false
  /// a separate search button is shown to the right of the input.

  /// Optional override for the search box background color. If provided,
  /// this color will be used directly.
  final Color? searchBackgroundColor;

  /// Optional flag removed: use `searchBackgroundColor` (defaults to white).
  final String? showMoreText;
  final String? emptyDataText;
  final String? refreshIntructionText;
  final Color? refreshColor;
  final Color? refreshBackgroundColor;
  final double? refreshDisplacement;
  final double? refreshEdgeOffset;
  final TextStyle? emptyDataTextStyle;
  final VoidCallback? onUpdated;
  final bool autoLoad;
  final bool enableAutoRefreshOnTop;
  final double autoRefreshTopThreshold;

  const ListDataComponent({
    super.key,
    this.controller,
    this.itemBuilder,
    this.dataSource,
    this.onDataReceived,
    this.showSearchBox = false,
    this.extraToolbar,
    this.searchHint,
    this.listViewMode = ListDataComponentMode.listView,
    this.header,
    this.onSelected,
    this.emptyWidget,
    this.enableGetMore = true,
    this.onReceiveDropedData,
    this.onWillReceiveDropedData,
    this.dragFeedbackBuilder,
    this.dragDataBuilder,
    this.enableDrag = false,
    this.loaderWidget,
    this.loaderCount = 5,
    this.autoSearch = true,
    this.autoLoad = true,
    this.enableAutoRefreshOnTop = true,
    this.autoRefreshTopThreshold = 200.0,
    this.refreshColor,
    this.refreshBackgroundColor,
    this.refreshDisplacement,
    this.refreshEdgeOffset,
    this.searchStyle,
    this.searchIcon,
    this.minSearchChars = 3,
    this.searchIconInside = false,
    this.searchBackgroundColor,
    this.showEmptyText = false,
    this.showMoreText,
    this.emptyDataText,
    this.emptyDataTextStyle,
    this.onUpdated,
    this.refreshIntructionText,
  });

  @override
  State<ListDataComponent<T>> createState() => _ListDataComponentState<T>();
}

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

  /// Copies the widget's callbacks onto the controller's value. Runs at startup
  /// and whenever the widget is rebuilt with different callbacks, so a parent
  /// that passes a new data source is not ignored.
  void _syncCallbacks() {
    final value = _controller.value;
    value.dataSource = widget.dataSource;
    value.onDataReceived = widget.onDataReceived;
    value.onSelected = widget.onSelected;
    value.onUpdated = widget.onUpdated;
  }

  @override
  void initState() {
    _syncCallbacks();
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

  void _attachSearchListener(TextEditingController? c) {
    if (c == null) return;
    _searchListener = () {
      if (mounted) setState(() {});
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

  Future<void> _doSearch() async {
    try {
      await _controller.refresh();
    } catch (_) {}
  }

  Widget searchBoxWithFormFields() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color:
            widget.searchBackgroundColor ??
            Theme.of(
              context,
            ).colorScheme.surface.withAlpha((0.08 * 255).round()),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FormFields<String>(
                onChanged: (v) async {
                  try {
                    final c = _controller.value.searchController;
                    c.text = v;
                    if (widget.searchIconInside == true &&
                        widget.autoSearch == true) {
                      final t = _controller.value.searchController.text;
                      if (t.trim().isEmpty ||
                          t.trim().length >= widget.minSearchChars) {
                        await _doSearch();
                      }
                    }
                  } catch (_) {}
                },
                // Set hintText via inputDecoration to avoid automatic
                // `enterPrefix` being prepended by `FormFields`.
                inputDecoration: InputDecoration(
                  hintText:
                      widget.searchHint ??
                      FormFieldsLocalizations.of(context).searchHint,
                ),
                label:
                    widget.searchHint ??
                    FormFieldsLocalizations.of(context).searchHint,
                labelPosition: LabelPosition.none,
                fieldSize: AppSize.medium,
                currentValue: _controller.value.searchController.text,
                onRemove: () async {
                  try {
                    final c = _controller.value.searchController;
                    c.text = '';
                    final t = _controller.value.searchController.text;
                    if (t.trim().isEmpty ||
                        t.trim().length >= widget.minSearchChars) {
                      await _doSearch();
                    }
                  } catch (_) {}
                },
                suffixIcon: widget.searchIconInside
                    ? (widget.searchIcon ?? const Icon(Icons.search))
                    : null,
                validator: (v) {
                  if (v != null &&
                      v.trim().isNotEmpty &&
                      v.trim().length < widget.minSearchChars) {
                    final raw = FormFieldsLocalizations.of(
                      context,
                    ).get('searchMinChars');
                    final msg = (raw.contains('{n}'))
                        ? raw.replaceAll(
                            '{n}',
                            widget.minSearchChars.toString(),
                          )
                        : raw;
                    if (msg.trim().isEmpty || msg == 'searchMinChars') {
                      return 'Please enter at least ${widget.minSearchChars} characters';
                    }
                    return msg;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            if (!widget.searchIconInside)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: AppButton(
                  onPressed: () async => await _doSearch(),
                  type: AppButtonType.filled,
                  size: AppSize.medium,
                  useSafeArea: false,
                  icon: widget.searchIcon ?? const Icon(Icons.search),
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.primary,
                    ),
                    // fixedSize: WidgetStatePropertyAll(
                    //   Size(kFieldHeightMedium + 5.0, kFieldHeightMedium + 5.0),
                    // ),
                    foregroundColor: WidgetStatePropertyAll(
                      widget.searchStyle?.color ??
                          Theme.of(context).colorScheme.surface,
                    ),
                    iconColor: WidgetStatePropertyAll(
                      widget.searchStyle?.color ??
                          Theme.of(context).colorScheme.surface,
                    ),
                    side: WidgetStatePropertyAll(
                      BorderSide(
                        color:
                            widget.searchStyle?.color ??
                            Theme.of(context).colorScheme.surface,
                        width: 1,
                      ),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget childBuilder() {
    Future<void> onRefreshHandler() async {
      try {
        await _controller.refresh();
      } catch (_) {}
    }

    switch (_controller.value.state) {
      case ListDataComponentState.firstLoad:
        return RefreshIndicator(
          onRefresh: onRefreshHandler,
          color: widget.refreshColor ?? Theme.of(context).colorScheme.primary,
          backgroundColor:
              widget.refreshBackgroundColor ??
              Theme.of(context).scaffoldBackgroundColor,
          displacement: widget.refreshDisplacement ?? 40.0,
          edgeOffset: widget.refreshEdgeOffset ?? 0.0,
          child: CustomScrollView(
            controller: _controller.value.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.loaderCount!, (index) {
                    return loader();
                  }),
                ),
              ),
            ],
          ),
        );
      case ListDataComponentState.errorLoaded:
        return RefreshIndicator(
          onRefresh: onRefreshHandler,
          color: widget.refreshColor ?? Theme.of(context).colorScheme.primary,
          backgroundColor:
              widget.refreshBackgroundColor ??
              Theme.of(context).scaffoldBackgroundColor,
          displacement: widget.refreshDisplacement ?? 40.0,
          edgeOffset: widget.refreshEdgeOffset ?? 0.0,
          child: CustomScrollView(
            controller: _controller.value.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(hasScrollBody: false, child: errorLoaded()),
            ],
          ),
        );
      default:
        final hasData =
            _controller.value.data.isNotEmpty ||
            (_controller.value.state == ListDataComponentState.loading);
        Widget content;
        if (hasData) {
          content = listModeBuilder();
        } else {
          content = CustomScrollView(
            controller: _controller.value.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(hasScrollBody: false, child: emptyData()),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: onRefreshHandler,
          color: widget.refreshColor ?? Theme.of(context).colorScheme.primary,
          backgroundColor:
              widget.refreshBackgroundColor ??
              Theme.of(context).scaffoldBackgroundColor,
          displacement: widget.refreshDisplacement ?? 40.0,
          edgeOffset: widget.refreshEdgeOffset ?? 0.0,
          child: content,
        );
    }
  }

  Widget listModeBuilder() {
    switch (widget.listViewMode) {
      case ListDataComponentMode.column:
        return columnMode();
      case ListDataComponentMode.tile:
        return tilewMode();
      default:
        return listMode();
    }
  }

  Widget columnMode() {
    List<T> data = List.from(_controller.value.data);
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        controller: _controller.value.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Column(
              children: List.generate(
                (data.length) +
                    (_controller.value.state == ListDataComponentState.loading
                        ? widget.loaderCount!
                        : 0),
                (index) {
                  if (widget.itemBuilder != null) {
                    if (index < (data.length)) {
                      return GestureDetector(
                        onTap: () {
                          _controller.value.selected = data[index];
                          _controller.commit();
                          if (widget.onSelected != null) {
                            widget.onSelected!(data[index]);
                          }
                        },
                        child: item(data[index], index),
                      );
                    } else {
                      return loader();
                    }
                  } else {
                    return emptyItem();
                  }
                },
              ),
            ),
            widget.enableGetMore != true
                ? const SizedBox()
                : Container(
                    margin: const EdgeInsets.only(top: 5),
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        _controller.getOther();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.showMoreText ??
                                FormFieldsLocalizations.of(context).showMore,
                          ),
                          Icon(
                            Icons.arrow_downward,
                            size: 15,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget tilewMode() {
    List<T> data = List.from(_controller.value.data);
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      child: NotificationListener(
        onNotification: (n) {
          if (n is ScrollEndNotification) {
            var current = _controller.value.scrollController.position.pixels;
            var min =
                _controller.value.scrollController.position.minScrollExtent;
            var max =
                _controller.value.scrollController.position.maxScrollExtent;
            if (_controller
                        .value
                        .scrollController
                        .position
                        .userScrollDirection ==
                    ScrollDirection.forward &&
                (current <= (min + widget.autoRefreshTopThreshold))) {
              if (widget.enableAutoRefreshOnTop == true) {
                _controller.refresh();
              }
            } else if (_controller
                        .value
                        .scrollController
                        .position
                        .userScrollDirection ==
                    ScrollDirection.reverse &&
                (current >= max)) {
              if (widget.enableGetMore == true) _controller.getOther();
            }
          }
          return true;
        },
        child: SingleChildScrollView(
          controller: _controller.value.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Wrap(
            children: List.generate(
              (data.length) +
                  (_controller.value.state == ListDataComponentState.loading
                      ? widget.loaderCount!
                      : 0),
              (index) {
                if (widget.itemBuilder != null) {
                  if (index < (data.length)) {
                    return GestureDetector(
                      onTap: () {
                        _controller.value.selected = data[index];
                        _controller.commit();
                        if (widget.onSelected != null) {
                          widget.onSelected!(data[index]);
                        }
                      },
                      child: IntrinsicWidth(
                        child: Container(child: item(data[index], index)),
                      ),
                    );
                  } else {
                    return loader();
                  }
                } else {
                  return emptyItem();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget listMode() {
    List<T> data = List.from(_controller.value.data);
    return NotificationListener(
      onNotification: (n) {
        if (n is ScrollEndNotification) {
          var current = _controller.value.scrollController.position.pixels;
          var min = _controller.value.scrollController.position.minScrollExtent;
          var max = _controller.value.scrollController.position.maxScrollExtent;
          if (_controller.value.scrollController.position.userScrollDirection ==
                  ScrollDirection.forward &&
              (current <= (min + widget.autoRefreshTopThreshold))) {
            if (widget.enableAutoRefreshOnTop == true) {
              _controller.refresh();
            }
          } else if (_controller
                      .value
                      .scrollController
                      .position
                      .userScrollDirection ==
                  ScrollDirection.reverse &&
              (current >= max)) {
            if (widget.enableGetMore == true) _controller.getOther();
          }
        }
        return true;
      },
      child: ListView(
        controller: _controller.value.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: List.generate(
          (data.length) +
              (_controller.value.state == ListDataComponentState.loading
                  ? widget.loaderCount!
                  : 0),
          (index) {
            if (widget.itemBuilder != null) {
              if (index < (data.length)) {
                return GestureDetector(
                  onTap: () {
                    _controller.value.selected = data[index];
                    _controller.commit();
                    if (widget.onSelected != null) {
                      widget.onSelected!(data[index]);
                    }
                  },
                  child: item(data[index], index),
                );
              } else {
                return loader();
              }
            } else {
              return emptyItem();
            }
          },
        ),
      ),
    );
  }

  Widget item(T? data, int index) {
    List<Widget> item = [
      draggable(data, index),
      Container(
        color: Colors.transparent,
        child: widget.enableDrag
            ? LongPressDraggable<Object>(
                dragAnchorStrategy: (drg, obj, offset) {
                  return const Offset(1, 1);
                },
                feedback: Material(child: dragFeedBack(data, index)),
                data: widget.dragDataBuilder != null
                    ? widget.dragDataBuilder!(data, index)
                    : data,
                child: widget.itemBuilder!(data, index),
              )
            : widget.itemBuilder!(data, index),
      ),
      index == (_controller.value.data.length) - 1
          ? draggable(data, index + 1)
          : const SizedBox(),
    ];

    return Container(
      color: Colors.transparent,
      child: Column(children: item),
    );
  }

  Widget draggable(T? data, int index) {
    return DragTarget<Object>(
      builder: (c, d, w) {
        return Container(
          height: _controller.value.droppedItem != null ? null : 1,
          width: double.infinity,
          color: Colors.transparent,
          child:
              (_controller.value.droppedItem != null &&
                  _controller.value.droppedIndexTarget == index &&
                  _controller.value.droppedItem != data)
              ? widget.itemBuilder!(_controller.value.droppedItem, -1)
              : const SizedBox(),
        );
      },
      onMove: (object) {
        if (object.data is T) {
          if (_controller.value.droppedItem == (object.data as T)) {
            return;
          }
          _controller.value.droppedItem = (object.data as T);
          _controller.value.droppedIndexTarget = index;
          _controller.commit();
        }
      },
      onLeave: (object) {
        _controller.value.droppedItem = null;
        _controller.commit();
      },
      onWillAcceptWithDetails: (object) {
        _controller.value.droppedItem = null;
        _controller.commit();
        if (widget.onWillReceiveDropedData != null) {
          return widget.onWillReceiveDropedData!((object as T), index);
        } else {
          return true;
        }
      },
      onAcceptWithDetails: (object) {
        _controller.value.droppedItem = null;
        _controller.commit();
        if (widget.onReceiveDropedData != null) {
          widget.onReceiveDropedData!((object as T), index);
        }
      },
    );
  }

  Widget dragFeedBack(T? data, int index) {
    return widget.dragFeedbackBuilder != null
        ? widget.dragFeedbackBuilder!(data, index)
        : Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(31),
              ),
            ),
            child: Center(child: FittedBox(child: Text("$index"))),
          );
  }

  Widget loader() {
    return widget.loaderWidget != null
        ? widget.loaderWidget!
        : SkeletonAnimation(
            shimmerColor: Colors.grey.shade300,
            child: widget.itemBuilder != null
                ? widget.itemBuilder!(null, 0)
                : emptyItem(),
          );
  }

  Widget emptyItem() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 5, top: 5),
      color: Colors.transparent,
    );
  }

  Widget errorLoaded() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 50,
          ),
          const SizedBox(height: 10),
          !(_controller.value.errorMessage ?? "").contains("<div")
              ? Text(
                  _controller.value.errorMessage ?? "Error",
                  textAlign: TextAlign.center,
                )
              : Container(
                  height: 300,
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    child: HtmlWidget(_controller.value.errorMessage ?? ""),
                  ),
                ),
        ],
      ),
    );
  }

  Widget emptyData() {
    return DragTarget<Object>(
      builder: (c, lo, ld) {
        if (_controller.value.droppedItem != null) {
          return widget.itemBuilder!(_controller.value.droppedItem, -1);
        } else {
          if (_controller.value.droppedItem != null) {
            return widget.itemBuilder!(_controller.value.droppedItem, -1);
          } else {
            // Default empty view: allow caller override via `emptyWidget`.
            // Otherwise show a friendly, localized empty state with action.
            return widget.emptyWidget ??
                Container(
                  width: double.infinity,
                  color: Colors.transparent,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary
                                .withAlpha((0.08 * 255).round()),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inbox,
                            color: Theme.of(context).colorScheme.primary,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 16),
                        IconButton(
                          onPressed: () {
                            try {
                              _controller.refresh();
                            } catch (_) {}
                          },
                          icon: Icon(
                            Icons.refresh,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip:
                              widget.refreshIntructionText ??
                              FormFieldsLocalizations.of(context).refresh,
                        ),
                      ],
                    ),
                  ),
                );
          }
        }
      },
      onMove: (object) {
        if (object.data is T) {
          if (_controller.value.droppedItem == (object.data as T)) {
            return;
          }
          _controller.value.droppedItem = (object.data as T);
          _controller.commit();
        }
      },
      onLeave: (object) {
        _controller.value.droppedItem = null;
        _controller.commit();
      },
      onWillAcceptWithDetails: (object) {
        _controller.value.droppedItem = null;
        _controller.commit();
        if (widget.onWillReceiveDropedData != null) {
          return widget.onWillReceiveDropedData!((object as T), 0);
        } else {
          return true;
        }
      },
      onAcceptWithDetails: (object) {
        _controller.value.droppedItem = null;
        _controller.commit();
        if (widget.onReceiveDropedData != null) {
          widget.onReceiveDropedData!((object as T), 0);
        }
      },
    );
  }
}

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
    commit();
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
        value.data = (datas);
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
}

enum ListDataComponentState { firstLoad, loading, loaded, errorLoaded }

enum ListDataComponentMode { listView, column, tile }

typedef WidgetFromDataBuilder2Param<T, T2> = Widget Function(T value, T2 index);
typedef FutureObjectBuilderWith2Param<T, T2, T3> = Future<T> Function(T2, T3);
typedef ValueChanged2Param<T, T2> = void Function(T value, T2 value2);
typedef ObjectBuilderWith2Param<T, T1, T2> = T Function(T1, T2);
