import 'package:flutter/foundation.dart';
import 'package:mq_journey/features/open_day/domain/entities/open_day_data.dart';

/// Snapshot of the Open Day schedule relative to a point in time, biased
/// toward the user's selected study interest.
///
/// Computed by [OpenDayPersonalisation.liveStatus]. Held as a value type so
/// the UI can pattern-match on it without re-deriving anything.
@immutable
class OpenDayLiveStatus {
  const OpenDayLiveStatus({
    required this.liveNow,
    required this.comingUpNext,
    required this.usedFallback,
  });

  /// Events currently running (start ≤ now ≤ end).
  final List<OpenDayEvent> liveNow;

  /// The single soonest event that hasn't started yet, or `null` if the day
  /// is over.
  final OpenDayEvent? comingUpNext;

  /// True when there were no interest-relevant events to show and the result
  /// fell back to the full schedule. Lets the UI label the section honestly
  /// ("Across Open Day" vs "For your interest").
  final bool usedFallback;

  bool get isEmpty => liveNow.isEmpty && comingUpNext == null;
}

/// Pure personalisation logic for the Open Day / Home experience.
///
/// **Why this is a standalone service**
///   Every "what should this user see?" decision lives here as a static,
///   side-effect-free function. Widgets and providers call in; nothing in
///   this file imports Flutter UI or Riverpod. That keeps the ranking rules
///   unit-testable in isolation and prevents the logic from being copy-pasted
///   across the Suggested Stops, Your Day and Live Now widgets.
class OpenDayPersonalisation {
  OpenDayPersonalisation._();

  /// Returns the suggested stops most relevant to [selected], ranked
  /// strongest-match-first and trimmed to [max].
  ///
  /// Ranking is stable: stops with equal relevance keep their dataset order,
  /// so curators can control tie-breaks simply by ordering the JSON. The
  /// universal (relevance-1) stops act as a backfill, guaranteeing the list
  /// reaches [max] wherever enough stops exist — so the section never looks
  /// thin even for a niche interest.
  static List<OpenDaySuggestedStop> suggestedStops(
    OpenDayData data,
    OpenDayBachelor? selected, {
    int max = 5,
  }) {
    final scored = <({OpenDaySuggestedStop stop, int score, int order})>[];
    for (var i = 0; i < data.suggestedStops.length; i++) {
      final stop = data.suggestedStops[i];
      final score = stop.relevanceFor(selected);
      if (score <= 0) continue;
      scored.add((stop: stop, score: score, order: i));
    }
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.order.compareTo(b.order);
    });
    return [for (final s in scored.take(max)) s.stop];
  }

  /// Computes the live/upcoming snapshot for Home.
  ///
  /// [relevant] should already be filtered to the user's interest (e.g. the
  /// `relevantOpenDayEventsProvider` output) and [all] is the full schedule.
  /// When the user's interest yields nothing live or upcoming, we fall back
  /// to [all] so the section stays useful — and flag it via
  /// [OpenDayLiveStatus.usedFallback].
  static OpenDayLiveStatus liveStatus(
    List<OpenDayEvent> relevant,
    List<OpenDayEvent> all,
    DateTime now,
  ) {
    final relevantStatus = _statusFrom(relevant, now, usedFallback: false);
    if (!relevantStatus.isEmpty) return relevantStatus;
    return _statusFrom(all, now, usedFallback: true);
  }

  static OpenDayLiveStatus _statusFrom(
    List<OpenDayEvent> events,
    DateTime now, {
    required bool usedFallback,
  }) {
    final sorted = [...events]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final liveNow = <OpenDayEvent>[];
    OpenDayEvent? comingUpNext;
    for (final e in sorted) {
      final isLive =
          !now.isBefore(e.startTime) && !now.isAfter(e.endTime);
      if (isLive) {
        liveNow.add(e);
      } else if (e.startTime.isAfter(now) && comingUpNext == null) {
        comingUpNext = e;
      }
    }
    return OpenDayLiveStatus(
      liveNow: liveNow,
      comingUpNext: comingUpNext,
      usedFallback: usedFallback,
    );
  }
}
