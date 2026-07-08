import 'package:flutter/material.dart';
import 'main.dart' as main;
import 'package:provider/provider.dart';

class Presenter extends StatefulWidget {
  const Presenter({super.key});

  @override
  State<Presenter> createState() => main.View();
}

abstract class PresenterState extends State<Presenter> {
  late final main.ViewModel viewModel = context.read<main.ViewModel>();
}
