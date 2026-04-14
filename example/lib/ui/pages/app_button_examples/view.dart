import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';

import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  String _keyboardTestValue = '';
  Set<String> _selectedVolume = {'4oz'};
  Set<String> _selectedSegment = {'songs'};
  String _lastSplitAction = '-';
  String _lastTypedButtonValue = '-';

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  FormFields<String>(
                    label: 'Keyboard test field',
                    currrentValue: _keyboardTestValue,
                    onChanged: (value) {
                      setState(() {
                        _keyboardTestValue = value;
                      });
                    },
                    inputDecoration: const InputDecoration(
                      hintText: 'Tap here, then focus on button behavior',
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    type: AppButtonType.filled,
                    size: AppButtonSize.large,
                    text: 'Filled Large',
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    type: AppButtonType.elevated,
                    size: AppButtonSize.medium,
                    text: 'Elevated Medium',
                    icon: const Icon(Icons.rocket_launch_outlined),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    type: AppButtonType.outlined,
                    size: AppButtonSize.medium,
                    text: 'Outlined Medium',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    type: AppButtonType.text,
                    size: AppButtonSize.small,
                    text: 'Text Small',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    type: AppButtonType.filledTonal,
                    size: AppButtonSize.medium,
                    text: 'Filled Tonal',
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    type: AppButtonType.filled,
                    size: AppButtonSize.custom,
                    customHeight: 52,
                    customHorizontalPadding: 28,
                    customIconSize: 26,
                    customSpinnerSize: 20,
                    text: 'Custom Size',
                    icon: const Icon(Icons.straighten),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  AppButton<String>(
                    type: AppButtonType.outlined,
                    size: AppButtonSize.medium,
                    text: 'Typed Callback (T)',
                    icon: const Icon(Icons.data_object),
                    value: 'checkout',
                    onPressedWithValue: (value) {
                      setState(() {
                        _lastTypedButtonValue = value ?? '-';
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  Text('Last typed payload: $_lastTypedButtonValue'),
                  const SizedBox(height: 16),
                  Text(
                    'Button Groups',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppSegmentedButton<String>(
                          size: AppButtonSize.small,
                          segments: const [
                            ButtonSegment<String>(
                              value: '4oz',
                              label: Text('4 oz'),
                            ),
                            ButtonSegment<String>(
                              value: '8oz',
                              label: Text('8 oz'),
                            ),
                            ButtonSegment<String>(
                              value: '12oz',
                              label: Text('12 oz'),
                            ),
                          ],
                          selected: _selectedVolume,
                          onSelectionChanged: (value) {
                            setState(() {
                              _selectedVolume = value;
                            });
                          },
                          selectedIcon: const Icon(Icons.check, size: 14),
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            AppButton(
                              type: AppButtonType.icon,
                              size: AppButtonSize.custom,
                              customHeight: 48,
                              customIconSize: 22,
                              icon:
                                  const Icon(Icons.accessibility_new_outlined),
                              style: ButtonStyle(
                                shape: const WidgetStatePropertyAll(
                                    CircleBorder()),
                                side: WidgetStatePropertyAll(
                                  BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                ),
                              ),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppButton(
                                type: AppButtonType.filled,
                                size: AppButtonSize.custom,
                                customHeight: 48,
                                text: 'Get started',
                                style: FilledButton.styleFrom(
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 10),
                            AppButton(
                              type: AppButtonType.icon,
                              size: AppButtonSize.custom,
                              customHeight: 48,
                              customIconSize: 22,
                              icon: const Icon(Icons.public_outlined),
                              style: ButtonStyle(
                                shape: const WidgetStatePropertyAll(
                                    CircleBorder()),
                                side: WidgetStatePropertyAll(
                                  BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                ),
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      AppButton(
                        type: AppButtonType.icon,
                        size: AppButtonSize.small,
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        type: AppButtonType.icon,
                        size: AppButtonSize.medium,
                        icon: const Icon(Icons.bookmark_border),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        type: AppButtonType.icon,
                        size: AppButtonSize.large,
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Floating Action Buttons',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AppButton(
                        type: AppButtonType.fab,
                        size: AppButtonSize.small,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        type: AppButtonType.fab,
                        size: AppButtonSize.medium,
                        icon: const Icon(Icons.edit),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        type: AppButtonType.fab,
                        size: AppButtonSize.large,
                        icon: const Icon(Icons.edit_note),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      type: AppButtonType.extendedFab,
                      text: 'New task',
                      icon: const Icon(Icons.add),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          type: AppButtonType.filled,
                          size: AppButtonSize.medium,
                          text: 'Custom Style Override',
                          icon: const Icon(Icons.tune),
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          type: AppButtonType.filled,
                          size: AppButtonSize.small,
                          text: 'Custom Style Override',
                          icon: const Icon(Icons.tune),
                          style: FilledButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          type: AppButtonType.elevated,
                          size: AppButtonSize.medium,
                          text: 'Rounded 16',
                          icon: const Icon(Icons.rounded_corner),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          type: AppButtonType.outlined,
                          size: AppButtonSize.medium,
                          text: 'Beveled',
                          icon: const Icon(Icons.crop_16_9),
                          style: OutlinedButton.styleFrom(
                            shape: const BeveledRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    type: AppButtonType.filled,
                    size: AppButtonSize.medium,
                    text: 'Continuous Rectangle Shape',
                    icon: const Icon(Icons.hexagon_outlined),
                    style: FilledButton.styleFrom(
                      shape: const ContinuousRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                      ),
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Segmented Buttons',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppSegmentedButton<String>(
                    size: AppButtonSize.medium,
                    segments: const [
                      ButtonSegment<String>(
                        value: 'songs',
                        icon: Icon(Icons.check, size: 16),
                        label: Text('Songs'),
                      ),
                      ButtonSegment<String>(
                        value: 'albums',
                        label: Text('Albums'),
                      ),
                      ButtonSegment<String>(
                        value: 'podcasts',
                        label: Text('Podcasts'),
                      ),
                    ],
                    selected: _selectedSegment,
                    onSelectionChanged: (value) {
                      setState(() {
                        _selectedSegment = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Split Button',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppSplitButton<String>(
                    size: AppButtonSize.large,
                    text: 'Add to cart',
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      setState(() {
                        _lastSplitAction = 'default';
                      });
                    },
                    items: const [
                      AppSplitButtonItem(
                        value: 'save',
                        label: 'Save for later',
                      ),
                      AppSplitButtonItem(
                        value: 'wishlist',
                        label: 'Add to wishlist',
                      ),
                      AppSplitButtonItem(
                        value: 'gift',
                        label: 'Buy as gift',
                      ),
                    ],
                    onSelected: (value) {
                      setState(() {
                        _lastSplitAction = value;
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  Text('Last split action: $_lastSplitAction'),
                  const SizedBox(height: 16),
                  Text(
                    'FAB Menu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppFabMenu(
                      size: AppButtonSize.small,
                      items: [
                        AppFabMenuItem(
                          label: 'First',
                          icon: const Icon(Icons.looks_one_outlined),
                          onPressed: () {},
                        ),
                        AppFabMenuItem(
                          label: 'Second',
                          icon: const Icon(Icons.looks_two_outlined),
                          onPressed: () {},
                        ),
                        AppFabMenuItem(
                          label: 'Third',
                          icon: const Icon(Icons.looks_3_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            AppButton(
              withLayout: true,
              type: AppButtonType.filled,
              size: AppButtonSize.large,
              text: 'Submit (Loading + SafeArea + Keyboard)',
              icon: const Icon(Icons.send_outlined),
              isLoading: viewModel.isSubmitting,
              onPressed: viewModel.isSubmitting
                  ? null
                  : () {
                      viewModel.submit();
                    },
            ),
          ],
        );
      },
    );
  }
}
