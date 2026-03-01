import 'package:flutter/material.dart' hide View;
import 'view.dart';

class Presenter extends StatefulWidget {
  final VoidCallback onBack;

  const Presenter({
    super.key,
    required this.onBack,
  });

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {
  // No business logic needed for this simple page
}
