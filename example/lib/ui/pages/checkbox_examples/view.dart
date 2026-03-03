import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/localization/localizations.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/ui/widgets/result_display_widget.dart';
import 'presenter.dart';
import 'view_model.dart';

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return Consumer<ViewModel>(
      builder: (context, viewModel, _) {
        return Form(
          key: viewModel.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle(context.tr('cbBasicExamples'),
                    Colors.pink.shade700, Colors.pink.shade400),

                // Example 1: Single Selection - Vertical
                buildFieldTitle(
                    context.tr('cbSingleVertical'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbTermsConditions'),
                  initialValue: viewModel.checkbox1,
                  items: [context.tr('iAgreeTerms')],
                  isRequired: true,
                  direction: Axis.vertical,
                  indicatorVerticalAlignment: IndicatorVerticalAlignment.top,
                  onChanged: viewModel.setCheckbox1,
                ),
                buildResultDisplay(
                    context, context.tr('cbTermsAgreed'), viewModel.checkbox1),

                // Example 2: Single Selection - Horizontal
                buildFieldTitle(
                    context.tr('cbSingleHorizontal'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbNewsletter'),
                  initialValue: viewModel.checkbox2,
                  items: [context.tr('cbSubscribeWeekly')],
                  isRequired: false,
                  direction: Axis.horizontal,
                  horizontalSideBySide: true,
                  borderColor: Colors.blue,
                  activeColor: Colors.blue,
                  onChanged: viewModel.setCheckbox2,
                ),
                buildResultDisplay(context, context.tr('cbNewsletterResult'),
                    viewModel.checkbox2),

                buildSectionTitle(context.tr('cbMultipleSelection'),
                    Colors.pink.shade700, Colors.pink.shade400),

                // Example 3: Multiple Selection - Vertical
                buildFieldTitle(
                    context.tr('cbMultipleVertical'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbHobbies'),
                  initialValue: viewModel.checkbox3,
                  items: const [
                    'Reading',
                    'Gaming',
                    'Sports',
                    'Cooking',
                    'Traveling',
                    'Photography',
                    'Music',
                    'Art & Crafts',
                    'Dancing',
                    'Yoga',
                    'Meditation',
                    'Gardening',
                    'Fishing',
                    'Hiking',
                    'Cycling',
                    'Swimming',
                    'Writing',
                    'Blogging',
                    'Painting',
                    'Drawing',
                    'Singing',
                    'Playing Instruments',
                    'Bird Watching',
                    'Astronomy',
                    'Volunteering',
                  ],
                  isRequired: true,
                  direction: Axis.vertical,
                  horizontalSideBySide: true,
                  onChanged: viewModel.setCheckbox3,
                ),
                buildResultDisplay(context, context.tr('cbSelectedHobbies'),
                    viewModel.checkbox3),

                // Example 4: Multiple Selection - Horizontal
                buildFieldTitle(
                    context.tr('cbMultipleHorizontal'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbLanguages'),
                  initialValue: viewModel.checkbox4,
                  items: const [
                    'Dart',
                    'JavaScript',
                    'Python',
                    'Java',
                    'C++',
                    'TypeScript',
                    'Go',
                    'Rust',
                    'Kotlin',
                    'Swift',
                    'C#',
                    'PHP',
                    'Ruby',
                    'Scala',
                    'R',
                    'MATLAB',
                    'Perl',
                    'Haskell',
                    'Lua',
                    'Elixir',
                    'Clojure'
                  ],
                  isRequired: true,
                  direction: Axis.horizontal,
                  horizontalSideBySide: true,
                  borderColor: Colors.teal,
                  activeColor: Colors.teal,
                  onChanged: viewModel.setCheckbox4,
                ),
                buildResultDisplay(context, context.tr('cbSelectedLanguages'),
                    viewModel.checkbox4),

                buildSectionTitle(context.tr('cbCustomStyling'),
                    Colors.pink.shade700, Colors.pink.shade400),

                // Example 5: Custom Border & Colors
                buildFieldTitle(
                    context.tr('cbCustomBorder'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbSkills'),
                  initialValue: viewModel.checkbox5,
                  items: const [
                    'Leadership',
                    'Communication',
                    'Problem Solving',
                    'Time Management',
                    'Teamwork',
                    'Critical Thinking',
                    'Creativity',
                    'Adaptability',
                    'Decision Making',
                    'Conflict Resolution',
                    'Negotiation',
                    'Project Management',
                    'Strategic Planning',
                    'Public Speaking',
                    'Active Listening',
                    'Emotional Intelligence',
                    'Customer Service',
                    'Sales',
                    'Marketing',
                    'Data Analysis',
                    'Research',
                    'Technical Writing',
                    'Mentoring',
                    'Coaching',
                    'Delegation',
                  ],
                  isRequired: true,
                  direction: Axis.vertical,
                  borderColor: Colors.purple,
                  errorBorderColor: Colors.red.shade700,
                  activeColor: Colors.purple,
                  radius: 15,
                  itemBorderColor: Colors.purple.shade300,
                  itemBorderWidth: 1.5,
                  itemBorderRadius: 10,
                  indicatorVerticalAlignment: IndicatorVerticalAlignment.center,
                  onChanged: viewModel.setCheckbox5,
                ),
                buildResultDisplay(context, context.tr('cbSelectedSkills'),
                    viewModel.checkbox5),

                // Example 6: Custom Item Padding
                buildFieldTitle(
                    context.tr('cbCustomPadding'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbContactMethods'),
                  initialValue: viewModel.checkbox6,
                  items: const ['Email', 'Phone', 'SMS', 'WhatsApp'],
                  isRequired: false,
                  direction: Axis.vertical,
                  borderColor: Colors.orange,
                  activeColor: Colors.orange,
                  itemBorderColor: Colors.orange.shade300,
                  itemBorderWidth: 1.25,
                  itemBorderRadius: 8,
                  itemPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  onChanged: viewModel.setCheckbox6,
                ),
                buildResultDisplay(context, context.tr('cbContactMethods'),
                    viewModel.checkbox6),

                buildSectionTitle(context.tr('cbLayoutVariations'),
                    Colors.pink.shade700, Colors.pink.shade400),

                // Example 7: Horizontal Layout
                buildFieldTitle(
                    context.tr('cbHorizontalLayout'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbDaysOfWeek'),
                  initialValue: viewModel.checkbox7,
                  items: const [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ],
                  isRequired: true,
                  direction: Axis.horizontal,
                  horizontalSideBySide: true,
                  borderColor: Colors.indigo,
                  activeColor: Colors.indigo,
                  itemBorderColor: Colors.indigo.shade300,
                  itemBorderWidth: 1.25,
                  itemBorderRadius: 8,
                  textRightPadding: 8,
                  itemMarginTop: 6,
                  itemMarginBottom: 6,
                  itemMarginHorizontal: 4,
                  onChanged: viewModel.setCheckbox7,
                ),
                buildResultDisplay(
                    context, context.tr('cbSelectedDays'), viewModel.checkbox7),

                // Example 8: Vertical Layout with Custom Colors
                buildFieldTitle(
                    context.tr('cbVerticalLayout'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbFeatures'),
                  initialValue: viewModel.checkbox8,
                  items: const ['WiFi', 'Parking', 'Gym', 'Pool'],
                  isRequired: false,
                  direction: Axis.vertical,
                  borderColor: Colors.cyan,
                  activeColor: Colors.cyan,
                  indicatorVerticalAlignment: IndicatorVerticalAlignment.bottom,
                  onChanged: viewModel.setCheckbox8,
                ),
                buildResultDisplay(context, context.tr('cbSelectedFeatures'),
                    viewModel.checkbox8),

                buildSectionTitle(context.tr('cbAdvancedFeatures'),
                    Colors.pink.shade700, Colors.pink.shade400),

                // Example 9: Custom Validation
                buildFieldTitle(
                    context.tr('cbCustomValidation'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbRestrictedMinOptions'),
                  initialValue: viewModel.checkbox3,
                  items: const ['Option A', 'Option B', 'Option C', 'Option D'],
                  isRequired: true,
                  direction: Axis.vertical,
                  borderColor: Colors.red,
                  activeColor: Colors.red,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('cbMinSelections');
                    }
                    if (value.length < 2) {
                      return context.tr('cbMinSelections');
                    }
                    return null;
                  },
                  onChanged: viewModel.setCheckbox3,
                ),
                buildResultDisplay(
                    context,
                    context.tr('cbCustomValidationResult'),
                    viewModel.checkbox3),

                // Example 10: Custom Styling
                buildFieldTitle(
                    context.tr('cbCustomPadding'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbDietaryRestrictions'),
                  initialValue: viewModel.checkbox4,
                  items: const [
                    'Vegetarian',
                    'Vegan',
                    'Gluten-Free',
                    'Dairy-Free',
                    'Nut Allergy',
                    'Shellfish Allergy',
                    'Egg Allergy',
                    'Soy Allergy',
                    'Lactose Intolerant',
                    'Kosher',
                    'Halal',
                    'Pescatarian',
                    'Raw Food',
                    'Keto',
                    'Paleo',
                    'Low Carb',
                    'Low Sodium',
                    'Low Sugar',
                    'Diabetic',
                    'Heart Healthy',
                    'No Preservatives',
                    'Organic Only',
                    'No Artificial Colors',
                    'No MSG',
                    'No GMO',
                  ],
                  isRequired: false,
                  direction: Axis.vertical,
                  borderColor: Colors.green,
                  activeColor: Colors.green,
                  itemPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  onChanged: viewModel.setCheckbox4,
                ),
                buildResultDisplay(context, context.tr('cbDietaryRestrictions'),
                    viewModel.checkbox4),

                // Example 11: Horizontal Layout with Custom Border
                buildFieldTitle(
                    context.tr('cbNotificationsLayout'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbNotifications'),
                  initialValue: viewModel.checkbox5,
                  items: const ['Push', 'Email', 'SMS', 'In-App'],
                  isRequired: false,
                  direction: Axis.horizontal,
                  horizontalSideBySide: true,
                  borderColor: Colors.deepPurple,
                  activeColor: Colors.deepPurple,
                  itemBorderColor: Colors.deepPurple.shade300,
                  itemBorderWidth: 1.25,
                  itemBorderRadius: 8,
                  textRightPadding: 8,
                  itemMarginBottom: 8,
                  itemMarginHorizontal: 4,
                  onChanged: viewModel.setCheckbox5,
                ),
                buildResultDisplay(context, context.tr('cbNotifications'),
                    viewModel.checkbox5),

                // Example 12: Many Options
                buildFieldTitle(context.tr('cbManyOptionsScrollable'),
                    Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbCountriesVisited'),
                  initialValue: viewModel.checkbox6,
                  items: const [
                    'United States',
                    'United Kingdom',
                    'Canada',
                    'Australia',
                    'Germany',
                    'France',
                    'Japan',
                    'China',
                    'India',
                    'Brazil',
                    'Mexico',
                    'Italy',
                    'Spain',
                    'Russia',
                    'South Korea',
                    'Argentina',
                    'Netherlands',
                    'Sweden',
                    'Switzerland',
                    'Belgium',
                    'Poland',
                    'Norway',
                    'Austria',
                    'Denmark',
                    'Finland',
                    'Ireland',
                    'Portugal',
                    'Greece',
                    'New Zealand',
                    'Singapore',
                  ],
                  isRequired: false,
                  direction: Axis.vertical,
                  borderColor: Colors.amber,
                  activeColor: Colors.amber,
                  itemPadding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  onChanged: viewModel.setCheckbox6,
                ),
                buildResultDisplay(
                    context,
                    context.tr('cbSelectedCountriesVisited'),
                    viewModel.checkbox6),

                buildSectionTitle(context.tr('cbLabelPositions'),
                    Colors.pink.shade700, Colors.pink.shade400),

                // Example 13: Label Position - Bottom
                buildFieldTitle(
                    context.tr('cbLabelBottom'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbPreferences'),
                  initialValue: viewModel.checkbox9,
                  items: const ['Dark Mode', 'Notifications', 'Analytics'],
                  isRequired: false,
                  direction: Axis.vertical,
                  borderColor: Colors.blue,
                  activeColor: Colors.blue,
                  labelPosition: LabelPosition.bottom,
                  containerGap: 12,
                  onChanged: viewModel.setCheckbox9,
                ),
                buildResultDisplay(
                    context, context.tr('cbPreferences'), viewModel.checkbox9),

                // Example 14: Label Position - Left
                buildFieldTitle(
                    context.tr('cbLabelLeft'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbPermissions'),
                  initialValue: viewModel.checkbox10,
                  items: const ['Read', 'Write', 'Delete', 'Admin'],
                  isRequired: false,
                  direction: Axis.vertical,
                  borderColor: Colors.green,
                  activeColor: Colors.green,
                  labelPosition: LabelPosition.left,
                  containerGap: 16,
                  onChanged: viewModel.setCheckbox10,
                ),
                buildResultDisplay(
                    context, context.tr('cbPermissions'), viewModel.checkbox10),

                const SizedBox(height: 32),

                // Submit Button

                // Example 15: Label Position - Top (Default)
                buildFieldTitle(context.tr('cbLabelTop'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbNotifications'),
                  initialValue: viewModel.checkbox11,
                  items: const ['Email', 'SMS', 'Push'],
                  isRequired: false,
                  direction: Axis.vertical,
                  borderColor: Colors.purple,
                  activeColor: Colors.purple,
                  labelPosition: LabelPosition.top,
                  containerGap: 8,
                  onChanged: viewModel.setCheckbox11,
                ),
                buildResultDisplay(context, context.tr('cbNotifications'),
                    viewModel.checkbox11),

                // Example 16: Label Position - Right
                buildFieldTitle(
                    context.tr('cbLabelRight'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbThemes'),
                  initialValue: viewModel.checkbox12,
                  items: const ['Light', 'Dark', 'Auto'],
                  isRequired: false,
                  direction: Axis.vertical,
                  borderColor: Colors.orange,
                  activeColor: Colors.orange,
                  labelPosition: LabelPosition.right,
                  containerGap: 16,
                  onChanged: viewModel.setCheckbox12,
                ),
                buildResultDisplay(
                    context, context.tr('cbThemes'), viewModel.checkbox12),

                // Example 17: Label Position - InBorder
                buildFieldTitle(
                    context.tr('cbLabelInBorder'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbFeatures'),
                  initialValue: viewModel.checkbox13,
                  items: const ['Feature A', 'Feature B', 'Feature C'],
                  isRequired: false,
                  direction: Axis.vertical,
                  borderColor: Colors.red,
                  activeColor: Colors.red,
                  labelPosition: LabelPosition.inBorder,
                  containerGap: 8,
                  onChanged: viewModel.setCheckbox13,
                ),
                buildResultDisplay(
                    context, context.tr('cbFeatures'), viewModel.checkbox13),

                // Example 18: Label Position - None
                buildFieldTitle(
                    context.tr('cbLabelNone'), Colors.pink.shade600),
                FormFieldsCheckbox<String>(
                  label: context.tr('cbOptions'),
                  initialValue: viewModel.checkbox14,
                  items: const ['Option 1', 'Option 2', 'Option 3'],
                  isRequired: false,
                  direction: Axis.vertical,
                  borderColor: Colors.teal,
                  activeColor: Colors.teal,
                  labelPosition: LabelPosition.none,
                  containerGap: 8,
                  onChanged: viewModel.setCheckbox14,
                ),
                buildResultDisplay(
                    context, context.tr('cbOptions'), viewModel.checkbox14),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => handleValidateForm(viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
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
    );
  }
}
