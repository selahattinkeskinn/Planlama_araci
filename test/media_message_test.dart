import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/chat_thread.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/utils/formatters.dart';
import 'package:flutter_application_1/widgets/chat_composer.dart';
import 'package:flutter_application_1/widgets/media_message.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAC'
  'hwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  testWidgets('resim eki mesaj içinde gösterilir', (tester) async {
    final ChatAttachment attachment = ChatAttachment(
      kind: MediaKind.image,
      name: 'test.png',
      bytes: _transparentPng,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: MediaMessage(attachment: attachment, accent: AppColors.cyan),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('metin mesajı gönderilir', (tester) async {
    String? sentText;
    ChatAttachment? sentAttachment;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: ChatComposer(
            accent: AppColors.cyan,
            onSend: (String text, ChatAttachment? attachment) {
              sentText = text;
              sentAttachment = attachment;
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('composer-field')),
      'Merhaba dünya',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('send-button')));
    await tester.pump();

    expect(sentText, 'Merhaba dünya');
    expect(sentAttachment, isNull);
  });

  test('boyut ve süre biçimlendirmesi', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(2048), '2 KB');
    expect(formatDuration(const Duration(seconds: 65)), '01:05');
    expect(formatDuration(const Duration(minutes: 62)), '1:02:00');
  });
}
