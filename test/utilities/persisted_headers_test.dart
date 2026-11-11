import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/utilities/persisted_headers.dart';

void main() {
  test('the Authorization header is removed from a persisted payload', () {
    final headers = {
      'Authorization': 'Bearer secret-token',
      'X-Client': 'app',
    };

    final kept = headersForPersistence(headers);

    expect(kept, {'X-Client': 'app'});
    expect(kept.toString(), isNot(contains('secret-token')));
  });

  test('the header name is matched regardless of case', () {
    expect(
      headersForPersistence({'authorization': 'Bearer x'}),
      isEmpty,
    );
  });

  test('the original map is not changed', () {
    final headers = {'Authorization': 'Bearer x'};

    headersForPersistence(headers);

    expect(headers, {'Authorization': 'Bearer x'});
  });
}
