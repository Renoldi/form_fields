import 'package:flutter/material.dart' hide View;
import 'view.dart';
import 'package:form_fields_example/ui/pages/map_examples/view_model.dart';
import 'package:provider/provider.dart';

class Presenter extends StatefulWidget {
  const Presenter({super.key});

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final vm = Provider.of<MapExamplesViewModel>(context, listen: false);
        vm.generateMarkers(markerCount: vm.createMarkers);
      } catch (e, st) {
        debugPrint('generateMarkers post-frame callback error: $e');
        debugPrint(st.toString());
      }
    });
  }
}
