import 'package:flutter/material.dart';
import 'package:mq_journey/features/scan/domain/contracts/schedule_slot.dart';

class ScheduleChips extends StatelessWidget {
  const ScheduleChips({super.key, this.liveNow, this.comingUpNext});
  final ScheduleSlot? liveNow;
  final ScheduleSlot? comingUpNext;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (liveNow != null) {
      chips.add(Chip(
        avatar: const Icon(Icons.play_circle, size: 18),
        label: Text('Live Now: ${liveNow!.title}'),
        backgroundColor: Colors.green[50],
      ));
    }
    if (comingUpNext != null) {
      chips.add(Chip(
        avatar: const Icon(Icons.schedule, size: 18),
        label: Text('Up Next: ${comingUpNext!.title}'),
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 4, children: chips);
  }
}
