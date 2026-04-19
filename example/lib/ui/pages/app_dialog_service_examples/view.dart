import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';

import 'dart:convert';

import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  // Helper to pretty print JSON
  String _prettyPrintJson(Map<String, dynamic> json) {
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  // Widget to display JSON example
  Widget _buildJsonExample(Map<String, dynamic> json) {
    final prettyJson = _prettyPrintJson(json);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          prettyJson,
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 12, color: Color(0xFF333333)),
        ),
      ),
    );
  }

  // Widget for options card (segmented buttons)
  Widget _buildOptionsCard(BuildContext context, ViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loading Back Behavior'),
            const SizedBox(height: 8),
            SegmentedButton<AppDialogLoadingBackBehavior>(
              segments: [
                ButtonSegment(
                    value: AppDialogLoadingBackBehavior.block,
                    label: Text('Block')),
                ButtonSegment(
                    value: AppDialogLoadingBackBehavior.allow,
                    label: Text('Allow')),
                ButtonSegment(
                    value: AppDialogLoadingBackBehavior.confirmCancel,
                    label: Text('Confirm Cancel')),
              ],
              selected: {vm.loadingBackBehavior},
              onSelectionChanged: (set) => vm.setLoadingBackBehavior(set.first),
            ),
            const SizedBox(height: 10),
            Text('Loading Dialog Position'),
            const SizedBox(height: 8),
            SegmentedButton<AppDialogLoadingContainer>(
              segments: [
                ButtonSegment(
                    value: AppDialogLoadingContainer.card, label: Text('Card')),
                ButtonSegment(
                    value: AppDialogLoadingContainer.nonCard,
                    label: Text('Non-Card')),
              ],
              selected: {vm.loadingContainer},
              onSelectionChanged: (set) => vm.setLoadingContainer(set.first),
            ),
            const SizedBox(height: 10),
            Text('Loading Dialog Position'),
            const SizedBox(height: 8),
            SegmentedButton<AppDialogPosition>(
              segments: [
                ButtonSegment(value: AppDialogPosition.top, label: Text('Top')),
                ButtonSegment(
                    value: AppDialogPosition.center, label: Text('Center')),
                ButtonSegment(
                    value: AppDialogPosition.bottom, label: Text('Bottom')),
              ],
              selected: {vm.loadingPosition},
              onSelectionChanged: (set) => vm.setLoadingPosition(set.first),
            ),
            const SizedBox(height: 10),
            Text('Result Dialog Position'),
            const SizedBox(height: 8),
            SegmentedButton<AppDialogPosition>(
              segments: [
                ButtonSegment(value: AppDialogPosition.top, label: Text('Top')),
                ButtonSegment(
                    value: AppDialogPosition.center, label: Text('Center')),
                ButtonSegment(
                    value: AppDialogPosition.bottom, label: Text('Bottom')),
              ],
              selected: {vm.resultPosition},
              onSelectionChanged: (set) => vm.setResultPosition(set.first),
            ),
            const SizedBox(height: 10),
            Text('Loading Visual'),
            const SizedBox(height: 8),
            SegmentedButton<AppDialogLoadingVisual>(
              segments: [
                ButtonSegment(
                    value: AppDialogLoadingVisual.indicator,
                    label: Text('Indicator')),
                ButtonSegment(
                    value: AppDialogLoadingVisual.progress,
                    label: Text('Progress')),
              ],
              selected: {vm.loadingVisual},
              onSelectionChanged: (set) => vm.setLoadingVisual(set.first),
            ),
            if (vm.loadingVisual == AppDialogLoadingVisual.indicator) ...[
              const SizedBox(height: 8),
              SegmentedButton<AppLoadingVariant>(
                segments: [
                  ButtonSegment(
                      value: AppLoadingVariant.spinner, label: Text('Spinner')),
                  ButtonSegment(
                      value: AppLoadingVariant.pulse, label: Text('Pulse')),
                  ButtonSegment(
                      value: AppLoadingVariant.dots, label: Text('Dots')),
                ],
                selected: {vm.loadingVariant},
                onSelectionChanged: (set) => vm.setLoadingVariant(set.first),
              ),
            ],
            if (vm.loadingVisual == AppDialogLoadingVisual.progress) ...[
              const SizedBox(height: 8),
              SegmentedButton<AppProgressType>(
                segments: [
                  ButtonSegment(
                      value: AppProgressType.circular, label: Text('Circular')),
                  ButtonSegment(
                      value: AppProgressType.linear, label: Text('Linear')),
                ],
                selected: {vm.progressType},
                onSelectionChanged: (set) => vm.setProgressType(set.first),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewModel>(
      builder: (context, vm, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'App Dialog Service',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Contoh penggunaan AppDialogService',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildOptionsCard(context, vm),
            const SizedBox(height: 16),
            buildActions(context, vm),
          ],
        );
      },
    );
  }

  Widget buildActions(BuildContext context, ViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show text Loading
            AppButton(
              type: AppButtonType.filled,
              text: 'Show text Loading',
              onPressed: () async {
                await AppDialogService(context).showLoading(
                  loadingContainer: vm.loadingContainer,
                  loadingVisual: vm.loadingVisual,
                  loadingVariant: vm.loadingVariant,
                  progressType: vm.progressType,
                  position: vm.loadingPosition,
                  loadingBackBehavior: vm.loadingBackBehavior,
                );
              },
            ),
            const SizedBox(height: 8),
            _buildJsonExample({
              "type": "AppButtonType.filled",
              "text": "Show text Loading",
              "onPressed":
                  "showLoading(loadingContainer, loadingVisual, loadingVariant, progressType, position, loadingBackBehavior)"
            }),
            const SizedBox(height: 16),
            // Show Loading
            AppButton(
              type: AppButtonType.filled,
              text: 'Show Loading',
              onPressed: () async {
                await AppDialogService(context).showLoading(
                  message: "",
                  loadingContainer: vm.loadingContainer,
                  loadingVisual: vm.loadingVisual,
                  loadingVariant: vm.loadingVariant,
                  progressType: vm.progressType,
                  position: vm.loadingPosition,
                  loadingBackBehavior: vm.loadingBackBehavior,
                );
              },
            ),
            const SizedBox(height: 8),
            _buildJsonExample({
              "type": "AppButtonType.filled",
              "text": "Show Loading",
              "onPressed":
                  "showLoading(message, loadingContainer, loadingVisual, loadingVariant, progressType, position, loadingBackBehavior)"
            }),
            const SizedBox(height: 16),
            // Success
            AppButton(
              type: AppButtonType.filled,
              text: 'Success',
              onPressed: () async {
                await AppDialogService(context).guard(
                  task: () async {
                    await Future.delayed(const Duration(seconds: 2));
                    return 'Success';
                  },
                  errorTitle: 'Error',
                  mapError: AppDialogService.defaultErrorMapper,
                  loadingPosition: vm.loadingPosition,
                  resultPosition: vm.resultPosition,
                  showBlockingLoading: true,
                  loadingMessage: 'Processing...',
                  loadingVisual: vm.loadingVisual,
                  loadingVariant: vm.loadingVariant,
                  progressType: vm.progressType,
                  loadingBackBehavior: vm.loadingBackBehavior,
                  showSuccessDialog: true,
                  successTitle: 'Success',
                  successMessage: 'Task completed successfully!',
                );
              },
            ),
            const SizedBox(height: 8),
            _buildJsonExample({
              "type": "AppButtonType.filled",
              "text": "Success",
              "onPressed":
                  "guard(task, errorTitle, mapError, loadingPosition, resultPosition, showBlockingLoading, loadingMessage, loadingVisual, loadingVariant, progressType, loadingBackBehavior, showSuccessDialog, successTitle, successMessage)"
            }),
            const SizedBox(height: 16),
            // Error
            AppButton(
              type: AppButtonType.filled,
              text: 'Error',
              onPressed: () async {
                await AppDialogService(context).guard(
                  task: () async {
                    await Future.delayed(const Duration(seconds: 2));
                    throw Exception('Simulated failure');
                  },
                  errorTitle: 'Error',
                  mapError: AppDialogService.defaultErrorMapper,
                  loadingPosition: vm.loadingPosition,
                  resultPosition: vm.resultPosition,
                  showBlockingLoading: true,
                  loadingMessage: 'Processing...',
                  loadingVisual: vm.loadingVisual,
                  loadingVariant: vm.loadingVariant,
                  progressType: vm.progressType,
                  loadingBackBehavior: vm.loadingBackBehavior,
                  showSuccessDialog: false,
                );
              },
            ),
            const SizedBox(height: 8),
            _buildJsonExample({
              "type": "AppButtonType.filled",
              "text": "Error",
              "onPressed":
                  "guard(task, errorTitle, mapError, loadingPosition, resultPosition, showBlockingLoading, loadingMessage, loadingVisual, loadingVariant, progressType, loadingBackBehavior, showSuccessDialog)"
            }),
            const SizedBox(height: 16),
            // Warning
            AppButton(
              type: AppButtonType.filled,
              text: 'Warning',
              onPressed: () async {
                await AppDialogService(context).guard(
                  task: () async {
                    await Future.delayed(const Duration(seconds: 2));
                    throw ValidationException(
                        'Simulated validation warning: Please fill all required fields.');
                  },
                  errorTitle: 'Warning',
                  mapError: AppDialogService.defaultErrorMapper,
                  loadingPosition: vm.loadingPosition,
                  resultPosition: vm.resultPosition,
                  showBlockingLoading: true,
                  loadingMessage: 'Processing...',
                  loadingVisual: vm.loadingVisual,
                  loadingVariant: vm.loadingVariant,
                  progressType: vm.progressType,
                  loadingBackBehavior: vm.loadingBackBehavior,
                  showSuccessDialog: false,
                );
              },
            ),
            const SizedBox(height: 8),
            _buildJsonExample({
              "type": "AppButtonType.filled",
              "text": "Warning",
              "onPressed":
                  "guard(task, errorTitle, mapError, loadingPosition, resultPosition, showBlockingLoading, loadingMessage, loadingVisual, loadingVariant, progressType, loadingBackBehavior, showSuccessDialog)"
            }),
          ],
        ),
      ),
    );
  }
}
