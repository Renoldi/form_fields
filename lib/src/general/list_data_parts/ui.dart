part of '../list_data.dart';

extension _ListDataUiX<T> on _ListDataComponentState<T> {
  /// Sort menu shown above the list. Picking a field sorts by it ascending;
  /// picking the active field again flips the direction.
  Widget sortBar() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final value = _controller.value;
    final active = _controller.activeSortField;
    final label = FormFieldsLocalizations.of(context).sort;
    final arrow = value.sortAscending
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final isActive = active != null;
    final accent = isActive ? scheme.primary : scheme.onSurfaceVariant;
    final radius = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: PopupMenuButton<String>(
          tooltip: label,
          position: PopupMenuPosition.under,
          offset: const Offset(0, 6),
          elevation: 3,
          shadowColor: scheme.shadow.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          borderRadius: radius,
          onSelected: (key) {
            final current = _controller.value;
            // Picking the active field again flips the direction.
            final ascending = key == current.sortKey
                ? !current.sortAscending
                : true;
            _controller.sortBy(key, ascending: ascending);
          },
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              enabled: false,
              height: 36,
              child: Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const PopupMenuDivider(height: 1),
            for (final field in value.sortFields)
              PopupMenuItem<String>(
                value: field.key,
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: field.key == value.sortKey
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: scheme.primary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        field.label,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: field.key == value.sortKey
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (field.key == value.sortKey)
                      Icon(arrow, size: 16, color: scheme.primary),
                  ],
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? scheme.primary.withValues(alpha: 0.08)
                  : scheme.surface,
              borderRadius: radius,
              border: Border.all(
                color: isActive
                    ? scheme.primary.withValues(alpha: 0.35)
                    : scheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_vert_rounded, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  active?.label ?? label,
                  style: textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  Icon(arrow, size: 14, color: accent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
