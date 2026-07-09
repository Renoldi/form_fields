import 'package:flutter/material.dart' hide View;
import 'view.dart';

class Presenter extends StatefulWidget {
  final Map<String, dynamic>? payload;
  const Presenter({super.key, this.payload});

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {}
