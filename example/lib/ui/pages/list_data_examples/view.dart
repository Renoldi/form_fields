import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presenter.dart';
import 'view_model.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/localization/localizations.dart';

class View extends PresenterState {
  Future<List<String>> _dataSource(int offset, String? search) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final all = List<String>.generate(50, (i) => 'Item ${i + 1}');
    final filtered = (search == null || search.trim().isEmpty)
        ? all
        : all
            .where((e) => e.toLowerCase().contains(search.toLowerCase()))
            .toList();
    const pageSize = 10;
    final start = offset;
    if (start >= filtered.length) return <String>[];
    final end = (start + pageSize) > filtered.length
        ? filtered.length
        : start + pageSize;
    return filtered.sublist(start, end);
  }

  Widget _itemBuilder(BuildContext context, String? value, int index) {
    if (value == null) {
      return ListTile(
        leading: const CircleAvatar(child: Icon(Icons.list)),
        title: Container(height: 12, color: Colors.grey.shade300),
        subtitle: Container(height: 10, color: Colors.grey.shade200),
      );
    }
    final detailTemplate = context.tr('detailFor');
    final detail = detailTemplate.replaceFirst('{value}', value);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(child: Text(value.split(' ').last)),
        title: Text(value),
        subtitle: Text(detail),
        onTap: () {
          listController.value.selected = value;
          listController.commit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ViewModel(),
      child: Consumer<ViewModel>(
        builder: (context, vm, _) {
          // Keep the view model informed when data arrives via param

          return SafeScaffold(
            backgroundColor: Color(0xFFF6F6FB),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row(
                //   children: [
                //     Expanded(
                //       child: Text(
                //         context.tr('listDataExampleTitle'),
                //         style: Theme.of(context).textTheme.titleLarge,
                //         overflow: TextOverflow.ellipsis,
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     TextButton.icon(
                //       onPressed: () => context.pushRoute(AppRoute.language),
                //       icon: const Icon(Icons.language),
                //       label: Text(context
                //                   .watch<AppStateNotifier>()
                //                   .locale
                //                   .languageCode ==
                //               'id'
                //           ? context.tr('languageIndonesian')
                //           : context.tr('languageEnglish')),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 8),
                ValueListenableBuilder<ListDataComponentValue<String>>(
                  valueListenable: listController,
                  builder: (context, value, _) {
                    final tpl = context.tr('loadedItems');
                    final text = tpl.replaceFirst(
                        '{count}', value.data.length.toString());
                    return Text(text);
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListDataComponent<String>(
                    // searchIconInside: true,
                    controller: listController,
                    dataSource: _dataSource,
                    onDataReceived: (datas, search) => vm.updateSearch(search),
                    itemBuilder: (v, i) => _itemBuilder(context, v, i),
                    showSearchBox: true,
                    loaderCount: 3,
                    enableGetMore: true,
                    autoLoad: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
