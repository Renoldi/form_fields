import 'package:flutter/material.dart';
import 'main.dart' as main;

class Presenter extends StatefulWidget {
  const Presenter({super.key});

  @override
  State<Presenter> createState() => main.View();
}

abstract class PresenterState extends State<Presenter> {
  main.ViewModel model = main.ViewModel();
  @override
  void initState() {
    super.initState();
    // model.generateMarkers(markerCount: model.createMarkers);
  }
}
