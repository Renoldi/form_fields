import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:form_fields/form_fields.dart';
import 'package:skeleton_text/skeleton_text.dart';

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

  /// When true, the default empty-state text is shown below the inbox icon.
  /// Defaults to `false` to keep an icon-only empty state.
  final bool showEmptyText;

  /// When true the search icon is shown inside the input field. When false
  /// a separate search button is shown to the right of the input.
  final bool searchIconInside;

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
    this.searchBackgroundColor,
    this.searchIconInside = true,
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
  @override
  void initState() {
    widget.controller?.value.dataSource = widget.dataSource;
    widget.controller?.value.onDataReceived = widget.onDataReceived;
    widget.controller?.value.onSelected = widget.onSelected;
    widget.controller?.value.onUpdated = widget.onUpdated;
    super.initState();

    // Defer any refresh or state change until after the first frame to avoid
    // calling notifyListeners()/setState() during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoLoad == true) {
        widget.controller?.refresh();
      } else {
        // If autoLoad is disabled, don't show the initial loading skeleton.
        // Switch to `loaded` so the empty view is shown and its controls can
        // trigger loading later.
        if (widget.controller?.value.state ==
            ListDataComponentState.firstLoad) {
          widget.controller?.value.state = ListDataComponentState.loaded;
          widget.controller?.commit();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: ValueListenableBuilder<ListDataComponentValue<T>>(
        valueListenable: widget.controller!,
        builder: (BuildContext context, value, Widget? child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.header != null ? widget.header! : const SizedBox(),
              const SizedBox(),
              // Toolbar area: show search box, extra toolbar, or both.
              widget.showSearchBox ? searchBox() : const SizedBox(),
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

  Widget searchBox() {
    final hasText =
        (widget.controller?.value.searchController.text ?? '').isNotEmpty;

    final Color bgColor = widget.searchBackgroundColor ?? Colors.white;
    final Color iconColor = Theme.of(context).colorScheme.primary;
    final Widget prefixIconWidget =
        widget.searchIcon ?? Icon(Icons.search, color: iconColor);
    // For the external button prefer a neutral icon so the button's
    // foreground color (IconTheme) can paint it correctly.
    final Widget buttonIconWidget =
        widget.searchIcon ?? const Icon(Icons.search);

    final inputDec = InputDecoration(
      prefixIcon: widget.searchIconInside ? prefixIconWidget : null,
      suffixIcon: hasText
          ? IconButton(
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              iconSize: 20,
              splashRadius: 20,
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                try {
                  widget.controller?.value.searchController.clear();
                } catch (_) {}
                widget.controller?.refresh();
              },
            )
          : null,
      filled: true,
      fillColor: bgColor,
      hintText:
          widget.searchHint ?? FormFieldsLocalizations.of(context).searchHint,
      hintStyle: widget.searchStyle ?? Theme.of(context).textTheme.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withAlpha((0.12 * 255).round()),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.25,
        ),
      ),
    );

    return Container(
      color: bgColor,
      height: kFieldHeightMedium + 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: widget.searchIconInside
          ? FormFields<String>(
              label: widget.searchHint ??
                  FormFieldsLocalizations.of(context).searchHint,
              labelPosition: LabelPosition.none,
              currentValue:
                  widget.controller?.value.searchController.text ?? '',
              onChanged: (val) {
                final sanitized = val.replaceAll(RegExp("[',\\\"]"), '');
                try {
                  widget.controller?.value.searchController.text = sanitized;
                } catch (_) {}
                if (widget.autoSearch == true) widget.controller?.refresh();
              },
              inputDecoration: inputDec,
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: kFieldHeightMedium + 12,
                    child: FormFields<String>(
                      label: widget.searchHint ??
                          FormFieldsLocalizations.of(context).searchHint,
                      labelPosition: LabelPosition.none,
                      currentValue:
                          widget.controller?.value.searchController.text ?? '',
                      onChanged: (val) {
                        final sanitized =
                            val.replaceAll(RegExp("[',\\\"]"), '');
                        try {
                          widget.controller?.value.searchController.text =
                              sanitized;
                        } catch (_) {}
                        if (widget.autoSearch == true) {
                          widget.controller?.refresh();
                        }
                      },
                      inputDecoration: inputDec,
                    ),
                  ),
                ),
                AppButton(
                  withLayout: true,
                  useSafeArea: false,
                  type: AppButtonType.filled,
                  size: AppSize.medium,
                  customHeight: kFieldHeightMedium + 12,
                  customIconSize: 20,
                  customHorizontalPadding: 12,
                  icon: buttonIconWidget,
                  onPressed: () {
                    try {
                      widget.controller?.refresh();
                    } catch (_) {}
                  },
                ),
              ],
            ),
    );
  }

  Widget childBuilder() {
    Future<void> onRefreshHandler() async {
      try {
        await widget.controller?.refresh();
      } catch (_) {}
    }

    switch (widget.controller?.value.state) {
      case ListDataComponentState.firstLoad:
        return RefreshIndicator(
          onRefresh: onRefreshHandler,
          color: widget.refreshColor ?? Theme.of(context).colorScheme.primary,
          backgroundColor: widget.refreshBackgroundColor ??
              Theme.of(context).scaffoldBackgroundColor,
          displacement: widget.refreshDisplacement ?? 40.0,
          edgeOffset: widget.refreshEdgeOffset ?? 0.0,
          child: CustomScrollView(
            controller: widget.controller?.value.scrollController,
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
          backgroundColor: widget.refreshBackgroundColor ??
              Theme.of(context).scaffoldBackgroundColor,
          displacement: widget.refreshDisplacement ?? 40.0,
          edgeOffset: widget.refreshEdgeOffset ?? 0.0,
          child: CustomScrollView(
            controller: widget.controller?.value.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(hasScrollBody: false, child: errorLoaded()),
            ],
          ),
        );
      default:
        final hasData = (widget.controller?.value.data.length ?? 0) > 0 ||
            (widget.controller?.value.state == ListDataComponentState.loading);
        Widget content;
        if (hasData) {
          content = listModeBuilder();
        } else {
          content = CustomScrollView(
            controller: widget.controller?.value.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(hasScrollBody: false, child: emptyData()),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: onRefreshHandler,
          color: widget.refreshColor ?? Theme.of(context).colorScheme.primary,
          backgroundColor: widget.refreshBackgroundColor ??
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
    List<T> data = List.from(widget.controller?.value.data ?? []);
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        controller: widget.controller?.value.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Column(
              children: List.generate(
                (data.length) +
                    (widget.controller?.value.state ==
                            ListDataComponentState.loading
                        ? widget.loaderCount!
                        : 0),
                (index) {
                  if (widget.itemBuilder != null) {
                    if (index < (data.length)) {
                      return GestureDetector(
                        onTap: () {
                          widget.controller?.value.selected = data[index];
                          widget.controller?.commit();
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
                        widget.controller?.getOther();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(widget.showMoreText ??
                              FormFieldsLocalizations.of(context).showMore),
                          const Icon(Icons.arrow_downward, size: 15),
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
    List<T> data = List.from(widget.controller?.value.data ?? []);
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      child: NotificationListener(
        onNotification: (n) {
          if (n is ScrollEndNotification) {
            var current =
                widget.controller?.value.scrollController.position.pixels;
            var min = widget
                .controller?.value.scrollController.position.minScrollExtent;
            var max = widget
                .controller?.value.scrollController.position.maxScrollExtent;
            if (widget.controller?.value.scrollController.position
                        .userScrollDirection ==
                    ScrollDirection.forward &&
                ((current ?? 0) <=
                    (min ?? 0 + widget.autoRefreshTopThreshold))) {
              if (widget.enableAutoRefreshOnTop == true) {
                widget.controller?.refresh();
              }
            } else if (widget.controller?.value.scrollController.position
                        .userScrollDirection ==
                    ScrollDirection.reverse &&
                ((current ?? 0) >= (max ?? 0))) {
              if (widget.enableGetMore == true) widget.controller?.getOther();
            }
          }
          return true;
        },
        child: SingleChildScrollView(
          controller: widget.controller?.value.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Wrap(
            children: List.generate(
              (data.length) +
                  (widget.controller?.value.state ==
                          ListDataComponentState.loading
                      ? widget.loaderCount!
                      : 0),
              (index) {
                if (widget.itemBuilder != null) {
                  if (index < (data.length)) {
                    return GestureDetector(
                      onTap: () {
                        widget.controller?.value.selected = data[index];
                        widget.controller?.commit();
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
    List<T> data = List.from(widget.controller?.value.data ?? []);
    return NotificationListener(
      onNotification: (n) {
        if (n is ScrollEndNotification) {
          var current =
              widget.controller?.value.scrollController.position.pixels;
          var min = widget
              .controller?.value.scrollController.position.minScrollExtent;
          var max = widget
              .controller?.value.scrollController.position.maxScrollExtent;
          if (widget.controller?.value.scrollController.position
                      .userScrollDirection ==
                  ScrollDirection.forward &&
              ((current ?? 0) <= (min ?? 0 + widget.autoRefreshTopThreshold))) {
            if (widget.enableAutoRefreshOnTop == true) {
              widget.controller?.refresh();
            }
          } else if (widget.controller?.value.scrollController.position
                      .userScrollDirection ==
                  ScrollDirection.reverse &&
              ((current ?? 0) >= (max ?? 0))) {
            if (widget.enableGetMore == true) widget.controller?.getOther();
          }
        }
        return true;
      },
      child: ListView(
        controller: widget.controller?.value.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: List.generate(
          (data.length) +
              (widget.controller?.value.state == ListDataComponentState.loading
                  ? widget.loaderCount!
                  : 0),
          (index) {
            if (widget.itemBuilder != null) {
              if (index < (data.length)) {
                return GestureDetector(
                  onTap: () {
                    widget.controller?.value.selected = data[index];
                    widget.controller?.commit();
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
      index == (widget.controller?.value.data.length ?? 0) - 1
          ? draggable(data, index + 1)
          : const SizedBox(),
    ];

    return Container(color: Colors.transparent, child: Column(children: item));
  }

  Widget draggable(T? data, int index) {
    return DragTarget<Object>(
      builder: (c, d, w) {
        return Container(
          height: widget.controller?.value.droppedItem != null ? null : 1,
          width: double.infinity,
          color: Colors.transparent,
          child: (widget.controller?.value.droppedItem != null &&
                  widget.controller?.value.droppedIndexTarget == index &&
                  widget.controller?.value.droppedItem != data)
              ? widget.itemBuilder!(
                  widget.controller?.value.droppedItem,
                  -1,
                )
              : const SizedBox(),
        );
      },
      onMove: (object) {
        if (object.data is T) {
          if (widget.controller?.value.droppedItem == (object.data as T)) {
            return;
          }
          widget.controller?.value.droppedItem = (object.data as T);
          widget.controller?.value.droppedIndexTarget = index;
          widget.controller?.commit();
        }
      },
      onLeave: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
      },
      onWillAcceptWithDetails: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
        if (widget.onWillReceiveDropedData != null) {
          return widget.onWillReceiveDropedData!((object as T), index);
        } else {
          return true;
        }
      },
      onAcceptWithDetails: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
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
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              border: Border.all(color: Colors.black),
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
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 10),
          !(widget.controller?.value.errorMessage ?? "").contains("<div")
              ? Text(
                  widget.controller?.value.errorMessage ?? "Error",
                  textAlign: TextAlign.center,
                )
              : Container(
                  height: 300,
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    child: HtmlWidget(
                      widget.controller?.value.errorMessage ?? "",
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget emptyData() {
    return DragTarget<Object>(
      builder: (c, lo, ld) {
        if (widget.controller?.value.droppedItem != null) {
          return widget.itemBuilder!(widget.controller?.value.droppedItem, -1);
        } else {
          if (widget.controller?.value.droppedItem != null) {
            return widget.itemBuilder!(
              widget.controller?.value.droppedItem,
              -1,
            );
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
                            color: Theme.of(context)
                                .colorScheme
                                .primary
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
                              widget.controller?.refresh();
                            } catch (_) {}
                          },
                          icon: Icon(
                            Icons.refresh,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: widget.refreshIntructionText ??
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
          if (widget.controller?.value.droppedItem == (object.data as T)) {
            return;
          }
          widget.controller?.value.droppedItem = (object.data as T);
          widget.controller?.commit();
        }
      },
      onLeave: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
      },
      onWillAcceptWithDetails: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
        if (widget.onWillReceiveDropedData != null) {
          return widget.onWillReceiveDropedData!((object as T), 0);
        } else {
          return true;
        }
      },
      onAcceptWithDetails: (object) {
        widget.controller?.value.droppedItem = null;
        widget.controller?.commit();
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

  void addAll(List<T> datas) {
    value.data.addAll(datas);
    commit();
  }

  Future<void> refresh({int? refreshDelayed}) {
    debugPrint('ListDataComponentController.refresh: start');
    value.state = ListDataComponentState.loading;
    value.data = [];
    commit();
    if (value.dataSource == null) {
      debugPrint('ListDataComponentController.refresh: no dataSource');
      value.state = ListDataComponentState.loaded;
      commit();
      return Future.value();
    }
    debugPrint('ListDataComponentController.refresh: calling dataSource...');
    return Future.delayed(
      Duration(seconds: refreshDelayed ?? value.refreshDelayed),
    ).then((_) async {
      try {
        final datas = await value.dataSource!(0, value.searchController.text);
        debugPrint(
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
        debugPrint('ListDataComponentController.refresh: error: $onError');
        value.state = ListDataComponentState.errorLoaded;
        final mapped = AppDialogService.defaultErrorMapper(onError);
        value.errorMessage = mapped.message;
        commit();
      }
    });
  }

  void clear() {
    value.data = [];
    commit();
  }

  Future<void> getOther() async {
    double latPosition = 0;
    try {
      latPosition = value.scrollController.position.pixels;
    } catch (e) {
      debugPrint("");
    }
    value.state = ListDataComponentState.loading;
    commit();
    if (value.dataSource == null) {
      value.state = ListDataComponentState.loaded;
      value.selected ??= value.data.first;
      commit();
      return;
    }
    try {
      debugPrint(
        'ListDataComponentController.getOther: calling dataSource at offset $total',
      );
      final datas = await value.dataSource!(total, value.searchController.text);
      debugPrint(
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
        debugPrint("");
      }
    } catch (onError) {
      debugPrint('ListDataComponentController.getOther: error: $onError');
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
          debugPrint('ListDataComponentController.onSelected error: $e');
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
        debugPrint('ListDataComponentController.notifyListeners error: $e');
      }
      if (value.updateWhenEmpty == true || value.data.isNotEmpty) {
        try {
          value.onUpdated?.call();
        } catch (e) {
          debugPrint('ListDataComponentController.onUpdated error: $e');
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
