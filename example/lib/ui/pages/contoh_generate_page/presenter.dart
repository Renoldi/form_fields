import 'package:flutter/material.dart' hide View;
import 'view_model.dart';
import 'view.dart';

class Presenter extends StatefulWidget {
  const Presenter({
    super.key,
  });

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {}
