import 'package:flutter/material.dart';
import 'view.dart';

class BarcodeScanPresenter extends StatefulWidget {
  const BarcodeScanPresenter({super.key});

  @override
  State<BarcodeScanPresenter> createState() => BarcodeScanView();
}

abstract class BarcodeScanPresenterState extends State<BarcodeScanPresenter> {
  // Business logic goes here
}
