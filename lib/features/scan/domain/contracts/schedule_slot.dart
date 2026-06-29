import 'package:flutter/foundation.dart';

@immutable
class ScheduleSlot {
  final String title;
  final DateTime start;
  final DateTime end;

  const ScheduleSlot(this.title, this.start, this.end);
}
