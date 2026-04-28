import 'package:flutter/material.dart';
import 'view_model.dart';

class ModalBottomSheetShapeExamplesView extends StatelessWidget {
  const ModalBottomSheetShapeExamplesView({super.key});

  Widget _jsonBlock(String json) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          json,
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 12, color: Color(0xFF333333)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shapes = ModalBottomSheetShapeExamplesViewModel.shapes;
    return Scaffold(
      appBar: AppBar(title: const Text('Modal Bottom Sheet Shapes Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Default
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              onPressed: () => shapes[0].show(context),
              child: Text(shapes[0].label),
            ),
          ),
          Text('Contoh Pengisian (JSON):',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          _jsonBlock(
            '{\n'
            '  "showAppModalBottomSheet": {\n'
            '    "isScrollControlled": true,\n'
            '    "enableDrag": true,\n'
            '    "scrollControlDisabledMaxHeightRatio": 0.5,\n'
            '    "shape": null\n'
            '  }\n'
            '}',
          ),

          // Rounded Rectangle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              onPressed: () => shapes[1].show(context),
              child: Text(shapes[1].label),
            ),
          ),
          Text('Contoh Pengisian (JSON):',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          _jsonBlock(
            '{\n'
            '  "shape": "RoundedRectangleBorder",\n'
            '  "borderRadius": "BorderRadius.vertical(top: Radius.circular(24))"\n'
            '}',
          ),

          // Continuous Rectangle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              onPressed: () => shapes[2].show(context),
              child: Text(shapes[2].label),
            ),
          ),
          Text('Contoh Pengisian (JSON):',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          _jsonBlock(
            '{\n'
            '  "shape": "ContinuousRectangleBorder",\n'
            '  "borderRadius": "BorderRadius.vertical(top: Radius.circular(40))"\n'
            '}',
          ),

          // Beveled Rectangle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              onPressed: () => shapes[3].show(context),
              child: Text(shapes[3].label),
            ),
          ),
          Text('Contoh Pengisian (JSON):',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          _jsonBlock(
            '{\n'
            '  "shape": "BeveledRectangleBorder",\n'
            '  "borderRadius": "BorderRadius.vertical(top: Radius.circular(20))"\n'
            '}',
          ),

          // Stadium Border
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              onPressed: () => shapes[4].show(context),
              child: Text(shapes[4].label),
            ),
          ),
          Text('Contoh Pengisian (JSON):',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          _jsonBlock(
            '{\n'
            '  "shape": "StadiumBorder()"\n'
            '}',
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
