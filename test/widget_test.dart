import 'package:flutter_test/flutter_test.dart';
import 'package:ternatelomba/main.dart';

void main() {
  testWidgets('Splash lalu halaman Masuk tampil', (tester) async {
    await tester.pumpWidget(const TernateLombaApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Masuk'), findsWidgets);
  });
}
