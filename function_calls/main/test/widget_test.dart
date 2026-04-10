// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:exemple0700/app.dart';
import 'package:exemple0700/app_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App renders main drawing layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppData(),
        child: const App(),
      ),
    );

    await tester.pump();

    expect(find.text('Func call demo'), findsOneWidget);
    expect(find.text('Query'), findsOneWidget);
  });
}
