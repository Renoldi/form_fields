import 'package:flutter/material.dart' hide View;
import 'package:provider/provider.dart';

import 'view.dart';
import 'view_model.dart';

class Presenter extends StatefulWidget {
  const Presenter({super.key});

  @override
  State<Presenter> createState() => View();
}

abstract class PresenterState extends State<Presenter> {
  late final ViewModel viewModel = context.read<ViewModel>();
}
