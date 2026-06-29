import 'package:flutter/foundation.dart';

@immutable
class MyDayEntry {
  final String locationId;
  final DateTime when;

  const MyDayEntry(this.locationId, this.when);
}
