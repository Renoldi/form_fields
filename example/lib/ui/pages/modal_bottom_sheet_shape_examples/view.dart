import 'package:flutter/material.dart';
import 'view_model.dart';

class ModalBottomSheetShapeExamplesView extends StatelessWidget {
  const ModalBottomSheetShapeExamplesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modal Bottom Sheet Shapes Example')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...ModalBottomSheetShapeExamplesViewModel.shapes.map(
            (shapeData) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton(
                onPressed: () => shapeData.show(context),
                child: Text(shapeData.label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
