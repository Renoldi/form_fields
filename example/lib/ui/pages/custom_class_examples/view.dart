import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart' as loc;
import 'package:form_fields_example/ui/widgets/result_display_widget.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomClassExamplesViewModel(),
      child: Consumer<CustomClassExamplesViewModel>(
        builder: (context, viewModel, _) {
          loc.Localizations.of(context);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: viewModel.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade700, Colors.teal.shade400],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.class_, size: 48, color: Colors.white),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('ccHeaderTitle'),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr('ccHeaderSubtitle'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Example 1: Dropdown with Custom Class
                  buildSectionTitle(context.tr('ccSectionDropdownCustomClass'),
                      Colors.teal.shade700, Colors.teal.shade400),
                  buildFieldTitle(
                      context.tr('ccFieldCountryFlag'), Colors.teal.shade600),
                  FormFieldsDropdown<Country>(
                    label: context.tr('ccSelectCountry'),
                    items: viewModel.countries,
                    initialValue: viewModel.selectedCountry,
                    isRequired: true,
                    itemLabelBuilder: (country) =>
                        '${country.flag} ${country.name}',
                    onChanged: viewModel.setSelectedCountry,
                  ),
                  buildResultDisplay(context, context.tr('ccSelectedCountry'),
                      viewModel.selectedCountry),

                  const SizedBox(height: 16),

                  if (viewModel.selectedCountry != null)
                    _buildInfoCard(
                      'Selected Country',
                      'Code: ${viewModel.selectedCountry!.code}\n'
                          'Name: ${viewModel.selectedCountry!.name}\n'
                          'Flag: ${viewModel.selectedCountry!.flag}',
                      Colors.blue.shade50,
                    ),
                  const SizedBox(height: 32),

                  // Example 2: Multi-Select Dropdown with Custom Class
                  buildSectionTitle(
                      context.tr('ccSectionMultiSelectCustomClass'),
                      Colors.teal.shade700,
                      Colors.teal.shade400),
                  buildFieldTitle(context.tr('ccFieldSkillsCategories'),
                      Colors.teal.shade600),
                  FormFieldsDropdownMulti<Skill>(
                    label: context.tr('ccSelectSkills'),
                    items: viewModel.skills,
                    initialValues: viewModel.selectedSkills,
                    isRequired: true,
                    minSelections: 2,
                    maxSelections: 5,
                    itemLabelBuilder: (skill) =>
                        '${skill.name} (${skill.category})',
                    chipBackgroundColor: Colors.teal.shade100,
                    chipTextColor: Colors.teal.shade900,
                    chipDeleteIconColor: Colors.teal.shade700,
                    showItemCount: true,
                    onChanged: viewModel.setSelectedSkills,
                  ),
                  buildResultDisplay(context, context.tr('ccSelectedSkills'),
                      viewModel.selectedSkills),

                  const SizedBox(height: 16),

                  if (viewModel.selectedSkills.isNotEmpty)
                    _buildInfoCard(
                      'Selected Skills (${viewModel.selectedSkills.length})',
                      viewModel.selectedSkills
                          .map((s) => '• ${s.name} - ${s.category}')
                          .join('\n'),
                      Colors.teal.shade50,
                    ),

                  const SizedBox(height: 32),

                  // Example 3: Radio Button with Custom Class
                  buildSectionTitle(context.tr('ccSectionRadioCustomClass'),
                      Colors.teal.shade700, Colors.teal.shade400),
                  buildFieldTitle(
                      context.tr('ccFieldPlanSelection'), Colors.teal.shade600),
                  FormFieldsRadioButton<SubscriptionPlan>(
                    label: context.tr('ccSelectPlan'),
                    items: viewModel.plans,
                    initialValue: viewModel.selectedPlan,
                    isRequired: true,
                    direction: Axis.vertical,
                    indicatorVerticalAlignment:
                        IndicatorVerticalAlignment.center,
                    activeColor: Colors.purple,
                    itemLabelBuilder: (plan) =>
                        '${plan.name} - \$${plan.price}/month',
                    itemBuilder: (plan, selected) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.purple.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                selected ? Colors.purple : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      selected ? Colors.purple : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${plan.price}/month',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: selected
                                      ? Colors.purple.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plan.features,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onChanged: viewModel.setSelectedPlan,
                  ),
                  buildResultDisplay(context, context.tr('ccSelectedPlan'),
                      viewModel.selectedPlan),

                  const SizedBox(height: 16),

                  if (viewModel.selectedPlan != null)
                    _buildInfoCard(
                      'Selected Plan',
                      'Plan: ${viewModel.selectedPlan!.name}\n'
                          'Price: \$${viewModel.selectedPlan!.price}/month\n'
                          'Features: ${viewModel.selectedPlan!.features}',
                      Colors.purple.shade50,
                    ),

                  const SizedBox(height: 32),

                  // Example 4: Checkbox with Custom Class
                  buildSectionTitle(context.tr('ccSectionCheckboxCustomClass'),
                      Colors.teal.shade700, Colors.teal.shade400),
                  buildFieldTitle(context.tr('ccFieldInterestsSelection'),
                      Colors.teal.shade600),
                  FormFieldsCheckbox<Interest>(
                    label: context.tr('ccSelectInterests'),
                    items: viewModel.interests,
                    initialValue: viewModel.selectedInterests,
                    isRequired: false,
                    direction: Axis.vertical,
                    indicatorVerticalAlignment:
                        IndicatorVerticalAlignment.center,
                    activeColor: Colors.green,
                    itemBuilder: (interest, selected) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? interest.color.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? interest.color
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: interest.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              interest.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    selected ? interest.color : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onChanged: viewModel.setSelectedInterests,
                  ),
                  buildResultDisplay(context, context.tr('ccSelectedInterests'),
                      viewModel.selectedInterests),

                  const SizedBox(height: 16),

                  if (viewModel.selectedInterests.isNotEmpty)
                    _buildInfoCard(
                      'Selected Interests (${viewModel.selectedInterests.length})',
                      viewModel.selectedInterests
                          .map((i) => '• ${i.name}')
                          .join('\n'),
                      Colors.green.shade50,
                    ),

                  const SizedBox(height: 32),

                  // Example 5: Dropdown with Filter and Custom Class
                  buildSectionTitle(
                      context.tr('ccSectionDropdownFilterCustomClass'),
                      Colors.teal.shade700,
                      Colors.teal.shade400),
                  buildFieldTitle(context.tr('ccFieldCountrySearchFilter'),
                      Colors.teal.shade600),
                  FormFieldsDropdown<Country>(
                    label: context.tr('ccSelectCountryFilter'),
                    items: viewModel.countries,
                    initialValue: viewModel.selectedCountryWithFilter,
                    isRequired: true,
                    enableFilter: true,
                    filterHintText: context.tr('ccSearchCountriesHint'),
                    itemLabelBuilder: (country) =>
                        '${country.flag} ${country.name}',
                    borderColor: Colors.orange,
                    focusedBorderColor: Colors.orange.shade700,
                    onChanged: viewModel.setSelectedCountryWithFilter,
                  ),
                  buildResultDisplay(
                      context,
                      context.tr('ccSelectedCountryFiltered'),
                      viewModel.selectedCountryWithFilter),

                  const SizedBox(height: 16),

                  if (viewModel.selectedCountryWithFilter != null)
                    _buildInfoCard(
                      'Selected Country Details',
                      'Code: ${viewModel.selectedCountryWithFilter!.code}\n'
                          'Name: ${viewModel.selectedCountryWithFilter!.name}\n'
                          'Flag: ${viewModel.selectedCountryWithFilter!.flag}',
                      Colors.orange.shade50,
                    ),

                  const SizedBox(height: 32),

                  // Example 6: Multi-Select Dropdown with Filter and Custom Class
                  buildSectionTitle(
                      context.tr('ccSectionMultiSelectFilterCustomClass'),
                      Colors.teal.shade700,
                      Colors.teal.shade400),
                  buildFieldTitle(context.tr('ccFieldSkillsSearchFilter'),
                      Colors.teal.shade600),
                  FormFieldsDropdownMulti<Skill>(
                    label: context.tr('ccSelectSkillsFilter'),
                    items: viewModel.skills,
                    initialValues: viewModel.selectedSkillsWithFilter,
                    isRequired: false,
                    enableFilter: true,
                    filterHintText: context.tr('ccSearchSkillsHint'),
                    itemLabelBuilder: (skill) =>
                        '${skill.name} (${skill.category})',
                    chipBackgroundColor: Colors.indigo.shade100,
                    chipTextColor: Colors.indigo.shade900,
                    chipDeleteIconColor: Colors.indigo.shade700,
                    showItemCount: true,
                    onChanged: viewModel.setSelectedSkillsWithFilter,
                  ),
                  buildResultDisplay(
                      context,
                      context.tr('ccSelectedSkillsFiltered'),
                      viewModel.selectedSkillsWithFilter),

                  const SizedBox(height: 16),

                  if (viewModel.selectedSkillsWithFilter.isNotEmpty)
                    _buildInfoCard(
                      'Selected Skills Details (${viewModel.selectedSkillsWithFilter.length})',
                      viewModel.selectedSkillsWithFilter
                          .map((s) => '• ${s.name} - ${s.category}')
                          .join('\n'),
                      Colors.indigo.shade50,
                    ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (viewModel.formKey.currentState!.validate()) {
                          _showFormData(context, viewModel);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        context.tr('validateFormButton'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, Color backgroundColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: backgroundColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showFormData(
    BuildContext context,
    CustomClassExamplesViewModel viewModel,
  ) {
    loc.Localizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr('ccFormValidated'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );

    viewModel.logFormData();
  }
}
