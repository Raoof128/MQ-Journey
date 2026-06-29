import 'dart:async';
import 'package:mq_journey/features/scan/domain/contracts/progress_api.dart';
import 'package:mq_journey/features/scan/domain/contracts/visited_state.dart';
import 'package:mq_journey/features/scan/domain/contracts/visit_event.dart';

class FakeProgressApi implements ProgressApi {
  final _visited = <String>{};
  final _controller = StreamController<VisitedState>.broadcast();

  @override
  Stream<VisitedState> watch(String locationId) async* {
    yield VisitedState(visited: _visited.contains(locationId), rewardEarned: false);
    yield* _controller.stream;
  }

  @override
  Future<void> recordVisit(VisitEvent event) async {
    _visited.add(event.locationId);
    _controller.add(const VisitedState(visited: true, rewardEarned: false));
  }

  void dispose() => _controller.close();
}
