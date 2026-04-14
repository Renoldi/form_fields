import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';

import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  String _keyboardTestValue = '';

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
