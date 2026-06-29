import 'package:mq_journey/features/scan/domain/contracts/visited_state.dart';
import 'package:mq_journey/features/scan/domain/contracts/visit_event.dart';

abstract class ProgressApi {
  Stream<VisitedState> watch(String locationId);
  Future<void> recordVisit(VisitEvent event);
}
