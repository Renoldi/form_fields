import 'package:flutter/material.dart';
import 'main.dart' as main;

class Presenter extends StatefulWidget {
  const Presenter({super.key});

  @override
  State<Presenter> createState() => main.View();
}

abstract class PresenterState extends State<Presenter> {
  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (!mounted) return;
    //   try {
    //     final vm = Provider.of<MapExamplesViewModel>(context, listen: false);
    //     vm.generateMarkers(markerCount: vm.createMarkers);
    //   } catch (e, st) {
    //     debugPrint('generateMarkers post-frame callback error: $e');
    //     debugPrint(st.toString());
    //   }
    // });
  }
}
