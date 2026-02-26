import 'package:flutter/material.dart';
import 'package:form_fields/form_fields.dart';

/// Widget to show current language and demonstrate localized text
class LanguageIndicator extends StatelessWidget {
  const LanguageIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final l10n = FormFieldsLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.indigo.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.language,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌍 Multi-Language Demo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentLocale.languageCode == 'id'
                          ? '🇮🇩 Aktif: Indonesian (Bahasa Indonesia)'
                          : '🇺🇸 Active: English (United States)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentLocale.languageCode == 'id'
                      ? '💡 Contoh teks yang dilokalkan:'
                      : '💡 Localized text examples:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildExampleRow('Search:', l10n.searchHint),
                _buildExampleRow('Cancel:', l10n.cancel),
                _buildExampleRow('Select:', l10n.selectPrefix),
                _buildExampleRow('Enter:', l10n.enterPrefix),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentLocale.languageCode == 'id'
                ? '👆 Klik tombol EN/ID di AppBar atau buka Drawer untuk mengganti bahasa'
                : '👆 Click EN/ID button on AppBar or open Drawer to change language',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
