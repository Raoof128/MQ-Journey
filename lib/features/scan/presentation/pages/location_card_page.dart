import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_journey/app/l10n/generated/app_localizations.dart';
import 'package:mq_journey/features/scan/domain/contracts/location_content.dart';
import 'package:mq_journey/features/scan/domain/contracts/my_day_entry.dart';
import 'package:mq_journey/features/scan/domain/contracts/visited_state.dart';
import 'package:mq_journey/features/scan/providers/scan_providers.dart';
import 'package:mq_journey/features/scan/presentation/widgets/location_hero.dart';
import 'package:mq_journey/features/scan/presentation/widgets/schedule_chips.dart';
import 'package:mq_journey/features/scan/presentation/widgets/card_visit_badge.dart';
import 'package:mq_journey/app/router/route_names.dart';

class LocationCardPage extends ConsumerWidget {
  const LocationCardPage({super.key, required this.locationId});
  final String locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(locationContentProvider(locationId));
    final schedule = ref.watch(scheduleProvider);
    final visitedAsync = ref.watch(visitedStateProvider(locationId));
    final visited = visitedAsync.asData?.value ?? const VisitedState(visited: false, rewardEarned: false);

    if (content == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final liveNow = schedule.liveNow(locationId);
    final nextUp = schedule.comingUpNext(locationId);

    return Scaffold(
      appBar: AppBar(title: Text(content.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationHero(content: content),
            const SizedBox(height: 12),
            CardVisitBadge(state: visited),
            const SizedBox(height: 12),
            ScheduleChips(liveNow: liveNow, comingUpNext: nextUp),
            const SizedBox(height: 24),
            _ActionButtons(content: content),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.content});
  final LocationContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content.buildingId != null) ...[
          FilledButton.icon(
            onPressed: () => context.goNamed(
              RouteNames.indoorPreview,
              pathParameters: {'buildingId': content.buildingId!},
            ),
            icon: const Icon(Icons.explore),
            label: const Text('View indoor'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.goNamed(
              RouteNames.map,
              queryParameters: {'building': content.buildingId!},
            ),
            icon: const Icon(Icons.map),
            label: Text(l10n.navigateOnCampus),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () async {
            final api = ref.read(myDayApiProvider);
            await api.addToDay(MyDayEntry(
              locationId: content.locationId,
              when: DateTime.now(),
            ));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to Your Day')),
              );
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: const Text('Add to Your Day'),
        ),
      ],
    );
  }
}
