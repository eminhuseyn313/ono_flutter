import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/app.dart';

void main() {
  Future<Size> sizeIn(WidgetTester tester, Size window) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late Size seen;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => PhoneFrame(child: child!),
      home: Builder(builder: (context) {
        seen = MediaQuery.of(context).size;
        return const SizedBox.expand(key: Key('page'));
      }),
    ));
    expect(tester.getSize(find.byKey(const Key('page'))).width, seen.width);
    return seen;
  }

  testWidgets('a wide window keeps a phone-width column', (tester) async {
    final size = await sizeIn(tester, const Size(1280, 800));
    expect(size.width, PhoneFrame.maxWidth);
    expect(size.height, 800);
  });

  testWidgets('a phone uses the whole screen', (tester) async {
    final size = await sizeIn(tester, const Size(393, 852));
    expect(size.width, 393);
  });
}
