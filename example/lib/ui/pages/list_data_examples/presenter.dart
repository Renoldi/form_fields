import 'package:flutter/material.dart';
import 'main.dart' as main;
import 'package:form_fields/form_fields.dart';

class Presenter extends StatefulWidget {
  const Presenter({super.key});

  @override
  State<Presenter> createState() => main.View();
}

abstract class PresenterState extends State<Presenter> {
  final ListDataComponentController<String> listController =
      ListDataComponentController<String>();

  @override
  void dispose() {
    try {
      listController.dispose();
    } catch (_) {}
    super.dispose();
  }
}
