import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_journey/app/l10n/generated/app_localizations.dart';
import 'package:mq_journey/features/scan/presentation/pages/location_card_page.dart';
import 'package:mq_journey/features/scan/providers/scan_providers.dart';
import 'package:mq_journey/features/scan/domain/contracts/location_content.dart';
import 'package:mq_journey/features/scan/domain/contracts/visited_state.dart';
import 'package:mq_journey/features/scan/domain/contracts/schedule_provider.dart';
import 'package:mq_journey/features/scan/domain/contracts/schedule_slot.dart';
import 'package:mq_journey/features/scan/domain/fakes/fake_my_day_api.dart';

void main() {
  testWidgets('renders location card with content', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationContentProvider.overrideWith(
            (ref, id) => LocationContent(
              locationId: id,
              title: 'Test Location',
              heroImageAsset: 'assets/images/placeholder_hero.png',
              shortDescription: 'A test location description.',
              buildingId: 'C3A',
            ),
          ),
          scheduleProvider.overrideWith((ref) => _FakeScheduleProvider()),
          visitedStateProvider.overrideWith(
            (ref, id) => Stream<VisitedState>.value(
              const VisitedState(visited: false, rewardEarned: false),
            ),
          ),
          myDayApiProvider.overrideWith((ref) => FakeMyDayApi()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LocationCardPage(locationId: 'lib-01'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test Location'), findsAtLeast(1));
    expect(find.text('A test location description.'), findsOneWidget);
  });
}

class _FakeScheduleProvider implements ScheduleProvider {
  @override
  ScheduleSlot? liveNow(String locationId) => null;

  @override
  ScheduleSlot? comingUpNext(String locationId) => null;
}
