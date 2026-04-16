import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

class ModalBottomSheetShapeData {
  final String label;
  final ShapeBorder? shape;
  const ModalBottomSheetShapeData(this.label, this.shape);

  void show(BuildContext context) {
    showAppModalBottomSheet(
      context: context,
      shape: shape,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(label, style: Theme.of(ctx).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Info'),
            onTap: () => Navigator.pop(ctx, 'Info'),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () => Navigator.pop(ctx, 'Edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () => Navigator.pop(ctx, 'Delete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class ModalBottomSheetShapeExamplesViewModel {
  static const shapes = [
    ModalBottomSheetShapeData('Default', null),
    ModalBottomSheetShapeData(
      'Rounded Rectangle',
      RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    ModalBottomSheetShapeData(
      'Continuous Rectangle',
      ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
    ),
    ModalBottomSheetShapeData(
      'Beveled Rectangle',
      BeveledRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    ModalBottomSheetShapeData(
      'Stadium Border',
      StadiumBorder(),
    ),
  ];
}
