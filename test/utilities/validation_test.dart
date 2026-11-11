import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/utilities/extensions.dart';
import 'package:form_fields/src/utilities/validators.dart';

void main() {
  group('isValidEmail', () {
    test('accepts ordinary and dotted addresses', () {
      expect('john@mail.com'.isValidEmail, isTrue);
      expect('a.b+c@sub.example.co.id'.isValidEmail, isTrue);
      expect('first-last@my-domain.io'.isValidEmail, isTrue);
    });

    test('ignores surrounding whitespace', () {
      expect('  user@x.io  '.isValidEmail, isTrue);
    });

    test('rejects trailing text after a valid address', () {
      expect('john@mail.com) junk'.isValidEmail, isFalse);
      expect('john@mail.com<script>'.isValidEmail, isFalse);
    });

    test('rejects a one-letter top-level domain and malformed parts', () {
      expect('a@b.c'.isValidEmail, isFalse);
      expect('user@@x.io'.isValidEmail, isFalse);
      expect('user@.io'.isValidEmail, isFalse);
      expect('user@x..io'.isValidEmail, isFalse);
      expect('no-at-sign.com'.isValidEmail, isFalse);
    });

    test('null is never valid', () {
      expect((null as String?).isValidEmail, isFalse);
    });
  });

  group('number validators', () {
    test('isValidDecimal accepts decimals and signs', () {
      expect('3.5'.isValidDecimal, isTrue);
      expect('-2'.isValidDecimal, isTrue);
      expect('.5'.isValidDecimal, isTrue);
      expect(' 7 '.isValidDecimal, isTrue);
    });

    test('isValidDecimal rejects text and non-finite values', () {
      expect('abc'.isValidDecimal, isFalse);
      expect('1,5'.isValidDecimal, isFalse);
      expect('NaN'.isValidDecimal, isFalse);
      expect('Infinity'.isValidDecimal, isFalse);
    });

    test('isValidNumber still accepts whole numbers only', () {
      expect('42'.isValidNumber, isTrue);
      expect('-42'.isValidNumber, isTrue);
      expect('4.2'.isValidNumber, isFalse);
    });

    test('number() accepts decimal input', () {
      final validate = FormFieldValidators.number('Amount');
      expect(validate('3.5'), isNull);
      expect(validate('x'), isNotNull);
    });

    test('range() accepts decimals inside the bounds', () {
      final validate = FormFieldValidators.range('Rate', 0.5, 2.5);
      expect(validate('1.5'), isNull);
      expect(validate('0.5'), isNull);
      expect(validate('2.6'), isNotNull);
      expect(validate('0.4'), isNotNull);
    });

    test('range() accepts a value with surrounding spaces', () {
      final validate = FormFieldValidators.range('Count', 1, 10);
      expect(validate(' 5 '), isNull);
    });
  });

  group('pattern()', () {
    test('an invalid pattern fails when the validator is built', () {
      expect(
        () => FormFieldValidators.pattern('Code', '('),
        throwsFormatException,
      );
    });

    test('matches the given pattern', () {
      final validate = FormFieldValidators.pattern('Code', r'^[A-Z]{3}$');
      expect(validate('ABC'), isNull);
      expect(validate('abc'), isNotNull);
    });
  });

  group('dateTimeUtcFromJson', () {
    DateTime utc(String s) => dateTimeUtcFromJson(s)!.toUtc();

    test('treats a timestamp with no offset as UTC', () {
      expect(utc('2024-01-01T03:00:00'), DateTime.utc(2024, 1, 1, 3));
    });

    test('keeps an explicit Z suffix', () {
      expect(utc('2024-01-01T03:00:00Z'), DateTime.utc(2024, 1, 1, 3));
    });

    test('honours an explicit offset instead of appending Z', () {
      // 10:00 at +07:00 is 03:00 UTC.
      expect(utc('2024-01-01T10:00:00+07:00'), DateTime.utc(2024, 1, 1, 3));
      expect(utc('2024-01-01T03:00:00-0500'), DateTime.utc(2024, 1, 1, 8));
    });

    test('returns null for null or unparseable input', () {
      expect(dateTimeUtcFromJson(null), isNull);
      expect(dateTimeUtcFromJson('not a date'), isNull);
    });
  });
}
