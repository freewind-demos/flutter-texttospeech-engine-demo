import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("smoke", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Center(child: Text("ok")),
        ),
      ),
    );
    expect(find.text("ok"), findsOneWidget);
  });
}
