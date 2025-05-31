import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'busSchedule.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'getTrafficTime.dart';
import 'calcTime.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {

  var startNum = 1;
  var startStop = 'Cheonan-Asan Station';
  var destNum = 5;
  var destStop = 'Cheonan Terminal';

  late Future<busScheduleDB> futureSchedule;

  Future<busScheduleDB> loadShuttleSchedule() async {
    final jsonStr = await rootBundle.loadString('assets/ShuttleScheduleDB.json');
    final jsonMap = jsonDecode(jsonStr);
    return busScheduleDB.fromJson(jsonMap);
  }

  @override
  void initState() {
    super.initState();
    getBusTime();
  }

  void getBusTime(){
    futureSchedule = loadShuttleSchedule();
    String? arriveTime;

    loadShuttleSchedule().then((db) async {
      final int dir = startNum < destNum ? 0 : 1;
      if(startNum == 0 || startNum == 6){ // No Api
        print("no api");
        arriveTime = getNextBusTime(stopName: startStop,schedules: getSchedules(dir: dir, busSche: db));
      }
      else{
        arriveTime = await getNextTime(stopName: startStop,schedules: getSchedules(dir: dir, busSche: db));
      }
      print("arriveTime:$arriveTime");

      Coordinates startXY = await getLocation(address: getAddress(startStop, dir));
      Coordinates destXY = await getLocation(address: getAddress(destStop, dir));

      final busTime = await getArriveDest(dir: dir, startNum : startNum, destNum: destNum, start: startXY, dest: destXY);
      print("busTime$busTime");

      DateFormat format = DateFormat.Hm();
      DateTime time = format.parse(arriveTime!);
      DateTime newTime = time.add(Duration(minutes: busTime.round()));
      String result = DateFormat.Hm().format(newTime);

      print("finalTime: $result");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('You have pushed the button this many times:'),
            ],
          ),
        )
    );
  }
}
