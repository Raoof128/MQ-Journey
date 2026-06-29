import 'package:flutter/foundation.dart';

@immutable
class VisitedState {
  final bool visited;
  final bool rewardEarned;

  const VisitedState(this.visited, this.rewardEarned);
}
