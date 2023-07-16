import 'package:RoutineCare/datetime/date_time.dart';
import 'package:hive_flutter/hive_flutter.dart';
final _myBox = Hive.box("Routine_Database");
class RoutineDatabase {
  List todaysRoutineList = [];
  Map<DateTime, int> heatMapDataSet = {};
  void createDefaultData() {
    todaysRoutineList = [
      ["Moisturizer", false],
      ["Rose Water Tonic", false],
      ["Pore Firming", false],
      ["Red Peeling", false],
      ["Drink 3 Gallon Water", false],
    ];
    _myBox.put("START_DATE", todaysDateFormatted());
  }
  void loadData() {
    if (_myBox.get(todaysDateFormatted()) == null) {
      todaysRoutineList = _myBox.get("CURRENT_Routine_LIST");
      for (int i = 0; i < todaysRoutineList.length; i++) {
        todaysRoutineList[i][1] = false;
      }
    }
    else {
      todaysRoutineList = _myBox.get(todaysDateFormatted());
    }
  }
  void updateDatabase() {
    _myBox.put(todaysDateFormatted(), todaysRoutineList);
    _myBox.put("CURRENT_Routine_LIST", todaysRoutineList);
    calculateRoutinePercentages();
    loadHeatMap();
  }
  void calculateRoutinePercentages() {
    int countCompleted = 0;
    for (int i = 0; i < todaysRoutineList.length; i++) {
      if (todaysRoutineList[i][1] == true) {
        countCompleted++;
      }
    }
    String percent = todaysRoutineList.isEmpty
        ? '0.0'
        : (countCompleted / todaysRoutineList.length).toStringAsFixed(1);
    _myBox.put("PERCENTAGE_SUMMARY_${todaysDateFormatted()}", percent);
  }
  void loadHeatMap() {
    DateTime startDate = createDateTimeObject(_myBox.get("START_DATE"));
    int daysInBetween = DateTime.now().difference(startDate).inDays;
    for (int i = 0; i < daysInBetween + 1; i++) {
      String yyyymmdd = convertDateTimeToString(
        startDate.add(Duration(days: i)),
      );
      double strengthAsPercent = double.parse(
        _myBox.get("PERCENTAGE_SUMMARY_$yyyymmdd") ?? "0.0",
      );
      int year = startDate.add(Duration(days: i)).year;
      int month = startDate.add(Duration(days: i)).month;
      int day = startDate.add(Duration(days: i)).day;
      final percentForEachDay = <DateTime, int>{
        DateTime(year, month, day): (10 * strengthAsPercent).toInt(),
      };
      heatMapDataSet.addEntries(percentForEachDay.entries);
      print(heatMapDataSet);
    }
  }
}
