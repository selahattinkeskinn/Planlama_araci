import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/router/app_router.dart';
import 'package:flutter_application_1/widgets/rotating_cube_3d.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => RotatingCube3D.animationsEnabled = false);

  testWidgets('sohbetler arasında geçiş yapılır ve arşiv sonucu gösterilir', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Planlama Ajanı'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey<String>('agent-card')));
    await tester.pumpAndSettle();

    expect(find.text('Sohbet 1'), findsWidgets);
    expect(find.text('Sohbet 2'), findsOneWidget);
    expect(find.text('Sohbet 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('chat-chip-3')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.textContaining('Odak modu'), findsOneWidget);
    expect(find.textContaining('Harika seçim'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('archive-button')));
    await tester.pumpAndSettle();

    expect(find.text('Planlama Ajanı'), findsWidgets);
    expect(find.text('Dönüş değeri: arsivlendi'), findsOneWidget);
  });

  testWidgets('path parametresi ile planlama ajanı açılır', (tester) async {
    final router = AppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData.dark(),
        routerConfig: router.config(),
      ),
    );
    await tester.pumpAndSettle();

    router.pushPath('/sohbet/7');
    await tester.pumpAndSettle();

    expect(find.text('Oturum #7'), findsOneWidget);
    expect(find.text('Sohbet 1'), findsWidgets);
  });

  testWidgets('bilinmeyen yol ana sayfaya yönlendirilir', (tester) async {
    final router = AppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData.dark(),
        routerConfig: router.config(),
      ),
    );
    await tester.pumpAndSettle();

    router.pushPath('/bilinmeyen');
    await tester.pumpAndSettle();

    expect(find.text('Planlama Ajanı'), findsWidgets);
  });
}
