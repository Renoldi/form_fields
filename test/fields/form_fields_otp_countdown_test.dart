import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';

void main() {
  testWidgets('OTP countdown timer is cancelled when the field is disposed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormFields<String>(
            label: 'OTP',
            onChanged: (_) {},
            formType: FormType.verification,
            verificationAsOtp: true,
            isOtpCountdown: true,
            otpCountdownDuration: const Duration(seconds: 3),
          ),
        ),
      ),
    );

    // Remove the field while the countdown is still running.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    // Advancing past the countdown must not call setState on the disposed
    // state. Before the fix this threw "setState() called after dispose()".
    await tester.pump(const Duration(seconds: 5));

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'OTP countdown fires onOtpCountdownComplete once it reaches zero',
    (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormFields<String>(
              label: 'OTP',
              onChanged: (_) {},
              formType: FormType.verification,
              verificationAsOtp: true,
              isOtpCountdown: true,
              otpCountdownDuration: const Duration(seconds: 2),
              onOtpCountdownComplete: () => completed++,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 3));

      expect(completed, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
