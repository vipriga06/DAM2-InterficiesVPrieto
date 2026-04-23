import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_proxmox/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GestorProxmoxApp());
    expect(find.text('Servidors'), findsOneWidget);
  });
}
