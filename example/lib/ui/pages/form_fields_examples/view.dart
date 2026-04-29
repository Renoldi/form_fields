import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_fields/form_fields.dart';
import 'package:form_fields_example/data/models/product.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:form_fields_example/localization/localizations.dart' as loc;
import 'package:form_fields_example/ui/widgets/result_display_widget.dart';
import 'package:form_fields_example/ui/widgets/language_indicator.dart';
import 'presenter.dart';
import 'view_model.dart';

final logger = Logger();

class View extends PresenterState {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FormFieldsExamplesViewModel(),
      child: Consumer<FormFieldsExamplesViewModel>(
        builder: (context, viewModel, _) {
          return Form(
            key: viewModel.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Language indicator showing current locale
                  const LanguageIndicator(),
                  buildSectionTitle(
                      'Scan Barcode', Colors.green, Colors.green.shade100),
                  FormFields<String>(
                    label: 'Scan Barcode',
                    formType: FormType.scanBarcode,
                    currentValue: viewModel.barcode ?? '',
                    isRequired: true,
                    onChanged: (value) {
                      viewModel.setBarcode(value);
                    },
                  ),
                  buildResultDisplay(
                      context, 'Barcode Result', viewModel.barcode),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Scan Barcode",\n'
                          '  "formType": "FormType.scanBarcode",\n'
                          '  "isRequired": true,\n'
                          "  \"currentValue\": \"viewModel.barcode ?? ''\",\n"
                          '  "onChanged": "viewModel.setBarcode(value)"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  buildSectionTitle('Autocomplete (Product Model)',
                      Colors.green, Colors.green.shade100),
                  FormFieldsAutocomplete<Product>(
                    fieldLabel: 'Product Autocomplete',
                    apiUrl: 'https://dummyjson.com/products/search',
                    searchKey: 'q',
                    parseResults: (data) {
                      if (data is Map && data['products'] is List) {
                        return (data['products'] as List)
                            .map((e) =>
                                Product.fromJson(e as Map<String, dynamic>))
                            .toList();
                      }
                      return [];
                    },
                    itemSelectedBuilder: (product) =>
                        product.title ??
                        product.brand ??
                        'Product #${product.id}',
                    onItemSelected: viewModel.updateSelectedProduct,
                    labelPlacement: LabelPosition.top,
                    itemBuilder: (item, selected) => ListTile(
                      title: Text(item.title ?? 'Product #${item.id}'),
                      subtitle: Text(item.brand ?? 'No brand'),
                      trailing: selected
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                    ),
                  ),
                  buildResultDisplay(
                      context, 'Selected Product', viewModel.selectedProduct),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "fieldLabel": "Product Autocomplete",\n'
                          '  "apiUrl": "https://dummyjson.com/products/search",\n'
                          '  "searchKey": "q",\n'
                          '  "parseResults": "(data) => ...",\n'
                          '  "itemSelectedBuilder": "(product) => ...",\n'
                          '  "onItemSelected": "viewModel.updateSelectedProduct",\n'
                          '  "labelPlacement": "LabelPosition.top",\n'
                          '  "itemBuilder": "(item, selected) => ..."\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  if (viewModel.selectedProduct != null)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selected Product:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green.shade900)),
                            const SizedBox(height: 8),
                            Text('Title: 9${viewModel.selectedProduct!.title}'),
                            Text('Brand: 9${viewModel.selectedProduct!.brand}'),
                            Text('Price: 9${viewModel.selectedProduct!.price}'),
                            Text(
                                'Category: ${viewModel.selectedProduct!.category}'),
                            if (viewModel.selectedProduct!.description != null)
                              Text(
                                  'Description: ${viewModel.selectedProduct!.description}'),
                          ],
                        ),
                      ),
                    ),

                  // ========== AUTOCOMPLETE PROPERTY DEMOS ==========
                  buildSectionTitle('Autocomplete (Custom Query Param)',
                      Colors.cyan, Colors.cyan.shade100),
                  FormFieldsAutocomplete<String>(
                    fieldLabel: 'Custom Query Param',
                    apiUrl: 'https://dummyjson.com/products/search',
                    searchKey: 'q',
                    parseResults: (data) {
                      if (data is Map && data['products'] is List) {
                        return (data['products'] as List)
                            .map((e) => e['title'].toString())
                            .toList();
                      }
                      return [];
                    },
                    onItemSelected:
                        viewModel.updateAutocompleteCustomQueryParamResult,
                    labelPlacement: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Custom Query Param Result',
                      viewModel.autocompleteCustomQueryParamResult),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "fieldLabel": "Custom Query Param",\n'
                          '  "apiUrl": "https://dummyjson.com/products/search",\n'
                          '  "searchKey": "q",\n'
                          '  "parseResults": "(data) => ...",\n'
                          '  "onItemSelected": "viewModel.updateAutocompleteCustomQueryParamResult",\n'
                          '  "labelPlacement": "LabelPosition.top"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  buildSectionTitle('Autocomplete (Token Auth)', Colors.red,
                      Colors.red.shade100),
                  FormFieldsAutocomplete<String>(
                    fieldLabel: 'Token Auth',
                    apiUrl: 'https://dummyjson.com/products/search',
                    searchKey: 'q',
                    apiToken: 'demo-token',
                    tokenHeaderName: 'X-Api-Key',
                    parseResults: (data) {
                      if (data is Map && data['products'] is List) {
                        return (data['products'] as List)
                            .map((e) => e['title'].toString())
                            .toList();
                      }
                      return [];
                    },
                    onItemSelected: viewModel.updateAutocompleteTokenResult,
                    labelPlacement: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Token Auth Result',
                      viewModel.autocompleteTokenResult),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "fieldLabel": "Token Auth",\n'
                          '  "apiUrl": "https://dummyjson.com/products/search",\n'
                          '  "searchKey": "q",\n'
                          '  "apiToken": "demo-token",\n'
                          '  "tokenHeaderName": "X-Api-Key",\n'
                          '  "parseResults": "(data) => ...",\n'
                          '  "onItemSelected": "viewModel.updateAutocompleteTokenResult",\n'
                          '  "labelPlacement": "LabelPosition.top"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  buildSectionTitle('Autocomplete (Custom Result Processor)',
                      Colors.deepOrange, Colors.deepOrange.shade100),
                  FormFieldsAutocomplete<String>(
                    fieldLabel: 'Custom Result Processor',
                    apiUrl: 'https://dummyjson.com/products/search',
                    parseResults: (data) {
                      if (data is Map && data['products'] is List) {
                        return (data['products'] as List)
                            .where(
                                (e) => e['title'].toString().contains('Phone'))
                            .map((e) => e['title'].toString())
                            .toList();
                      }
                      return [];
                    },
                    onItemSelected:
                        viewModel.updateAutocompleteCustomResultProcessorResult,
                    labelPlacement: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Custom Result Processor Result',
                      viewModel.autocompleteCustomResultProcessorResult),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "fieldLabel": "Custom Result Processor",\n'
                          '  "apiUrl": "https://dummyjson.com/products/search",\n'
                          '  "parseResults": "(data) => ...",\n'
                          '  "onItemSelected": "viewModel.updateAutocompleteCustomResultProcessorResult",\n'
                          '  "labelPlacement": "LabelPosition.top"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  buildSectionTitle('Autocomplete (Custom Decoration)',
                      Colors.pink, Colors.pink.shade100),
                  FormFieldsAutocomplete<String>(
                    fieldLabel: 'Custom Decoration',
                    apiUrl: 'https://dummyjson.com/products/search',
                    searchKey: 'q',
                    inputDecoration: InputDecoration(
                      hintText: 'Type to search...',
                      filled: true,
                      fillColor: Colors.pink.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onItemSelected:
                        viewModel.updateAutocompleteCustomDecorationResult,
                    labelPlacement: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Custom Decoration Result',
                      viewModel.autocompleteCustomDecorationResult),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "fieldLabel": "Custom Decoration",\n'
                          '  "apiUrl": "https://dummyjson.com/products/search",\n'
                          '  "searchKey": "q",\n'
                          '  "inputDecoration": "...",\n'
                          '  "onItemSelected": "viewModel.updateAutocompleteCustomDecorationResult",\n'
                          '  "labelPlacement": "LabelPosition.top"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  buildSectionTitle('Autocomplete (Suffix Icon)', Colors.amber,
                      Colors.amber.shade100),
                  FormFieldsAutocomplete<String>(
                    fieldLabel: 'Suffix Icon',
                    apiUrl: 'https://dummyjson.com/products/search',
                    searchKey: 'q',
                    trailingIcon: Icon(Icons.star, color: Colors.amber),
                    onItemSelected:
                        viewModel.updateAutocompleteSuffixIconResult,
                    labelPlacement: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Suffix Icon Result',
                      viewModel.autocompleteSuffixIconResult),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "fieldLabel": "Suffix Icon",\n'
                          '  "apiUrl": "https://dummyjson.com/products/search",\n'
                          '  "searchKey": "q",\n'
                          '  "trailingIcon": "Icon(Icons.star, color: Colors.amber)",\n'
                          '  "onItemSelected": "viewModel.updateAutocompleteSuffixIconResult",\n'
                          '  "labelPlacement": "LabelPosition.top"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  buildSectionTitle('Autocomplete (Remove Suffix Icon)',
                      Colors.lime, Colors.lime.shade100),
                  FormFieldsAutocomplete<String>(
                    fieldLabel: 'Remove Suffix Icon',
                    apiUrl: 'https://dummyjson.com/products/search',
                    searchKey: 'q',
                    hideTrailingIcon: true,
                    onItemSelected:
                        viewModel.updateAutocompleteRemoveSuffixIconResult,
                    labelPlacement: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Remove Suffix Icon Result',
                      viewModel.autocompleteRemoveSuffixIconResult),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "fieldLabel": "Remove Suffix Icon",\n'
                          '  "apiUrl": "https://dummyjson.com/products/search",\n'
                          '  "searchKey": "q",\n'
                          '  "hideTrailingIcon": true,\n'
                          '  "onItemSelected": "viewModel.updateAutocompleteRemoveSuffixIconResult",\n'
                          '  "labelPlacement": "LabelPosition.top"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "property1": "value1",\n'
                          '  "property2": "value2",\n'
                          '  "property3": "value3"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  buildSectionTitle('Autocomplete (BorderType Outline)',
                      Colors.blueGrey, Colors.blueGrey.shade100),
                  FormFieldsAutocomplete<String>(
                    fieldLabel: 'Outline Border',
                    apiUrl: 'https://dummyjson.com/products/search',
                    searchKey: 'q',
                    borderStyle: BorderType.outlineInputBorder,
                    onItemSelected:
                        viewModel.updateAutocompleteOutlineBorderResult,
                    labelPlacement: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Outline BorderType Result',
                      viewModel.autocompleteOutlineBorderResult),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "fieldLabel": "Outline Border",\n'
                          '  "apiUrl": "https://dummyjson.com/products/search",\n'
                          '  "searchKey": "q",\n'
                          '  "borderStyle": "BorderType.outlineInputBorder",\n'
                          '  "onItemSelected": "viewModel.updateAutocompleteOutlineBorderResult",\n'
                          '  "labelPlacement": "LabelPosition.top"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  buildSectionTitle('Autocomplete (BorderType Underline)',
                      Colors.teal, Colors.teal.shade100),
                  FormFieldsAutocomplete<String>(
                    fieldLabel: 'Underline Border',
                    apiUrl: 'https://dummyjson.com/products/search',
                    searchKey: 'q',
                    borderStyle: BorderType.underlineInputBorder,
                    onItemSelected:
                        viewModel.updateAutocompleteUnderlineBorderResult,
                    labelPlacement: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'Underline BorderType Result',
                      viewModel.autocompleteUnderlineBorderResult),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "fieldLabel": "Underline Border",\n'
                          '  "apiUrl": "https://dummyjson.com/products/search",\n'
                          '  "searchKey": "q",\n'
                          '  "borderStyle": "BorderType.underlineInputBorder",\n'
                          '  "onItemSelected": "viewModel.updateAutocompleteUnderlineBorderResult",\n'
                          '  "labelPlacement": "LabelPosition.top"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  buildSectionTitle('Autocomplete (BorderType None)',
                      Colors.deepPurple, Colors.deepPurple.shade100),
                  FormFieldsAutocomplete<String>(
                    fieldLabel: 'No Border',
                    apiUrl: 'https://dummyjson.com/products/search',
                    searchKey: 'q',
                    borderStyle: BorderType.none,
                    onItemSelected: viewModel.updateAutocompleteNoBorderResult,
                    labelPlacement: LabelPosition.top,
                  ),
                  buildResultDisplay(context, 'No BorderType Result',
                      viewModel.autocompleteNoBorderResult),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "fieldLabel": "No Border",\n'
                          '  "apiUrl": "https://dummyjson.com/products/search",\n'
                          '  "searchKey": "q",\n'
                          '  "borderStyle": "BorderType.none",\n'
                          '  "onItemSelected": "viewModel.updateAutocompleteNoBorderResult",\n'
                          '  "labelPlacement": "LabelPosition.top"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // ========== STRING TYPE ==========
                  buildSectionTitle(context.tr('ffStringTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable String - Basic
                  buildFieldTitle(
                      context.tr('ffStringBasic'), Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffFullName'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    onChanged: viewModel.updateString1,
                    currentValue: viewModel.string1,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffFullName'), viewModel.string1),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Full Name",\n'
                          '  "formType": "string",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Nullable String - Optional
                  buildFieldTitle(
                      context.tr('ffStringOptional'), Colors.blue.shade600),
                  FormFields<String?>(
                    label: context.tr('ffMiddleName'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    onChanged: viewModel.updateString2,
                    currentValue: viewModel.string2,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffMiddleName'), viewModel.string2),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Middle Name",\n'
                          '  "formType": "string",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": false\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // String with All Custom Parameters
                  buildFieldTitle(
                      context.tr('ffStringCustomParams'), Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffDescription'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    multiLine: 4,
                    radius: 15,
                    borderType: BorderType.outlineInputBorder,
                    borderColor: Colors.green,
                    errorBorderColor: Colors.red,
                    labelTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    prefixIcon:
                        const Icon(Icons.description, color: Colors.green),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('ffRequired');
                      }
                      if (value.length < 10) {
                        return context.tr('ffMinChars');
                      }
                      return null;
                    },
                    onChanged: viewModel.updateStringCustom,
                    currentValue: viewModel.stringCustom,
                    focusNode: viewModel.focusNode1,
                    nextFocusNode: viewModel.focusNode2,
                  ),
                  buildResultDisplay(context, context.tr('ffDescription'),
                      viewModel.stringCustom),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Description",\n'
                          '  "formType": "string",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true,\n'
                          '  "multiLine": 4,\n'
                          '  "radius": 15,\n'
                          '  "borderType": "BorderType.outlineInputBorder",\n'
                          '  "borderColor": "Colors.green",\n'
                          '  "errorBorderColor": "Colors.red",\n'
                          '  "labelTextStyle": "TextStyle(...)"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Email with Parameters
                  buildFieldTitle(context.tr('ffStringEmailFormType'),
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffEmail'),
                    formType: FormType.email,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.blue,
                    prefixIcon: const Icon(Icons.email),
                    onChanged: viewModel.updateEmail,
                    currentValue: viewModel.email,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffEmail'), viewModel.email),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Email",\n'
                          '  "formType": "FormType.email",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true,\n'
                          '  "prefixIcon": "Icon(Icons.email)",\n'
                          '  "onChanged": "viewModel.updateEmail"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Phone with Parameters
                  buildFieldTitle(context.tr('ffStringPhoneFormType'),
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffPhone'),
                    formType: FormType.phone,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.orange,
                    onChanged: viewModel.updatePhone,
                    currentValue: viewModel.phone,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffPhone'), viewModel.phone),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Phone",\n'
                          '  "formType": "FormType.phone",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true,\n'
                          '  "onChanged": "viewModel.updatePhone"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Phone with Country Code Selection
                  buildFieldTitle(
                      context.tr('ffStringPhoneCountry'), Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffPhoneCountryLabel'),
                    formType: FormType.phone,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.teal,
                    onChanged: viewModel.updatePhoneWithCountryCode,
                    currentValue: viewModel.phoneWithCountryCode,
                  ),
                  buildResultDisplay(context, context.tr('ffPhoneCountryCode'),
                      viewModel.phoneWithCountryCode),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Phone Country Label",\n'
                          '  "formType": "FormType.phone",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true,\n'
                          '  "onChanged": "viewModel.updatePhoneWithCountryCode"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Phone with Country Code & Formatting Display
                  buildFieldTitle(context.tr('ffStringPhoneFormatted'),
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffPhoneFormattedLabel'),
                    formType: FormType.phone,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    borderColor: Colors.indigo,
                    formatPhone: true,
                    onChanged: viewModel.updatePhoneFormatted,
                    currentValue: viewModel.phoneFormatted,
                  ),
                  buildResultDisplay(context, context.tr('ffPhoneFormatted'),
                      viewModel.phoneFormatted),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Phone Formatted Label",\n'
                          '  "formType": "FormType.phone",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "formatPhone": true,\n'
                          '  "onChanged": "viewModel.updatePhoneFormatted"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Password with All Parameters
                  buildFieldTitle(
                      context.tr('ffStringPassword'), Colors.blue.shade600),
                  FormFields<String>(
                    label: context.tr('ffPassword'),
                    formType: FormType.password,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    minLengthPassword: 8,
                    minLengthPasswordErrorText: context.tr('ffPasswordMin'),
                    borderColor: Colors.purple,
                    customPasswordValidator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('passwordRequired');
                      }
                      if (value.length < 8) {
                        return context.tr('passwordTooShort');
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return context.tr('passwordNeedsUppercase');
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return context.tr('passwordNeedsNumber');
                      }
                      return null;
                    },
                    onChanged: viewModel.updatePassword,
                    currentValue: viewModel.password,
                    focusNode: viewModel.focusNode2,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffPassword'), viewModel.password),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Password",\n'
                          '  "formType": "FormType.password",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true,\n'
                          '  "minLengthPassword": 8,\n'
                          '  "onChanged": "viewModel.updatePassword"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Verification code with verificationAsOtp: true
                  buildFieldTitle('Verification Code (verificationAsOtp: true)',
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: 'Verification Code',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationAsOtp: true,
                    borderColor: Colors.blueGrey,
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    onChanged: viewModel.updateVerificationCode,
                    currentValue: viewModel.verificationCode,
                  ),
                  buildResultDisplay(
                    context,
                    'Verification Code',
                    viewModel.verificationCode,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Verification Code",\n'
                          '  "formType": "FormType.verification",\n'
                          '  "verificationAsOtp": true,\n'
                          '  "verificationLength": 6,\n'
                          '  "onChanged": "viewModel.updateVerificationCode"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Verification code with verificationAsOtp: false
                  buildFieldTitle(
                      'Verification Code (verificationAsOtp: false)',
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: 'Verification Code (Single Field)',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationAsOtp: false,
                    verificationLength: 6,
                    borderColor: Colors.blueGrey,
                    prefixIcon: const Icon(Icons.pin_outlined),
                    onChanged: viewModel.updateVerificationCodeNoOtp,
                    currentValue: viewModel.verificationCodeNoOtp,
                  ),
                  buildResultDisplay(
                    context,
                    'Verification Code (Single Field)',
                    viewModel.verificationCodeNoOtp,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Verification Code (Single Field)",\n'
                          '  "formType": "FormType.verification",\n'
                          '  "verificationAsOtp": false,\n'
                          '  "verificationLength": 6,\n'
                          '  "onChanged": "viewModel.updateVerificationCodeNoOtp"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  buildFieldTitle(
                      'OTP Countdown (Alfanumerik)', Colors.blue.shade600),
                  FormFields<String>(
                    label: 'OTP Countdown (Alfanumerik)',
                    formType: FormType.verification,
                    isOtpCountdown: true,
                    verificationAsOtp: true,
                    labelPosition: LabelPosition.top,
                    verificationLength: 6,
                    verificationOtpAlphanumeric: true,
                    otpInputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    otpCountdownDuration: const Duration(seconds: 10),
                    onOtpCountdownComplete: () {
                      // ignore: avoid_print
                      print('Countdown selesai!');
                    },
                    onOtpCountdownReload: () {
                      // ignore: avoid_print
                      print('Kirim ulang OTP!');
                    },
                    currentValue: viewModel.verificationCode,
                    onChanged: (val) => viewModel.verificationCode = val,
                    otpBorderType: OtpBorderType.box,
                  ),
                  buildResultDisplay(
                    context,
                    'OTP Countdown (Alfanumerik)',
                    viewModel.verificationCode,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "OTP Countdown (Alfanumerik)",\n'
                          '  "formType": "verification",\n'
                          '  "isOtpCountdown": true,\n'
                          '  "verificationAsOtp": true,\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "verificationLength": 6,\n'
                          '  "verificationOtpAlphanumeric": true,\n'
                          '  "otpInputFormatters": "[FilteringTextInputFormatter.allow(RegExp(r\'[A-Za-z0-9]\')), LengthLimitingTextInputFormatter(6)]",\n'
                          '  "otpCountdownDuration": "Duration(seconds: 10)",\n'
                          '  "otpBorderType": "OtpBorderType.box"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Verification code hidden with OTP boxes
                  buildFieldTitle(
                      'Verification Code (Hidden OTP)', Colors.blue.shade600),
                  FormFields<String>(
                    label: 'Verification Code (Hidden OTP)',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationAsOtp: true,
                    verificationLength: 6,
                    verificationHidden: true,
                    borderColor: Colors.blueGrey,
                    prefixIcon: const Icon(Icons.shield_outlined),
                    onChanged: viewModel.updateVerificationCodeHiddenOtp,
                    currentValue: viewModel.verificationCodeHiddenOtp,
                  ),
                  buildResultDisplay(
                    context,
                    'Verification Code (Hidden OTP)',
                    viewModel.verificationCodeHiddenOtp,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Verification Code (Hidden OTP)",\n'
                          '  "formType": "verification",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true,\n'
                          '  "verificationAsOtp": true,\n'
                          '  "verificationLength": 6,\n'
                          '  "verificationHidden": true,\n'
                          '  "borderColor": "Colors.blueGrey",\n'
                          '  "prefixIcon": "Icon(Icons.shield_outlined)"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Verification code hidden in single text field
                  buildFieldTitle('Verification Code (Hidden Single Field)',
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: 'Verification Code (Hidden Single)',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationAsOtp: false,
                    verificationLength: 6,
                    verificationHidden: true,
                    borderColor: Colors.blueGrey,
                    prefixIcon: const Icon(Icons.lock_outline),
                    onChanged: viewModel.updateVerificationCodeHiddenSingle,
                    currentValue: viewModel.verificationCodeHiddenSingle,
                  ),
                  buildResultDisplay(
                    context,
                    'Verification Code (Hidden Single)',
                    viewModel.verificationCodeHiddenSingle,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Verification Code (Hidden Single)",\n'
                          '  "formType": "FormType.verification",\n'
                          '  "verificationAsOtp": false,\n'
                          '  "verificationHidden": true,\n'
                          '  "verificationLength": 6,\n'
                          '  "onChanged": "viewModel.updateVerificationCodeHiddenSingle"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Verification code with custom OTP style + inputDecoration
                  buildFieldTitle('Verification Code (Custom OTP Style)',
                      Colors.blue.shade600),
                  FormFields<String>(
                    label: 'Custom OTP',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationLength: 6,
                    verificationAsOtp: true,
                    otpBoxWidth: 44,
                    otpBoxSpacing: 12,
                    otpTextStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                    inputDecoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFF3F4F6),
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide:
                            BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide:
                            BorderSide(color: Color(0xFF84CC16), width: 1.6),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.red, width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: Colors.red, width: 1.6),
                      ),
                    ),
                    onChanged: viewModel.updateVerificationCodeStyled,
                    currentValue: viewModel.verificationCodeStyled,
                  ),
                  buildResultDisplay(
                    context,
                    'Custom OTP',
                    viewModel.verificationCodeStyled,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Custom OTP",\n'
                          '  "formType": "FormType.verification",\n'
                          '  "verificationAsOtp": true,\n'
                          '  "verificationLength": 6,\n'
                          '  "otpBoxWidth": 44,\n'
                          '  "otpBoxSpacing": 12,\n'
                          '  "onChanged": "viewModel.updateVerificationCodeStyled"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Dedicated OTP example (4 digits)
                  buildFieldTitle(
                      'OTP Example (4 Digits)', Colors.blue.shade600),
                  FormFields<String>(
                    label: 'OTP Code',
                    formType: FormType.verification,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    verificationLength: 4,
                    verificationAsOtp: true,
                    otpBoxWidth: 52,
                    otpBoxSpacing: 14,
                    otpTextStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    inputDecoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFFEEF2FF),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide:
                            BorderSide(color: Color(0xFFCBD5E1), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide:
                            BorderSide(color: Color(0xFF2563EB), width: 1.8),
                      ),
                    ),
                    onChanged: viewModel.updateOtp4Code,
                    currentValue: viewModel.otp4Code,
                  ),
                  buildResultDisplay(
                    context,
                    'OTP 4 Digits',
                    viewModel.otp4Code,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "OTP Code",\n'
                          '  "formType": "FormType.verification",\n'
                          '  "verificationAsOtp": true,\n'
                          '  "verificationLength": 4,\n'
                          '  "otpBoxWidth": 52,\n'
                          '  "otpBoxSpacing": 14,\n'
                          '  "onChanged": "viewModel.updateOtp4Code"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // ========== INTEGER TYPE ==========
                  buildSectionTitle(context.tr('ffIntTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable Int - Basic
                  buildFieldTitle(
                      context.tr('ffIntBasic'), Colors.blue.shade600),
                  FormFields<int>(
                    label: context.tr('ffAge'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    stripSeparators: false,
                    isRequired: true,
                    onChanged: viewModel.updateInt1,
                    currentValue: viewModel.int1,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffAge'), viewModel.int1),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Age",\n'
                          '  "formType": "string",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  // Nullable Int - With All Parameters
                  buildFieldTitle(
                      context.tr('ffIntOptional'), Colors.blue.shade600),
                  FormFields<int?>(
                    label: context.tr('ffQuantity'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    stripSeparators: true,
                    isRequired: false,
                    borderColor: Colors.teal,
                    prefixIcon: const Icon(Icons.inventory, color: Colors.teal),
                    labelTextStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                    onChanged: viewModel.updateInt2,
                    currentValue: viewModel.int2,
                  ),
                  buildResultDisplay(
                      context, context.tr('ffQuantity'), viewModel.int2),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Quantity",\n'
                          '  "formType": "string",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": false,\n'
                          '  "borderColor": "Colors.teal",\n'
                          '  "prefixIcon": "Icon(Icons.inventory, color: Colors.teal)",\n'
                          '  "labelTextStyle": "TextStyle(...)"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  buildSectionTitle(context.tr('ffDoubleTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable Double - With Separators
                  buildFieldTitle(
                      context.tr('ffDoubleBasic'), Colors.blue.shade600),
                  FormFields<double>(
                    label: context.tr('ffProductPrice'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    stripSeparators: true,
                    isRequired: true,
                    borderColor: Colors.green,
                    prefix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('\$',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    onChanged: viewModel.updateDouble1,
                    currentValue: viewModel.double1,
                  ),
                  buildResultDisplay(
                      context.tr('ffProductPrice'), viewModel.double1),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Product Price",\n'
                          '  "formType": "string",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true,\n'
                          '  "borderColor": "Colors.green",\n'
                          '  "prefix": "Text(\\\$)"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Nullable Double - All Parameters
                  buildFieldTitle(
                      context.tr('ffDoubleOptional'), Colors.blue.shade600),
                  FormFields<double?>(
                    label: context.tr('ffDiscountPercentage'),
                    formType: FormType.string,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.orange,
                    radius: 10,
                    suffix: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('%',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    labelTextStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: viewModel.updateDouble2,
                    currentValue: viewModel.double2,
                  ),
                  buildResultDisplay(
                      context.tr('ffDiscountPercentage'), viewModel.double2),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Discount Percentage",\n'
                          '  "formType": "string",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": false,\n'
                          '  "borderColor": "Colors.orange",\n'
                          '  "radius": 10,\n'
                          '  "suffix": "Text(\'%\')",\n'
                          '  "labelTextStyle": "TextStyle(...)"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // ========== DATETIME TYPE ==========
                  buildSectionTitle(context.tr('ffDateTimeTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable DateTime - Basic
                  buildFieldTitle(
                      context.tr('ffDateTimeBasic'), Colors.blue.shade600),
                  FormFields<DateTime>(
                    label: context.tr('ffBirthDate'),
                    formType: FormType.dateTime,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    onChanged: viewModel.updateDate1,
                    currentValue: viewModel.date1,
                  ),
                  buildResultDisplay(
                      context.tr('ffBirthDate'), viewModel.date1),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Birth Date",\n'
                          '  "formType": "dateTime",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Nullable DateTime - All Parameters
                  buildFieldTitle(
                      context.tr('ffDateTimeOptional'), Colors.blue.shade600),
                  FormFields<DateTime?>(
                    label: context.tr('ffEventDate'),
                    formType: FormType.dateTime,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.indigo,
                    radius: 12,
                    customFormat: 'dd MMMM yyyy',
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    prefixIcon: const Icon(Icons.calendar_today),
                    labelTextStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo,
                    ),
                    onChanged: viewModel.updateDate2,
                    currentValue: viewModel.date2,
                  ),
                  buildResultDisplay(
                      context.tr('ffEventDate'), viewModel.date2),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Event Date",\n'
                          '  "formType": "dateTime",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": false,\n'
                          '  "borderColor": "Colors.indigo",\n'
                          '  "radius": 12,\n'
                          '  "customFormat": "dd MMMM yyyy",\n'
                          '  "firstDate": "2020",\n'
                          '  "lastDate": "2030",\n'
                          '  "prefixIcon": "Icon(Icons.calendar_today)",\n'
                          '  "labelTextStyle": "TextStyle(...)"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // ========== TIMEOFDAY TYPE ==========
                  buildSectionTitle(context.tr('ffTimeOfDayTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable TimeOfDay - Basic
                  buildFieldTitle(
                      context.tr('ffTimeOfDayBasic'), Colors.blue.shade600),
                  FormFields<TimeOfDay>(
                    label: context.tr('ffMeetingTime'),
                    formType: FormType.timeOfDay,
                    labelPosition: LabelPosition.top,
                    isRequired: true,
                    onChanged: viewModel.updateTime1,
                    currentValue: viewModel.time1,
                  ),
                  buildResultDisplay(
                      context.tr('ffMeetingTime'), viewModel.time1),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Meeting Time",\n'
                          '  "formType": "timeOfDay",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": true\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Nullable TimeOfDay - All Parameters
                  buildFieldTitle(
                      context.tr('ffTimeOfDayOptional'), Colors.blue.shade600),
                  FormFields<TimeOfDay?>(
                    label: context.tr('ffWakeupTime'),
                    formType: FormType.timeOfDay,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.deepPurple,
                    radius: 12,
                    prefixIcon: const Icon(Icons.access_time),
                    labelTextStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                    onChanged: viewModel.updateTime2,
                    currentValue: viewModel.time2,
                  ),
                  buildResultDisplay(
                      context.tr('ffWakeupTime'), viewModel.time2),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Wakeup Time",\n'
                          '  "formType": "timeOfDay",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": false,\n'
                          '  "borderColor": "Colors.deepPurple",\n'
                          '  "radius": 12,\n'
                          '  "prefixIcon": "Icon(Icons.access_time)",\n'
                          '  "labelTextStyle": "TextStyle(...)"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // ========== DATETIMERANGE TYPE ==========
                  buildSectionTitle(context.tr('ffDateRangeTypes'),
                      Colors.blue.shade700, Colors.blue.shade400),

                  // Non-Nullable DateTimeRange - Basic
                  buildFieldTitle(
                      context.tr('ffDateRangeBasic'), Colors.blue.shade600),
                  FormFields<DateTimeRange>(
                    label: context.tr('ffProjectDuration'),
                    formType: FormType.dateTimeRange,
                    labelPosition: LabelPosition.top,
                    useDatePickerForRange: true,
                    onChanged: viewModel.updateRange1,
                    currentValue: viewModel.range1,
                  ),
                  buildResultDisplay(
                      context.tr('ffProjectDuration'), viewModel.range1),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Project Duration",\n'
                          '  "formType": "dateTimeRange",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "useDatePickerForRange": true\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // Nullable DateTimeRange - All Parameters
                  buildFieldTitle(
                      context.tr('ffDateRangeOptional'), Colors.blue.shade600),
                  FormFields<DateTimeRange?>(
                    label: context.tr('ffVacationPeriod'),
                    formType: FormType.dateTimeRange,
                    labelPosition: LabelPosition.top,
                    isRequired: false,
                    borderColor: Colors.cyan,
                    radius: 12,
                    customFormat: 'dd/MM/yyyy',
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2026),
                    prefixIcon: const Icon(Icons.date_range),
                    useDatePickerForRange: true,
                    labelTextStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.cyan,
                    ),
                    onChanged: viewModel.updateRange2,
                    currentValue: viewModel.range2,
                  ),
                  buildResultDisplay(
                      context.tr('ffVacationPeriod'), viewModel.range2),

                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Ff Vacation Period",\n'
                          '  "formType": "dateTimeRange",\n'
                          '  "labelPosition": "LabelPosition.top",\n'
                          '  "isRequired": false,\n'
                          '  "borderColor": "Colors.cyan",\n'
                          '  "radius": 12,\n'
                          '  "customFormat": "dd/MM/yyyy",\n'
                          '  "firstDate": "2024",\n'
                          '  "lastDate": "2026",\n'
                          '  "prefixIcon": "Icon(Icons.date_range)",\n'
                          '  "useDatePickerForRange": true,\n'
                          '  "labelTextStyle": "TextStyle(...)"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // ========== DROPDOWN ==========
                  buildSectionTitle(
                    'Dropdown',
                    Colors.purple.shade700,
                    Colors.purple.shade400,
                  ),
                  buildFieldTitle(
                      'Single Select Dropdown', Colors.purple.shade600),
                  FormFieldsDropdown<String>(
                    label: 'Kategori',
                    isRequired: true,
                    items: const [
                      'Elektronik',
                      'Pakaian',
                      'Makanan',
                      'Olahraga'
                    ],
                    initialValue: viewModel.dropdownValue,
                    onChanged: viewModel.setDropdownValue,
                  ),
                  buildResultDisplay(
                      context, 'Kategori Dipilih', viewModel.dropdownValue),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Kategori",\n'
                          '  "formType": "FormType.dropdown",\n'
                          '  "isRequired": true,\n'
                          '  "items": ["Elektronik", "Pakaian", "Makanan", "Olahraga"],\n'
                          '  "initialValue": "viewModel.dropdownValue",\n'
                          '  "onChanged": "viewModel.setDropdownValue"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // ========== DROPDOWN MULTI ==========
                  buildSectionTitle(
                    'Dropdown Multi',
                    Colors.deepPurple.shade700,
                    Colors.deepPurple.shade400,
                  ),
                  buildFieldTitle(
                      'Multi Select Dropdown', Colors.deepPurple.shade600),
                  FormFieldsDropdownMulti<String>(
                    label: 'Hobi',
                    isRequired: true,
                    items: const [
                      'Membaca',
                      'Olahraga',
                      'Musik',
                      'Memasak',
                      'Traveling'
                    ],
                    initialValues: viewModel.dropdownMultiValues,
                    onChanged: viewModel.setDropdownMultiValues,
                  ),
                  buildResultDisplay(
                      context, 'Hobi Dipilih', viewModel.dropdownMultiValues),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Hobi",\n'
                          '  "formType": "FormType.dropdownMulti",\n'
                          '  "isRequired": true,\n'
                          '  "items": ["Membaca", "Olahraga", "Musik", "Memasak", "Traveling"],\n'
                          '  "initialValue": "viewModel.dropdownMultiValues",\n'
                          '  "onChanged": "viewModel.setDropdownMultiValues"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // ========== RADIO BUTTON ==========
                  buildSectionTitle(
                    'Radio Button',
                    Colors.orange.shade700,
                    Colors.orange.shade400,
                  ),
                  buildFieldTitle(
                      'Radio Button (Horizontal)', Colors.orange.shade600),
                  FormFieldsRadioButton<String>(
                    label: 'Jenis Kelamin',
                    isRequired: true,
                    items: const ['Laki-laki', 'Perempuan', 'Lainnya'],
                    initialValue: viewModel.radioValue,
                    direction: Axis.horizontal,
                    onChanged: viewModel.setRadioValue,
                  ),
                  buildResultDisplay(
                      context, 'Jenis Kelamin', viewModel.radioValue),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Jenis Kelamin",\n'
                          '  "formType": "FormType.radioButton",\n'
                          '  "isRequired": true,\n'
                          '  "items": ["Laki-laki", "Perempuan", "Lainnya"],\n'
                          '  "direction": "Axis.horizontal",\n'
                          '  "initialValue": "viewModel.radioValue",\n'
                          '  "onChanged": "viewModel.setRadioValue"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  // ========== CHECKBOX ==========
                  buildSectionTitle(
                    'Checkbox',
                    Colors.pink.shade700,
                    Colors.pink.shade400,
                  ),
                  buildFieldTitle(
                      'Checkbox (Multi Selection)', Colors.pink.shade600),
                  FormFieldsCheckbox<String>(
                    label: 'Minat',
                    isRequired: true,
                    items: const ['Teknologi', 'Seni', 'Bisnis', 'Pendidikan'],
                    initialValue: viewModel.checkboxValues,
                    direction: Axis.vertical,
                    onChanged: viewModel.setCheckboxValues,
                  ),
                  buildResultDisplay(
                      context, 'Minat Dipilih', viewModel.checkboxValues),
                  const SizedBox(height: 12),
                  Text(
                    'Contoh Pengisian (JSON):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Color(0xFFF5F5F5),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SelectableText(
                          '{\n'
                          '  "label": "Minat",\n'
                          '  "formType": "FormType.checkbox",\n'
                          '  "isRequired": true,\n'
                          '  "items": ["Teknologi", "Seni", "Bisnis", "Pendidikan"],\n'
                          '  "direction": "Axis.vertical",\n'
                          '  "initialValue": "viewModel.checkboxValues",\n'
                          '  "onChanged": "viewModel.setCheckboxValues"\n'
                          '}',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        logger.i(
                            '\n╔═══════════════════════════════════════════════════════════════╗');
                        logger.i(
                            '║ FORM SUBMIT BUTTON CLICKED                                      ║');
                        logger.i(
                            '╚═══════════════════════════════════════════════════════════════╝');

                        final isValid =
                            viewModel.formKey.currentState!.validate();
                        logger.i('Form validation result: $isValid');

                        if (!isValid) {
                          logger.e('❌ Form validation FAILED - showing errors');
                          return;
                        } else {
                          logger.i('✓ Form validation PASSED - submitting');
                          _showFormData(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        context.tr('submitFormButton'),
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

  void _showFormData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(context.tr('ffFormValidated')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
