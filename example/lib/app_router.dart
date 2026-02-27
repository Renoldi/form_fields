import 'package:go_router/go_router.dart';
import 'pages/form_fields_examples_page.dart';
import 'pages/dropdown_examples_page.dart';
import 'pages/dropdown_multi_examples_page.dart';
import 'pages/radio_button_examples_page.dart';
import 'pages/checkbox_examples_page.dart';
import 'pages/custom_class_examples_page.dart';
import 'pages/null_non_null_validation_examples_page.dart';
import 'widgets/scaffold_with_drawer.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/form-fields',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithDrawer(child: child),
      routes: [
        GoRoute(
          path: '/form-fields',
          builder: (context, state) => const FormFieldsExamplesPage(),
        ),
        GoRoute(
          path: '/dropdown',
          builder: (context, state) => const DropdownExamplesPage(),
        ),
        GoRoute(
          path: '/dropdown-multi',
          builder: (context, state) => const DropdownMultiExamplesPage(),
        ),
        GoRoute(
          path: '/radio-button',
          builder: (context, state) => const RadioButtonExamplesPage(),
        ),
        GoRoute(
          path: '/checkbox',
          builder: (context, state) => const CheckboxExamplesPage(),
        ),
        GoRoute(
          path: '/custom-class',
          builder: (context, state) => const CustomClassExamplesPage(),
        ),
        GoRoute(
          path: '/validation',
          builder: (context, state) =>
              const NullNonNullValidationExamplesPage(),
        ),
      ],
    ),
  ],
);
