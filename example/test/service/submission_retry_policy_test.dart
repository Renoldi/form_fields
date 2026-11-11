import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields_example/src/service/submission_retry_policy.dart';

void main() {
  const policy = SubmissionRetryPolicy();

  test('delay doubles after each failure', () {
    expect(policy.delayAfter(1), const Duration(seconds: 30));
    expect(policy.delayAfter(2), const Duration(seconds: 60));
    expect(policy.delayAfter(3), const Duration(seconds: 120));
  });

  test('delay is capped at maxDelay', () {
    expect(policy.delayAfter(20), const Duration(hours: 1));
    expect(policy.delayAfter(100), const Duration(hours: 1));
  });

  test('gives up after maxAttempts', () {
    expect(policy.isExhausted(7), isFalse);
    expect(policy.isExhausted(8), isTrue);
    expect(policy.isExhausted(9), isTrue);
  });

  test('zero or negative attempts fall back to the base delay', () {
    expect(policy.delayAfter(0), const Duration(seconds: 30));
  });
}
