import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presenter.dart';
import 'view_model.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/localization/localizations.dart';
// `flutter_map` is used internally by the package; example doesn't import it directly.

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapExamplesViewModel(),
      child: Consumer<MapExamplesViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('mapExampleTitle'))),
            body: Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(context.tr('mapExampleDescription')),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => vm.generateDemoData(),
                              child:
                                  const Text('Generate 1000 markers + shapes'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => vm.clearDemoData(),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Fullscreen map area
                        Expanded(
                          child: FormFieldsMap(
                            notifier: vm.mapNotifier,
                            initialCenter: vm.center,
                            initialZoom: 12.0,
                            onTap: (latlng) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tapped: ${latlng.latitude}, ${latlng.longitude}',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                        Text('Code example',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const SelectableText(
                            "FormFieldsMap(center: LatLong(-6.2, 106.8166), zoom: 12.0)",
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // NOTE: loading indicator for demo data generation is shown
                // by the map widget itself via the controller. The view-level
                // indicator was removed to avoid duplicate overlays.
              ],
            ),
          );
        },
      ),
    );
  }
}
