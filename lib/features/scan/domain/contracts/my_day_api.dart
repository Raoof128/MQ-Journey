import 'package:mq_journey/features/scan/domain/contracts/my_day_entry.dart';

abstract class MyDayApi {
  Future<void> addToDay(MyDayEntry entry);
}
