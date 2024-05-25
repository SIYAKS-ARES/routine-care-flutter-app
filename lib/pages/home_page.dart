import 'package:flutter/material.dart';
import 'package:routine_care/components/routine_tile.dart';
import 'package:routine_care/components/month_summary.dart';
import 'package:routine_care/components/my_fab.dart';
import 'package:routine_care/components/my_alert_box.dart';
import 'package:routine_care/data/routine_database.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RoutineDatabase db = RoutineDatabase();
  final _myBox = Hive.box("Routine_Database");
  @override
  void initState() {
    if (_myBox.get("CURRENT_Routine_LIST") == null) {
      db.createDefaultData();
    } else {
      db.loadData();
    }
    db.updateDatabase();
    super.initState();
  }

  void checkBoxTapped(bool? value, int index) {
    setState(() {
      db.todaysRoutineList[index][1] = value;
    });
    db.updateDatabase();
  }

  final _newRoutineNameController = TextEditingController();
  void createNewRoutine() {
    showDialog(
      context: context,
      builder: (context) {
        return MyAlertBox(
          controller: _newRoutineNameController,
          hintText: 'Create A New Routine...',
          onSave: saveNewRoutine,
          onCancel: cancelDialogBox,
        );
      },
    );
  }

  void saveNewRoutine() {
    setState(() {
      db.todaysRoutineList.add([_newRoutineNameController.text, false]);
    });
    _newRoutineNameController.clear();
    Navigator.of(context).pop();
    db.updateDatabase();
  }

  void cancelDialogBox() {
    _newRoutineNameController.clear();
    Navigator.of(context).pop();
  }

  void openRoutineSettings(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return MyAlertBox(
          controller: _newRoutineNameController,
          hintText: db.todaysRoutineList[index][0],
          onSave: () => saveExistingRoutine(index),
          onCancel: cancelDialogBox,
        );
      },
    );
  }

  void saveExistingRoutine(int index) {
    setState(() {
      db.todaysRoutineList[index][0] = _newRoutineNameController.text;
    });
    _newRoutineNameController.clear();
    Navigator.pop(context);
    db.updateDatabase();
  }

  void deleteRoutine(int index) {
    setState(() {
      db.todaysRoutineList.removeAt(index);
    });
    db.updateDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[
          300], // const Color.fromARGB(255, 249, 92, 1) Orange for Retro theme
      floatingActionButton: MyFloatingActionButton(onPressed: createNewRoutine),
      body: ListView(
        children: [
          MonthlySummary(
            datasets: db.heatMapDataSet,
            startDate: _myBox.get("START_DATE"),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: db.todaysRoutineList.length,
            itemBuilder: (context, index) {
              return RoutineTile(
                RoutineName: db.todaysRoutineList[index][0],
                RoutineCompleted: db.todaysRoutineList[index][1],
                onChanged: (value) => checkBoxTapped(value, index),
                settingsTapped: (context) => openRoutineSettings(index),
                deleteTapped: (context) => deleteRoutine(index),
              );
            },
          )
        ],
      ),
    );
  }
}
