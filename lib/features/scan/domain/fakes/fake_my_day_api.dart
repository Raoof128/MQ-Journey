import 'package:mq_journey/features/scan/domain/contracts/my_day_api.dart';
import 'package:mq_journey/features/scan/domain/contracts/my_day_entry.dart';

class FakeMyDayApi implements MyDayApi {
  final added = <MyDayEntry>[];

  @override
  Future<void> addToDay(MyDayEntry entry) async {
    added.add(entry);
  }
}
