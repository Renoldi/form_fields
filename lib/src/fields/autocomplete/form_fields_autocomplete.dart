import 'package:flutter/material.dart';

import '../../utilities/dio_service.dart';
import 'package:dio/dio.dart' show Options;
import 'package:logger/logger.dart';
import '../../utilities/enums.dart';

/// FormFieldsAutocomplete supports:
/// - Custom query param and token header
/// - Custom InputDecoration (see #sym:InputDecoration)
/// - Custom result processing (resultProcessor)
/// - Use with FormFields and LabelPosition, BorderType (see #sym:LabelPosition, #sym:BorderType)
class FormFieldsAutocomplete<T extends Object> extends StatelessWidget {
  static final Logger _logger = Logger();
  final String fieldLabel;
  final String apiUrl;
  final String? apiToken;
  final void Function(T?) onItemSelected;
  final InputDecoration? inputDecoration;
  final String searchKey;
  final String tokenHeaderName;
  final List<T> Function(dynamic data)? parseResults;
  final LabelPosition labelPlacement;
  final BorderType borderStyle;
  final Widget? trailingIcon;
  final bool hideTrailingIcon;

  /// Returns a string label for the option (for text field display)
  final String Function(T)? itemSelectedBuilder;

  /// Returns a custom widget for the option (for dropdown list)
  final Widget Function(T item, bool selected)? itemBuilder;

  const FormFieldsAutocomplete({
    super.key,
    required this.fieldLabel,
    required this.apiUrl,
    this.apiToken,
    required this.onItemSelected,
    this.inputDecoration,
    this.searchKey = 'q',
    this.tokenHeaderName = 'Authorization',
    this.parseResults,
    this.labelPlacement = LabelPosition.none,
    this.borderStyle = BorderType.outlineInputBorder,
    this.trailingIcon,
    this.hideTrailingIcon = false,
    this.itemSelectedBuilder,
    this.itemBuilder,
  });

  /// Fetches options from the URL using Dio, with custom query param, token header, and result processing.
  Future<List<T>> _fetchOptions(String query) async {
    if (query.isEmpty) return [];
    try {
      final dioService = DioService();
      final headers = <String, dynamic>{};
      if (apiToken != null && tokenHeaderName.isNotEmpty) {
        headers[tokenHeaderName] =
            tokenHeaderName == 'Authorization' ? 'Bearer $apiToken' : apiToken;
      }
      _logger.i('Fetching options from: $apiUrl with query: $query');
      final response = await dioService.get(
        apiUrl,
        queryParameters: {searchKey: query},
        options: headers.isNotEmpty ? Options(headers: headers) : null,
      );
      final data = response.data;
      _logger.d('Response data: $data');
      if (parseResults != null) {
        return parseResults!(data);
      }
      if (data is List) {
        return data.map<T>((e) => e as T).toList();
      } else if (data is Map && data['results'] is List) {
        return (data['results'] as List).map<T>((e) => e as T).toList();
      }
      return [];
    } on DioServiceException catch (e, stack) {
      _logger.e('FormFieldsAutocomplete fetch error (DioServiceException)',
          error: e, stackTrace: stack);
      return [];
    } catch (e, stack) {
      _logger.e('FormFieldsAutocomplete fetch error',
          error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field = Autocomplete<T>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        return await _fetchOptions(textEditingValue.text);
      },
      onSelected: onItemSelected,
      displayStringForOption:
          itemSelectedBuilder ?? (option) => option.toString(),
      optionsViewBuilder: itemBuilder != null
          ? (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final selected = false; // You can enhance this if needed
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: itemBuilder!(option, selected),
                      );
                    },
                  ),
                ),
              );
            }
          : null,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        InputBorder border;
        switch (borderStyle) {
          case BorderType.underlineInputBorder:
            border = const UnderlineInputBorder();
            break;
          case BorderType.none:
            border = InputBorder.none;
            break;
          case BorderType.outlineInputBorder:
            border = OutlineInputBorder(borderRadius: BorderRadius.circular(8));
            break;
        }
        final baseDecoration =
            (inputDecoration ?? InputDecoration(hintText: fieldLabel)).copyWith(
          border: border,
        );
        InputDecoration effectiveDecoration;
        if (hideTrailingIcon) {
          effectiveDecoration = baseDecoration.copyWith(
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                // Always pass null when clearing, for type safety
                onItemSelected(null as T?);
              },
            ),
          );
        } else {
          effectiveDecoration = baseDecoration.copyWith(
            suffixIcon: trailingIcon,
          );
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: effectiveDecoration,
        );
      },
    );

    // Optionally wrap with label based on labelPosition
    switch (labelPlacement) {
      case LabelPosition.top:
        field = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(fieldLabel,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            field,
          ],
        );
        break;
      case LabelPosition.bottom:
        field = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            field,
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(fieldLabel,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        );
        break;
      case LabelPosition.left:
        field = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(fieldLabel,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Expanded(child: field),
          ],
        );
        break;
      case LabelPosition.right:
        field = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: field),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(fieldLabel,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        );
        break;
      case LabelPosition.inBorder:
        // Let InputDecoration handle floating label
        break;
      case LabelPosition.none:
        // No label
        break;
    }
    return field;
  }
}
