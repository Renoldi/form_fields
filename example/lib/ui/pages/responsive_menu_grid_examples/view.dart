import 'dart:math';

import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';

import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, Color color1, Color color2) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color1, color2]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  Widget _fieldTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 16,
              color: color,
              margin: const EdgeInsets.only(right: 8)),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _jsonBlock(String json) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          json,
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 12, color: Color(0xFF333333)),
        ),
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
            width: 120,
            child: Text('$label: ${value.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13))),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 4).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ── Grid item builders ────────────────────────────────────────────────────

  Widget _buildAppIcon(GridItemData item, ViewModel vm) {
    return GestureDetector(
      onTap: () => vm.tap(item.label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 30),
              ),
              if (item.badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(item.badge!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(GridItemData item, ViewModel vm) {
    return GestureDetector(
      onTap: () => vm.tap(item.label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: item.color.withValues(alpha: 0.1),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => vm.tap(item.label),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(child: Icon(item.icon, color: item.color, size: 30)),
                    if (item.badge != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(item.badge!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ViewModel>(
      builder: (context, vm, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section 1: Basic ────────────────────────────────────────
              _sectionTitle(
                  'Basic Usage', Colors.teal.shade700, Colors.teal.shade400),

              _fieldTitle('App Launcher Style (default)', Colors.teal.shade600),
              ResponsiveMenuGrid(
                itemSize: 80,
                widgets: ViewModel.sampleApps
                    .take(Random().nextInt(ViewModel.sampleApps.length - 3) + 3)
                    .map((item) => _buildAppIcon(item, vm))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text('Contoh Pengisian (JSON):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              _jsonBlock(
                '{\n'
                '  "widget": "ResponsiveMenuGrid",\n'
                '  "itemSize": 80,\n'
                '  "widgets": "[...list of Widget]"\n'
                '}',
              ),

              _fieldTitle('Menu Style (circle + badge)', Colors.teal.shade600),
              SizedBox(
                width: 340,
                child: ResponsiveMenuGrid(
                  itemSize: 100,
                  horizontalMargin: 8,
                  verticalSpacing: 24,
                  alignLeft: true,
                  widgets: ViewModel.sampleMenu
                      .map((item) => _buildMenuIcon(item, vm))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text('Contoh Pengisian (JSON):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              _jsonBlock(
                '{\n'
                '  "widget": "ResponsiveMenuGrid",\n'
                '  "itemSize": 100,\n'
                '  "horizontalMargin": 8,\n'
                '  "verticalSpacing": 24,\n'
                '  "alignLeft": true,\n'
                '  "widgets": "[...list of Widget]"\n'
                '}',
              ),

              // ── Section 2: Interactive ──────────────────────────────────
              _sectionTitle('Interactive Playground', Colors.indigo.shade700,
                  Colors.indigo.shade400),

              _fieldTitle('Adjust Parameters Live', Colors.indigo.shade600),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _sliderRow(
                        'itemSize', vm.itemSize, 60, 120, vm.updateItemSize),
                    _sliderRow('hMargin', vm.horizontalMargin, 0, 40,
                        vm.updateHorizontalMargin),
                    _sliderRow('vSpacing', vm.verticalSpacing, 0, 48,
                        vm.updateVerticalSpacing),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('alignLeft',
                          style: TextStyle(fontSize: 13)),
                      value: vm.alignLeft,
                      onChanged: vm.toggleAlignLeft,
                    ),
                  ],
                ),
              ),
              ResponsiveMenuGrid(
                itemSize: vm.itemSize,
                horizontalMargin: vm.horizontalMargin,
                verticalSpacing: vm.verticalSpacing,
                alignLeft: vm.alignLeft,
                widgets: ViewModel.sampleApps
                    .map((item) => _buildAppIcon(item, vm))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text('Contoh Pengisian (JSON):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              _jsonBlock(
                '{\n'
                '  "widget": "ResponsiveMenuGrid",\n'
                '  "itemSize": ${vm.itemSize.toStringAsFixed(0)},\n'
                '  "horizontalMargin": ${vm.horizontalMargin.toStringAsFixed(0)},\n'
                '  "verticalSpacing": ${vm.verticalSpacing.toStringAsFixed(0)},\n'
                '  "alignLeft": ${vm.alignLeft},\n'
                '  "widgets": "[...list of Widget]"\n'
                '}',
              ),
              if (vm.lastTapped != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Last tapped: ${vm.lastTapped}',
                      style: const TextStyle(color: Colors.green)),
                ),

              // ── Section 3: Edge cases ───────────────────────────────────
              _sectionTitle(
                  'Edge Cases', Colors.purple.shade700, Colors.purple.shade400),

              _fieldTitle('Single Item', Colors.purple.shade600),
              ResponsiveMenuGrid(
                itemSize: 80,
                widgets: [_buildAppIcon(ViewModel.sampleApps[0], vm)],
              ),
              const SizedBox(height: 8),
              Text('Contoh Pengisian (JSON):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              _jsonBlock(
                '{\n'
                '  "widget": "ResponsiveMenuGrid",\n'
                '  "itemSize": 80,\n'
                '  "widgets": "[Widget]"  // single item\n'
                '}',
              ),

              _fieldTitle('Large itemSize (fills fewer columns)',
                  Colors.purple.shade600),
              ResponsiveMenuGrid(
                itemSize: 120,
                horizontalMargin: 8,
                verticalSpacing: 20,
                widgets: ViewModel.sampleApps
                    .take(6)
                    .map((item) => _buildAppIcon(item, vm))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text('Contoh Pengisian (JSON):',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              _jsonBlock(
                '{\n'
                '  "widget": "ResponsiveMenuGrid",\n'
                '  "itemSize": 120,\n'
                '  "horizontalMargin": 8,\n'
                '  "verticalSpacing": 20,\n'
                '  "widgets": "[...6 items]"\n'
                '}',
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
