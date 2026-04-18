import 'package:flutter/material.dart' hide View;
import 'package:form_fields/form_fields.dart';
import 'view.dart';

class Presenter extends StatefulWidget {
  const Presenter({super.key});

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {
  // Business logic goes here
  final MyImageController networkImagesController = MyImageController()
    ..images = [
      MyimageResult(path: '', base64: "", link: 'https://picsum.photos/150'),
      MyimageResult(path: '', base64: "", link: 'https://picsum.photos/200'),
    ];
  // Controller for asset image demo (now using network links)
  final MyImageController assetImagesController = MyImageController()
    ..images = [
      MyimageResult(
        path: '',
        base64: "",
        link:
            'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
      ),
      MyimageResult(
        path: '',
        base64: "",
        link:
            'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80',
      ),
    ];
  final MyImageController profileController = MyImageController();
  final MyImageController multiController = MyImageController();
  final MyImageController customController = MyImageController();
  final MyImageController customsController = MyImageController();

  String? singleImageLog;
  String? singleRemoveLog;
}
