import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/pages/sohbet_listesi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tüm sohbetler ListView.builder ile listelenir', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('all-chats-button')));
    await tester.pumpAndSettle();

    expect(find.byType(SohbetListesi), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('sohbet-listesi')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sohbet-satiri-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sohbet-satiri-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('sohbet-satiri-3')),
      findsOneWidget,
    );

    final ListView list = tester.widget<ListView>(
      find.byKey(const ValueKey<String>('sohbet-listesi')),
    );
    expect(list.childrenDelegate, isA<SliverChildBuilderDelegate>());
  });

  testWidgets('listedeki sohbet detayı açılır', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('all-chats-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('sohbet-satiri-2')));
    await tester.pumpAndSettle();

    expect(find.text('Oturum #2'), findsOneWidget);
  });
}
