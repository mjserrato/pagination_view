library pagination_view;

import 'dart:async';

import 'package:flutter/material.dart';

typedef PaginationBuilder<T> = Future<List<T>> Function(int currentListSize);

class PaginationView<T> extends StatefulWidget {
  const PaginationView({
    Key key,
    @required this.itemBuilder,
    @required this.pageFetch,
    @required this.onEmpty,
    @required this.onError,
    this.onLoading = const Center(child: CircularProgressIndicator()),
    this.onPageLoading = const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(),
        ),
      ),
    ),
    this.padding = const EdgeInsets.all(0),
    this.seperatorWidget = const SizedBox(height: 0, width: 0),
  }) : super(key: key);

  final Widget Function(BuildContext, T) itemBuilder;
  final PaginationBuilder<T> pageFetch;
  final Widget onEmpty;
  final Widget Function(dynamic) onError;
  final Widget onLoading;
  final Widget onPageLoading;
  final EdgeInsets padding;
  final Widget seperatorWidget;

  @override
  _PaginationViewState<T> createState() => _PaginationViewState<T>();
}

class _PaginationViewState<T> extends State<PaginationView<T>>
    with AutomaticKeepAliveClientMixin<PaginationView<T>> {
  final List<T> _itemList = <T>[];
  dynamic _error;
  final StreamController<PageState> _streamController =
      StreamController<PageState>();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<PageState>(
      stream: _streamController.stream,
      initialData: PageState.firstLoad,
      builder: (BuildContext context, AsyncSnapshot<PageState> snapshot) {
        if (!snapshot.hasData) {
          return widget.onLoading;
        }
        if (snapshot.data == PageState.firstLoad) {
          fetchPageData(offset: _itemList.length);
          return widget.onLoading;
        }
        if (snapshot.data == PageState.firstEmpty) {
          return widget.onEmpty;
        }
        if (snapshot.data == PageState.firstError) {
          return widget.onError(_error);
        }
        return ListView.separated(
          padding: widget.padding,
          itemCount: _itemList.length,
          separatorBuilder: (BuildContext context, int index) =>
              widget.seperatorWidget,
          itemBuilder: (BuildContext context, int index) {
            if (_itemList[index] == null &&
                snapshot.data == PageState.pageLoad) {
              fetchPageData(offset: index);
              return widget.onPageLoading;
            }
            if (_itemList[index] == null &&
                snapshot.data == PageState.pageError) {
              return widget.onError(_error);
            }
            return widget.itemBuilder(context, _itemList[index]);
          },
        );
      },
    );
  }

  void fetchPageData({int offset = 0}) {
    widget.pageFetch(offset).then((List<T> list) {
      if (_itemList.contains(null)) {
        _itemList.remove(null);
      }
      if (list.isEmpty) {
        if (offset == 0) {
          _streamController.add(PageState.firstEmpty);
        } else {
          _streamController.add(PageState.pageEmpty);
        }
        return;
      }

      _itemList.addAll(list);

      _itemList.add(null);
      _streamController.add(PageState.pageLoad);
    }, onError: (dynamic _error) {
      this._error = _error;
      if (offset == 0) {
        _streamController.add(PageState.firstError);
      } else {
        if (!_itemList.contains(null)) {
          _itemList.add(null);
        }
        _streamController.add(PageState.pageError);
      }
    });
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

enum PageState {
  pageLoad,
  pageError,
  pageEmpty,
  firstEmpty,
  firstLoad,
  firstError,
}
