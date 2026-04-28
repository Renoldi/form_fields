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
                    currentValue: _keyboardTestValue,
                    onChanged: (value) {
                      setState(() {
                        _keyboardTestValue = value;
                      });
                    },
                    inputDecoration: const InputDecoration(
                      hintText: 'Tap here, then focus on button behavior',
                    ),
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "FormFields<String>",\n  "label": "Keyboard test field",\n  "currentValue": _keyboardTestValue,\n  "onChanged": "(value) { ... }",\n  "inputDecoration": { "hintText": "Tap here, then focus on button behavior" }\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.filled",\n  "size": "AppButtonSize.large",\n  "text": "Filled Large",\n  "icon": "Icons.check_circle_outline",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    type: AppButtonType.elevated,
                    size: AppButtonSize.medium,
                    text: 'Elevated Medium',
                    icon: const Icon(Icons.rocket_launch_outlined),
                    onPressed: () {},
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.elevated",\n  "size": "AppButtonSize.medium",\n  "text": "Elevated Medium",\n  "icon": "Icons.rocket_launch_outlined",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    type: AppButtonType.outlined,
                    size: AppButtonSize.medium,
                    text: 'Outlined Medium',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {},
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.outlined",\n  "size": "AppButtonSize.medium",\n  "text": "Outlined Medium",\n  "icon": "Icons.edit_outlined",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    type: AppButtonType.text,
                    size: AppButtonSize.small,
                    text: 'Text Small',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {},
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.text",\n  "size": "AppButtonSize.small",\n  "text": "Text Small",\n  "icon": "Icons.info_outline",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    type: AppButtonType.filledTonal,
                    size: AppButtonSize.medium,
                    text: 'Filled Tonal',
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: () {},
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.filledTonal",\n  "size": "AppButtonSize.medium",\n  "text": "Filled Tonal",\n  "icon": "Icons.palette_outlined",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.filled",\n  "size": "AppButtonSize.custom",\n  "customHeight": 52,\n  "customHorizontalPadding": 28,\n  "customIconSize": 26,\n  "customSpinnerSize": 20,\n  "text": "Custom Size",\n  "icon": "Icons.straighten",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.outlined",\n  "size": "AppButtonSize.medium",\n  "text": "Typed Callback (T)",\n  "icon": "Icons.data_object",\n  "value": "checkout",\n  "onPressedWithValue": "(value) { ... }"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Last typed payload: $_lastTypedButtonValue'),
                  const SizedBox(height: 16),
                  Text(
                    'All AppButton Types',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppButtonGroup(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: 170,
                        child: AppButton(
                          type: AppButtonType.filled,
                          text: 'Filled',
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () {},
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: AppButton(
                          type: AppButtonType.filledTonal,
                          text: 'Filled Tonal',
                          icon: const Icon(Icons.tonality),
                          onPressed: () {},
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: AppButton(
                          type: AppButtonType.elevated,
                          text: 'Elevated',
                          icon: const Icon(Icons.trending_up_outlined),
                          onPressed: () {},
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: AppButton(
                          type: AppButtonType.outlined,
                          text: 'Outlined',
                          icon: const Icon(Icons.crop_square_outlined),
                          onPressed: () {},
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: AppButton(
                          type: AppButtonType.text,
                          text: 'Text',
                          icon: const Icon(Icons.text_fields),
                          onPressed: () {},
                        ),
                      ),
                      AppButton(
                        type: AppButtonType.icon,
                        size: AppButtonSize.medium,
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {},
                      ),
                      AppButton(
                        type: AppButtonType.fab,
                        size: AppButtonSize.medium,
                        icon: const Icon(Icons.add),
                        onPressed: () {},
                      ),
                      AppButton(
                        type: AppButtonType.extendedFab,
                        text: 'Extended FAB',
                        icon: const Icon(Icons.add_task_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "widget": "AppButtonGroup",\n  "spacing": 10,\n  "runSpacing": 10,\n  "children": "[SizedBox(width:170, child: AppButton(...)), ...]",\n  "note": "Wraps multiple AppButtons in a Wrap layout"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 220,
                    child: AppButton(
                      type: AppButtonType.filled,
                      text: 'Disabled',
                      icon: const Icon(Icons.block_outlined),
                      onPressed: null,
                    ),
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.filled",\n  "text": "Disabled",\n  "icon": "Icons.block_outlined",\n  "onPressed": null\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.icon",\n  "size": "AppButtonSize.small",\n  "icon": "Icons.favorite_border",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.icon",\n  "size": "AppButtonSize.medium",\n  "icon": "Icons.bookmark_border",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.icon",\n  "size": "AppButtonSize.large",\n  "icon": "Icons.share_outlined",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.fab",\n  "size": "AppButtonSize.small",\n  "icon": "Icons.edit_outlined",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.fab",\n  "size": "AppButtonSize.medium",\n  "icon": "Icons.edit",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.fab",\n  "size": "AppButtonSize.large",\n  "icon": "Icons.edit_note",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.extendedFab",\n  "text": "New task",\n  "icon": "Icons.add",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.filled",\n  "size": "AppButtonSize.medium",\n  "text": "Custom Style Override",\n  "icon": "Icons.tune",\n  "style": "FilledButton.styleFrom(StadiumBorder)",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.filled",\n  "size": "AppButtonSize.small",\n  "text": "Custom Style Override",\n  "icon": "Icons.tune",\n  "style": "FilledButton.styleFrom(StadiumBorder)",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.elevated",\n  "size": "AppButtonSize.medium",\n  "text": "Rounded 16",\n  "icon": "Icons.rounded_corner",\n  "style": "ElevatedButton.styleFrom(RoundedRectangleBorder(16))",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
                  ),
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.outlined",\n  "size": "AppButtonSize.medium",\n  "text": "Beveled",\n  "icon": "Icons.crop_16_9",\n  "style": "OutlinedButton.styleFrom(BeveledRectangleBorder(10))",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppButtonType.filled",\n  "size": "AppButtonSize.medium",\n  "text": "Continuous Rectangle Shape",\n  "icon": "Icons.hexagon_outlined",\n  "style": "FilledButton.styleFrom(ContinuousRectangleBorder(28))",\n  "onPressed": "() {}"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "type": "AppSegmentedButton<String>",\n  "size": "AppButtonSize.medium",\n  "segments": [ButtonSegment<String>],\n  "selected": _selectedSegment,\n  "onSelectionChanged": "(value) { ... }"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "widget": "AppSplitButton<String>",\n  "size": "AppButtonSize.large",\n  "text": "Add to cart",\n  "icon": "Icons.shopping_cart_outlined",\n  "onPressed": "() { setState(() { _lastSplitAction = default; }) }",\n  "items": "[AppSplitButtonItem(save, wishlist, gift)]",\n  "onSelected": "(value) { setState(() { _lastSplitAction = value; }) }"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
                    ),
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
                  Text('Contoh Pengisian (JSON):',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        '{\n  "widget": "AppFabMenu",\n  "size": "AppButtonSize.small",\n  "items": "[AppFabMenuItem(First, Second, Third)]",\n  "note": "Expandable FAB with labeled action items"\n}',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF333333)),
                      ),
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
