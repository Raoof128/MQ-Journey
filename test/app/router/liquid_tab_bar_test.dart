import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_journey/app/router/liquid_tab_bar.dart';

void main() {
  Finder viewfinder() => find.byWidgetPredicate(
    (w) =>
        w is CustomPaint &&
        w.painter.runtimeType.toString() == '_ViewfinderPainter',
  );

  Widget host() {
    var index = 0;
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: StatefulBuilder(
          builder: (context, setState) => LiquidTabBar(
            currentIndex: index,
            onSelected: (i) => setState(() => index = i),
            color: Colors.black,
            accent: Colors.red,
            items: const [
              LiquidNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                fx: TabFx.homecoming,
              ),
              LiquidNavItem(
                icon: Icons.qr_code_scanner_outlined,
                activeIcon: Icons.qr_code_scanner,
                label: 'Scan',
                fx: TabFx.scanline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('scanline fx plays on select and leaves no overlays behind', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    // Idle: no viewfinder brackets painted.
    expect(viewfinder(), findsNothing);

    await tester.tap(
      find.byIcon(Icons.qr_code_scanner_outlined),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // mid-scan
    expect(viewfinder(), findsOneWidget);

    await tester.pumpAndSettle();
    expect(viewfinder(), findsNothing); // sequence ends clean
  });

  testWidgets(
    'homecoming fx plays on re-select and leaves no overlays behind',
    (tester) async {
      Finder sunrise() => find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_SunrisePainter',
      );

      await tester.pumpWidget(host());
      expect(sunrise(), findsNothing); // initially selected but idle

      // Leave home, then come back — the flourish plays on becoming selected.
      await tester.tap(
        find.byIcon(Icons.qr_code_scanner_outlined),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.home_outlined), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 550)); // ray-burst stage
      expect(sunrise(), findsOneWidget);

      await tester.pumpAndSettle();
      expect(sunrise(), findsNothing);
    },
  );

  // ── RTL (fa/ar/he/ur) ──────────────────────────────────────
  //
  // The tab row is a plain [Row], so under `TextDirection.rtl` Flutter
  // mirrors it: item 0 renders at the *physical right*. Hit-testing
  // (`localPosition.dx`) and the indicator (`Positioned.left`) are both
  // physical-left-origin, so without mirroring they address the opposite
  // tab — taps navigate to the wrong page and the lens glides the wrong way.
  Widget rtlHost({
    required int currentIndex,
    required ValueChanged<int> onSelected,
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          bottomNavigationBar: LiquidTabBar(
            currentIndex: currentIndex,
            onSelected: onSelected,
            color: Colors.black,
            items: const [
              LiquidNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                fx: TabFx.homecoming,
              ),
              LiquidNavItem(
                icon: Icons.qr_code_scanner_outlined,
                activeIcon: Icons.qr_code_scanner,
                label: 'Scan',
                fx: TabFx.scanline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('RTL: tapping a tab selects that tab, not its mirror', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(rtlHost(currentIndex: 0, onSelected: selected.add));

    // Scan (index 1) renders on the physical LEFT under RTL.
    await tester.tap(
      find.byIcon(Icons.qr_code_scanner_outlined),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(selected, [1]);
  });

  testWidgets('RTL: the lens sits over the selected tab', (tester) async {
    Rect lensRect(WidgetTester tester) {
      final positioned = tester
          .widgetList<Positioned>(
            find.descendant(
              of: find.byType(LiquidTabBar),
              matching: find.byType(Positioned),
            ),
          )
          .first;
      final barWidth = tester.getSize(find.byType(LiquidTabBar)).width;
      return Rect.fromLTWH(
        positioned.left!,
        0,
        positioned.width!,
        1,
      ).translate(0, barWidth * 0); // width-relative assertions below
    }

    await tester.pumpWidget(rtlHost(currentIndex: 0, onSelected: (_) {}));
    await tester.pumpAndSettle();

    final barWidth = tester.getSize(find.byType(LiquidTabBar)).width;
    final lens = lensRect(tester);
    // Index 0 is the right-hand half of a 2-tab bar under RTL.
    expect(lens.center.dx, greaterThan(barWidth / 2));

    // And the lens must actually cover the Home icon.
    final homeCentre = tester.getCenter(find.byIcon(Icons.home));
    expect(homeCentre.dx, greaterThan(lens.left));
    expect(homeCentre.dx, lessThan(lens.right));
  });
}
