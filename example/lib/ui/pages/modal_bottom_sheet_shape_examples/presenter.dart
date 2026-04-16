import 'package:flutter/material.dart';
import 'view.dart';

class ModalBottomSheetShapeExamplesPage extends StatefulWidget {
  const ModalBottomSheetShapeExamplesPage({super.key});

  @override
  State<ModalBottomSheetShapeExamplesPage> createState() => _PresenterState();
}

class _PresenterState extends State<ModalBottomSheetShapeExamplesPage> {
  @override
  Widget build(BuildContext context) =>
      const ModalBottomSheetShapeExamplesView();
}
