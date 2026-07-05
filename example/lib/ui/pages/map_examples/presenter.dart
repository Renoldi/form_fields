import 'package:flutter/material.dart' hide View;
import 'package:provider/provider.dart';
import 'view.dart';
import 'view_model.dart';

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
