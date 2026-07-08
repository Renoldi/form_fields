import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'main.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SqlViewerViewModel(),
      child: _SqlView(),
    );
  }
}

class _SqlView extends StatefulWidget {
  @override
  State<_SqlView> createState() => _SqlViewState();
}

class _SqlViewState extends State<_SqlView> {
  bool inlinePayloadsInList = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SqlViewerViewModel>().loadTables();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SqlViewerViewModel>(builder: (context, vm, _) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: LayoutBuilder(builder: (context, constraints) {
                final dropdownWidth = constraints.maxWidth > 480
                    ? 300.0
                    : constraints.maxWidth * 0.5;
                return Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: dropdownWidth,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        isDense: true,
                        initialValue: vm.selectedTable,
                        items: vm.tables
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t,
                                  overflow: TextOverflow.ellipsis,
                                )))
                            .toList(),
                        onChanged: (v) async {
                          if (v != null) {
                            await vm.loadRows(v,
                                inlinePayloads: inlinePayloadsInList);
                            if (!mounted) return;
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Table'),
                      ),
                    ),
                    ElevatedButton(
                        onPressed: vm.loading
                            ? null
                            : () async {
                                final vmRef = vm;
                                await vmRef.loadTables();
                                if (!context.mounted) return;
                                if (vmRef.selectedTable != null) {
                                  await vmRef.loadRows(vmRef.selectedTable!,
                                      inlinePayloads: inlinePayloadsInList);
                                  if (!context.mounted) return;
                                }
                              },
                        child: const Text('Refresh')),
                    // Row(
                    //   mainAxisSize: MainAxisSize.min,
                    //   children: [
                    //     Checkbox(
                    //       value: _inlinePayloadsInList,
                    //       onChanged: vm.loading
                    //           ? null
                    //           : (v) async {
                    //               final newVal = v ?? false;
                    //               setState(() {
                    //                 _inlinePayloadsInList = newVal;
                    //               });
                    //               if (vm.selectedTable != null) {
                    //                 await vm.loadRows(vm.selectedTable!,
                    //                     inlinePayloads: newVal);
                    //                 if (!mounted) return;
                    //               }
                    //             },
                    //     ),
                    //     const Text('Inline payloads'),
                    //   ],
                    // ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.insert_drive_file),
                      label: const Text('Import from file'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final vmRef = vm;
                              final path = await ImportExportService.instance
                                  .pickFileAndImport();
                              if (!context.mounted) return;
                              final messenger =
                                  ScaffoldMessenger.maybeOf(context);
                              if (path != null) {
                                messenger?.showSnackBar(SnackBar(
                                    content:
                                        Text('Imported from file: $path')));
                                await vmRef.loadTables();
                                if (vmRef.selectedTable != null) {
                                  await vmRef.loadRows(vmRef.selectedTable!,
                                      inlinePayloads: inlinePayloadsInList);
                                }
                              } else {
                                messenger?.showSnackBar(const SnackBar(
                                    content:
                                        Text('Import cancelled or failed')));
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Export to folder'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final out = await ImportExportService.instance
                                  .pickFolderAndExport();
                              if (!context.mounted) return;
                              final messenger =
                                  ScaffoldMessenger.maybeOf(context);
                              if (out != null) {
                                messenger?.showSnackBar(SnackBar(
                                    content: Text('Exported to $out')));
                              } else {
                                messenger?.showSnackBar(const SnackBar(
                                    content: Text('Export cancelled')));
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Export SQL File'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final tmpDir = await getTemporaryDirectory();
                              final out = p.join(tmpDir.path,
                                  'export_${DateTime.now().millisecondsSinceEpoch}.sql');
                              try {
                                await DBService.instance.exportToSqlFile(out);
                                if (!context.mounted) return;
                                final messenger =
                                    ScaffoldMessenger.maybeOf(context);
                                messenger?.showSnackBar(SnackBar(
                                    content: Text('Exported SQL to $out')));
                              } catch (e) {
                                if (!context.mounted) return;
                                final messenger =
                                    ScaffoldMessenger.maybeOf(context);
                                messenger?.showSnackBar(SnackBar(
                                    content: Text('Export failed: $e')));
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run SQL'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final controller = TextEditingController();
                              final query = await showDialog<String?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Run SQL InsUpDel'),
                                  content: TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 8,
                                    decoration: const InputDecoration(
                                        labelText: 'SQL query',
                                        hintText: 'Paste SQL here...'),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, null),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, controller.text),
                                        child: const Text('Execute')),
                                  ],
                                ),
                              );
                              if (query == null || query.trim().isEmpty) return;
                              final vmRef = vm;
                              try {
                                final res = await DBService.instance
                                    .executeSqlInsUpDel(query);
                                if (!context.mounted) return;
                                final messenger =
                                    ScaffoldMessenger.maybeOf(context);
                                messenger?.showSnackBar(SnackBar(
                                    content:
                                        Text('SQL executed, result: $res')));
                                await vmRef.loadTables();
                                if (vmRef.selectedTable != null) {
                                  await vmRef.loadRows(vmRef.selectedTable!,
                                      inlinePayloads: inlinePayloadsInList);
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                final messenger =
                                    ScaffoldMessenger.maybeOf(context);
                                messenger?.showSnackBar(SnackBar(
                                    content: Text('SQL execution failed: $e')));
                              }
                            },
                    ),
                    // Detailed example usage of DBService.selectFrom
                    ElevatedButton.icon(
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Select From (detailed)'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final tableCtrl = TextEditingController(
                                  text: vm.selectedTable ?? '');
                              final colsCtrl = TextEditingController();
                              final whereCtrl = TextEditingController();
                              final orderCtrl = TextEditingController();
                              final limitCtrl = TextEditingController();
                              final offsetCtrl = TextEditingController();
                              bool inlinePayloads = inlinePayloadsInList;

                              final params =
                                  await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (ctx) => StatefulBuilder(
                                  builder: (ctx, setState) => AlertDialog(
                                    title: const Text('Select From parameters'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: tableCtrl,
                                            decoration: const InputDecoration(
                                                labelText: 'Table name'),
                                          ),
                                          TextField(
                                            controller: colsCtrl,
                                            decoration: const InputDecoration(
                                                labelText:
                                                    'Columns (comma-separated, optional)'),
                                          ),
                                          TextField(
                                            controller: whereCtrl,
                                            decoration: const InputDecoration(
                                                labelText:
                                                    'WHERE clause (e.g. id = 1) optional'),
                                          ),
                                          TextField(
                                            controller: orderCtrl,
                                            decoration: const InputDecoration(
                                                labelText:
                                                    'ORDER BY (optional)'),
                                          ),
                                          Row(children: [
                                            Expanded(
                                              child: TextField(
                                                controller: limitCtrl,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'Limit (optional)'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller: offsetCtrl,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'Offset (optional)'),
                                              ),
                                            ),
                                          ]),
                                          CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            value: inlinePayloads,
                                            onChanged: (v) => setState(() =>
                                                inlinePayloads = v ?? true),
                                            title: const Text(
                                                'Inline payload files as JSON'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, null),
                                          child: const Text('Cancel')),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx, {
                                              'table': tableCtrl.text.trim(),
                                              'columns': colsCtrl.text.trim(),
                                              'where': whereCtrl.text.trim(),
                                              'orderBy': orderCtrl.text.trim(),
                                              'limit': limitCtrl.text.trim(),
                                              'offset': offsetCtrl.text.trim(),
                                              'inline': inlinePayloads,
                                            });
                                          },
                                          child: const Text('Execute')),
                                    ],
                                  ),
                                ),
                              );

                              if (params == null) return;
                              final table =
                                  (params['table'] as String?)?.trim();
                              if (table == null || table.isEmpty) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.maybeOf(context)
                                    ?.showSnackBar(const SnackBar(
                                        content: Text('Table required')));
                                return;
                              }

                              List<String>? columns;
                              final colsText = params['columns'] as String?;
                              if (colsText != null && colsText.isNotEmpty) {
                                columns = colsText
                                    .split(',')
                                    .map((s) => s.trim())
                                    .where((s) => s.isNotEmpty)
                                    .toList();
                              }

                              final where =
                                  (params['where'] as String?)?.trim();
                              final orderBy =
                                  (params['orderBy'] as String?)?.trim();
                              final limit = int.tryParse(
                                  (params['limit'] as String?) ?? '');
                              final offset = int.tryParse(
                                  (params['offset'] as String?) ?? '');
                              final inline = params['inline'] == true;

                              try {
                                final rows =
                                    await DBService.instance.selectFrom(
                                  table,
                                  columns: columns,
                                  where:
                                      where?.isNotEmpty == true ? where : null,
                                  orderBy: orderBy?.isNotEmpty == true
                                      ? orderBy
                                      : null,
                                  limit: limit,
                                  offset: offset,
                                  inlinePayloads: inline,
                                );

                                if (!context.mounted) return;

                                if (rows.isEmpty) {
                                  ScaffoldMessenger.maybeOf(context)
                                      ?.showSnackBar(const SnackBar(
                                          content: Text('No rows')));
                                  return;
                                }

                                // Build header order from union of keys
                                final headers = <String>{};
                                for (final r in rows) {
                                  headers
                                      .addAll(r.keys.map((k) => k.toString()));
                                }
                                final headerList = headers.toList();

                                await showDialog<void>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Rows (${rows.length})'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: SingleChildScrollView(
                                          child: DataTable(
                                            columns: headerList
                                                .map((h) =>
                                                    DataColumn(label: Text(h)))
                                                .toList(),
                                            rows: rows.map((r) {
                                              return DataRow(
                                                  cells: headerList
                                                      .map((h) => DataCell(Text(
                                                          r[h]?.toString() ??
                                                              'NULL')))
                                                      .toList());
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Close'))
                                    ],
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.maybeOf(context)
                                    ?.showSnackBar(SnackBar(
                                        content: Text('Select failed: $e')));
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.system_update_alt),
                      label: const Text('Upgrade DB'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final vmRef = vm;
                              final controller = TextEditingController();
                              final assetsController = TextEditingController();
                              final target = await showDialog<int?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Upgrade database'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            labelText: 'Target version (int)'),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: assetsController,
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                            labelText:
                                                'Migration asset paths (comma-separated)'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, null),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () {
                                          final v = int.tryParse(
                                              controller.text.trim());
                                          Navigator.pop(ctx, v);
                                        },
                                        child: const Text('Upgrade')),
                                  ],
                                ),
                              );
                              if (target != null) {
                                final assetsText = assetsController.text.trim();
                                final assetsList = assetsText.isEmpty
                                    ? null
                                    : assetsText
                                        .split(',')
                                        .map((s) => s.trim())
                                        .where((s) => s.isNotEmpty)
                                        .toList();
                                await vmRef.upgradeAndCaptureTables(target,
                                    migrationAssetPaths: assetsList);
                                if (!context.mounted) return;
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Tables: before → after'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Before:'),
                                          for (final t
                                              in vmRef.tablesBeforeUpgrade)
                                            Text(' • $t'),
                                          const SizedBox(height: 8),
                                          const Text('After:'),
                                          for (final t
                                              in vmRef.tablesAfterUpgrade)
                                            Text(' • $t'),
                                          if (vmRef.lastUpgradeError !=
                                              null) ...[
                                            const SizedBox(height: 8),
                                            const Text('Error:'),
                                            Text(vmRef.lastUpgradeError!),
                                          ],
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Close'))
                                    ],
                                  ),
                                );
                                await vmRef.loadTables();
                                if (vmRef.selectedTable != null) {
                                  await vmRef.loadRows(vmRef.selectedTable!,
                                      inlinePayloads: inlinePayloadsInList);
                                }
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.system_update_alt),
                      label: const Text('Downgrade DB'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final vmRef = vm;
                              final controller = TextEditingController();
                              final assetsController = TextEditingController();
                              final target = await showDialog<int?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Downgrade database'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: controller,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            labelText: 'Target version (int)'),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: assetsController,
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                            labelText:
                                                'Migration asset paths (comma-separated)'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, null),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () {
                                          final v = int.tryParse(
                                              controller.text.trim());
                                          Navigator.pop(ctx, v);
                                        },
                                        child: const Text('Downgrade')),
                                  ],
                                ),
                              );
                              if (target != null) {
                                final assetsText = assetsController.text.trim();
                                final assetsList = assetsText.isEmpty
                                    ? null
                                    : assetsText
                                        .split(',')
                                        .map((s) => s.trim())
                                        .where((s) => s.isNotEmpty)
                                        .toList();
                                await vmRef.downgradeAndCaptureTables(target,
                                    migrationAssetPaths: assetsList);
                                if (!context.mounted) return;
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Tables: before → after'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Before:'),
                                          for (final t
                                              in vmRef.tablesBeforeUpgrade)
                                            Text(' • $t'),
                                          const SizedBox(height: 8),
                                          const Text('After:'),
                                          for (final t
                                              in vmRef.tablesAfterUpgrade)
                                            Text(' • $t'),
                                          if (vmRef.lastUpgradeError !=
                                              null) ...[
                                            const SizedBox(height: 8),
                                            const Text('Error:'),
                                            Text(vmRef.lastUpgradeError!),
                                          ],
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Close'))
                                    ],
                                  ),
                                );
                                await vmRef.loadTables();
                                if (vmRef.selectedTable != null) {
                                  await vmRef.loadRows(vmRef.selectedTable!,
                                      inlinePayloads: inlinePayloadsInList);
                                }
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Set DB version'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final vmRef = vm;
                              final controller = TextEditingController();
                              final target = await showDialog<int?>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Set DB version'),
                                  content: TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText: 'Version (int)'),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, null),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () {
                                          final v = int.tryParse(
                                              controller.text.trim());
                                          Navigator.pop(ctx, v);
                                        },
                                        child: const Text('Set')),
                                  ],
                                ),
                              );
                              if (target != null) {
                                await vmRef.setUserVersion(target);
                                if (!context.mounted) return;
                                final messenger =
                                    ScaffoldMessenger.maybeOf(context);
                                final ver = vmRef.dbVersion;
                                if (vmRef.lastUpgradeError != null) {
                                  messenger?.showSnackBar(SnackBar(
                                      content: Text(
                                          'Failed: ${vmRef.lastUpgradeError}')));
                                } else {
                                  messenger?.showSnackBar(SnackBar(
                                      content: Text(
                                          'user_version set -> ${ver ?? 'unknown'}')));
                                }
                                await vmRef.loadDbVersion();
                                await vmRef.loadTables();
                                if (vmRef.selectedTable != null) {
                                  await vmRef.loadRows(vmRef.selectedTable!,
                                      inlinePayloads: inlinePayloadsInList);
                                }
                              }
                            },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Reset DB'),
                      onPressed: vm.loading
                          ? null
                          : () async {
                              final vmRef = vm;
                              final result =
                                  await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (ctx) {
                                  bool removeMigrations = false;
                                  bool removePayloads = false;
                                  return StatefulBuilder(
                                    builder: (ctx, setState) => AlertDialog(
                                      title: const Text('Reset database?'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                              'This will delete the local database and re-initialize it from bundled assets.'),
                                          CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            value: removeMigrations,
                                            onChanged: (v) => setState(() =>
                                                removeMigrations = v ?? false),
                                            title: const Text(
                                                'Also delete migrations folder'),
                                          ),
                                          CheckboxListTile(
                                            contentPadding: EdgeInsets.zero,
                                            value: removePayloads,
                                            onChanged: (v) => setState(() =>
                                                removePayloads = v ?? false),
                                            title: const Text(
                                                'Also delete payloads folder'),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, null),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, {
                                                  'confirmed': true,
                                                  'removeMigrations':
                                                      removeMigrations,
                                                  'removePayloads':
                                                      removePayloads,
                                                }),
                                            child: const Text('Reset')),
                                      ],
                                    ),
                                  );
                                },
                              );
                              if (result != null &&
                                  result['confirmed'] == true) {
                                final removeMigrations =
                                    result['removeMigrations'] == true;
                                final removePayloads =
                                    result['removePayloads'] == true;
                                await DBService.instance.resetDatabase(
                                    reinit: false,
                                    removeMigrationsDir: removeMigrations,
                                    removePayloadsDir: removePayloads);
                                if (!context.mounted) return;
                                final messenger =
                                    ScaffoldMessenger.maybeOf(context);
                                messenger?.showSnackBar(const SnackBar(
                                    content: Text('Database reset')));
                                // Do not call loadTables() here because that calls
                                // `DBService.init()` which would recreate the DB.
                                // Instead, clear the view model state so UI shows empty.
                                vmRef.clearState();
                              }
                            },
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Consumer<SqlViewerViewModel>(builder: (context, vm, _) {
                final verText =
                    vm.dbVersion != null ? vm.dbVersion.toString() : 'unknown';
                return Text('DB version: $verText');
              }),
            ),
            const SizedBox(height: 8),
            if (vm.loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: vm.selectedTable == null
                  ? const Center(child: Text('Select a table to view rows'))
                  : ListView.builder(
                      itemCount: vm.rows.length,
                      itemBuilder: (context, idx) {
                        final row = vm.rows[idx];
                        final rowid = row['rowid'] ?? row['id'] ?? idx;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ExpansionTile(
                            title: Text('${vm.selectedTable} • row $rowid'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: FutureBuilder<String>(
                                  future: vm.rowToPrettyJson(row,
                                      includePayloads: idx == 0),
                                  builder: (context, snap) {
                                    if (snap.connectionState !=
                                        ConnectionState.done) {
                                      return const SizedBox(
                                          height: 24,
                                          child: Center(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2)));
                                    }
                                    final text = snap.data ?? '';
                                    return SelectableText(text);
                                  },
                                ),
                              ),
                              OverflowBar(
                                spacing: 8,
                                children: [
                                  TextButton.icon(
                                    onPressed: () async {
                                      final text = await vm.rowToPrettyJson(row,
                                          includePayloads: idx == 0);
                                      await Clipboard.setData(
                                          ClipboardData(text: text));
                                      if (!context.mounted) return;
                                      final messenger =
                                          ScaffoldMessenger.maybeOf(context);
                                      messenger?.showSnackBar(const SnackBar(
                                          content: Text('Copied JSON')));
                                    },
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Copy JSON'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final vmRef = vm;
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Delete row?'),
                                          content: const Text(
                                              'This will delete the row from the database.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Delete')),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        final id = (row['rowid'] is int)
                                            ? row['rowid'] as int
                                            : (row['id'] is int
                                                ? row['id'] as int
                                                : null);
                                        if (id != null) {
                                          await vmRef.deleteRow(
                                              vm.selectedTable!, id);
                                          if (!context.mounted) return;
                                          final messenger =
                                              ScaffoldMessenger.maybeOf(
                                                  context);
                                          messenger?.showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('Row deleted')));
                                        } else {
                                          if (!context.mounted) return;
                                          final messenger =
                                              ScaffoldMessenger.maybeOf(
                                                  context);
                                          messenger?.showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Unable to determine row id')));
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.delete_forever),
                                    label: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}
