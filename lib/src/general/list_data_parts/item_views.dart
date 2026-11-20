part of '../list_data.dart';

/// Item, list, column and tile renderers for the list data component.
extension _ListDataItemViewsX<T> on _ListDataComponentState<T> {
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

  Widget emptyItem() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 5, top: 5),
      color: Colors.transparent,
    );
  }
}
