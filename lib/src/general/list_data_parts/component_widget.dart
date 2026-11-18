part of '../list_data.dart';

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

  /// Fields the loaded result can be sorted by. When empty, no sort menu is
  /// shown and the data keeps the order returned by [dataSource].
  final List<ListDataSortField<T>> sortFields;

  /// Shows the sort menu above the list when true. Defaults to false. The list
  /// can still be sorted with [initialSortKey] or `controller.sortBy`.
  final bool showSortMenu;

  /// Key of the field the list starts sorted by. It is used only the first
  /// time the component is created. Ignored when [sortFields] has no field
  /// with this key.
  final String? initialSortKey;

  /// Direction of the initial sort. Used together with [initialSortKey].
  final bool initialSortAscending;

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
    this.sortFields = const [],
    this.showSortMenu = false,
    this.initialSortKey,
    this.initialSortAscending = true,
  });

  @override
  State<ListDataComponent<T>> createState() => _ListDataComponentState<T>();
}
