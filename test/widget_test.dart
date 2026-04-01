import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_texttospeech_engine_demo/main.dart';

void main() {
  testWidgets('首页显示朗读按钮', (WidgetTester tester) async {
    await tester.pumpWidget(const TtsDemoApp());
    expect(find.text('朗读'), findsOneWidget);
    expect(find.text('停止'), findsOneWidget);
  });
}
