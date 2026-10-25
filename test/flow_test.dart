import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staff_lona/main.dart';
import 'package:staff_lona/components.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('ReplicaSans');
    loader.addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await loader.load();
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    final cupertino = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(
        rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
      );
    await material.load();
    await cupertino.load();
  });
  Future<void> mount(
    WidgetTester tester,
    ReferenceScreen screen, {
    GlobalKey? key,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MyApp(
        key: UniqueKey(),
        initialScreen: screen,
        autoAdvance: false,
        showReviewPanel: false,
        captureKey: key,
        simulateDevice: true,
      ),
    );
    await tester.runAsync(() async {
      for (final name in ['wordmark', 'ready', 'cards', 'invest']) {
        await precacheImage(
          AssetImage('assets/art/$name.webp'),
          tester.element(find.byType(ReferenceFlow)),
        );
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'capture all 12 reference states at 390 × 844 without framework errors',
    (tester) async {
      for (final screen in ReferenceScreen.values) {
        final key = GlobalKey();
        await mount(tester, screen, key: key);
        expect(tester.takeException(), isNull, reason: screen.label);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('verification/screens').create(recursive: true);
          await File(
            'verification/screens/${(screen.index + 1).toString().padLeft(2, '0')}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('walkthrough, recovery, country filtering and validation work', (
    tester,
  ) async {
    await mount(tester, ReferenceScreen.ready);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('+44'));
    await tester.pumpAndSettle();
    expect(find.text('United Kingdom'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'usa');
    await tester.pump();
    expect(find.text('United States'), findsNothing);
    await tester.enterText(find.byType(TextField).last, 'us');
    await tester.pump();
    expect(find.text('United States'), findsOneWidget);
    expect(find.text('Australia'), findsOneWidget);
    await tester.tap(find.text('United States'));
    await tester.pumpAndSettle();
    expect(find.text('+1'), findsOneWidget);
    await tester.tap(find.text('Lost access to my phone number'));
    await tester.pumpAndSettle();
    expect(find.text('Enter phone\nnumber'), findsOneWidget);
    await tester.tap(find.text('Forgot your phone number?'));
    await tester.pumpAndSettle();
    final field = find.byType(TextField).first;
    await tester.enterText(field, 'invalid');
    await tester.pump();
    PillButton button = tester.widget(find.byType(PillButton));
    expect(button.onPressed, isNull);
    await tester.enterText(field, 'alex@example.com');
    await tester.pump();
    button = tester.widget(find.byType(PillButton));
    expect(button.onPressed, isNotNull);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Preview complete'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Enter phone\nnumber'), findsOneWidget);
  });

  testWidgets('compact width and keyboard focus remain usable', (tester) async {
    await mount(tester, ReferenceScreen.welcome, size: const Size(390, 844));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(tester.takeException(), isNull);
    await mount(tester, ReferenceScreen.email, size: const Size(390, 740));
    expect(tester.takeException(), isNull);
  });
}
