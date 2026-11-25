import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/form_fields.dart';

String _controllerText(WidgetTester tester) => tester
    .widget<EditableText>(find.byType(EditableText).first)
    .controller
    .text;

/// Types [text] one key at a time, pumping [gap] between keys, as a fast typist
/// would. Each key is delivered through the text input channel.
Future<void> _typeFast(
  WidgetTester tester,
  String text, {
  Duration gap = const Duration(milliseconds: 80),
}) async {
  for (var i = 0; i < text.length; i++) {
    final next = _controllerText(tester) + text[i];
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      ),
    );
    await tester.pump(gap);
  }
}

/// Hosts a text [FormFields] that behaves like a typical parent: it stores the
/// value it receives in `onChanged` and passes it back as `currentValue`.
/// [echo] lets a test make the parent hand back a transformed value.
class _EchoHost extends StatefulWidget {
  const _EchoHost({
    super.key,
    required this.calls,
    this.echo,
    this.holdEcho = false,
  });

  final List<String> calls;
  final String Function(String value)? echo;

  /// When true the echoes are kept back until [_EchoHostState.releaseEcho], so
  /// a test can deliver a parent's echo late, after the user typed more.
  final bool holdEcho;

  @override
  State<_EchoHost> createState() => _EchoHostState();
}

class _EchoHostState extends State<_EchoHost> {
  String? value;
  bool showField = true;
  final List<String> _held = [];

  void hideField() => setState(() => showField = false);

  /// Changes the value as the parent itself, not as an echo.
  void setParentValue(String v) => setState(() => value = v);

  /// Hands back the oldest held echo.
  void releaseEcho() {
    if (_held.isEmpty) return;
    final next = _held.removeAt(0);
    setState(() => value = next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: showField
            ? FormFields<String>(
                label: 'Nama',
                currentValue: value,
                onChanged: (v) {
                  widget.calls.add(v);
                  final next = widget.echo?.call(v) ?? v;
                  if (widget.holdEcho) {
                    _held.add(next);
                  } else {
                    setState(() => value = next);
                  }
                },
              )
            : const SizedBox(),
      ),
    );
  }
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required List<String> calls,
  GlobalKey<_EchoHostState>? key,
  String Function(String value)? echo,
  bool holdEcho = false,
}) async {
  await tester.pumpWidget(
    _EchoHost(key: key, calls: calls, echo: echo, holdEcho: holdEcho),
  );
  await tester.tap(find.byType(EditableText).first);
  await tester.pump();
}

void main() {
  testWidgets('the text is sent once typing pauses, not on every keystroke', (
    tester,
  ) async {
    final calls = <String>[];
    await _pumpHost(tester, calls: calls);

    await _typeFast(tester, 'abc', gap: const Duration(milliseconds: 50));
    expect(calls, isEmpty, reason: 'still typing: nothing is sent yet');

    await tester.pump(const Duration(milliseconds: 600));
    expect(calls, ['abc']);
  });

  testWidgets('pending text is sent when the field loses focus', (
    tester,
  ) async {
    final calls = <String>[];
    await _pumpHost(tester, calls: calls);

    await _typeFast(tester, 'abc', gap: const Duration(milliseconds: 50));
    expect(calls, isEmpty);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(calls, ['abc']);
  });

  testWidgets('pending text is sent when the user submits', (tester) async {
    final calls = <String>[];
    await _pumpHost(tester, calls: calls);

    await _typeFast(tester, 'abc', gap: const Duration(milliseconds: 50));
    expect(calls, isEmpty);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(calls, ['abc']);
  });

  testWidgets('pending text is sent when the field is removed', (tester) async {
    final calls = <String>[];
    final key = GlobalKey<_EchoHostState>();
    await _pumpHost(tester, calls: calls, key: key);

    await _typeFast(tester, 'abc', gap: const Duration(milliseconds: 50));
    expect(calls, isEmpty);

    // Remove the field inside the debounce window.
    key.currentState!.hideField();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(calls, ['abc']);
  });

  testWidgets('a trailing space the user typed survives the parent echo', (
    tester,
  ) async {
    final calls = <String>[];
    await _pumpHost(tester, calls: calls);

    await _typeFast(tester, 'budi ');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    // The space trims to the same value, so the value is sent once. The text
    // the user typed is kept as it is.
    expect(calls, ['budi']);
    expect(_controllerText(tester), 'budi ');
  });

  testWidgets('a parent that transforms the value still updates the text', (
    tester,
  ) async {
    await _pumpHost(tester, calls: <String>[], echo: (v) => v.toUpperCase());

    await _typeFast(tester, 'budi');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(_controllerText(tester), 'BUDI');
  });

  testWidgets(
    'a number with stripSeparators is sent after the pause and keeps its separators',
    (tester) async {
      final sent = <int>[];
      int? value;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FormFields<int>(
                  label: 'Jumlah',
                  stripSeparators: true,
                  currentValue: value,
                  onChanged: (v) {
                    sent.add(v);
                    setState(() => value = v);
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText).first);
      await tester.pump();

      await _typeFast(tester, '1000');
      // The input formatter shows the separators as the user types.
      expect(_controllerText(tester), '1,000');
      expect(sent, isEmpty, reason: 'still typing: nothing is sent yet');

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(sent, [1000]);
      expect(value, 1000);
      expect(_controllerText(tester), '1,000');
    },
  );

  testWidgets('a late echo does not erase text typed while it was on its way', (
    tester,
  ) async {
    final calls = <String>[];
    final key = GlobalKey<_EchoHostState>();
    await _pumpHost(tester, calls: calls, key: key, holdEcho: true);

    await _typeFast(tester, 'ab');
    await tester.pump(const Duration(milliseconds: 600));
    expect(calls, ['ab']);

    // The user types more while the echo of "ab" has not arrived yet, and the
    // new text is still waiting for its pause.
    await _typeFast(tester, 'c');
    expect(calls, ['ab']);

    // The stale echo arrives now. It must not rewrite the text.
    key.currentState!.releaseEcho();
    await tester.pump();
    expect(_controllerText(tester), 'abc');

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(calls, ['ab', 'abc']);

    key.currentState!.releaseEcho();
    await tester.pump();
    expect(_controllerText(tester), 'abc');
  });

  testWidgets('a value the parent sets itself replaces the typed text', (
    tester,
  ) async {
    final calls = <String>[];
    final key = GlobalKey<_EchoHostState>();
    await _pumpHost(tester, calls: calls, key: key);

    await _typeFast(tester, 'abc');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    key.currentState!.setParentValue('xyz');
    await tester.pump();
    await tester.pump();

    expect(_controllerText(tester), 'xyz');
  });
}
