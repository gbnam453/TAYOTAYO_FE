import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'busSchedule.dart';
import 'calcTime.dart';
import 'getTrafficTime.dart';

class ResultPage extends StatefulWidget {
  final int departureIndex;
  final String departureName;
  final int arrivalIndex;
  final String arrivalName;

  ResultPage({
    required this.departureIndex,
    required this.departureName,
    required this.arrivalIndex,
    required this.arrivalName,
  });

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {

  @override
  void initState() {
    super.initState();
    getBusTime();
  }

  late Future<busScheduleDB> futureSchedule;

  Future<busScheduleDB> loadShuttleSchedule() async {
    final jsonStr = await rootBundle.loadString('assets/ShuttleScheduleDB.json');
    final jsonMap = jsonDecode(jsonStr);
    return busScheduleDB.fromJson(jsonMap);
  }

  void getBusTime(){
    futureSchedule = loadShuttleSchedule();
    String? arriveTime;

    var startNum = widget.departureIndex;
    var startStop = widget.departureName;
    var destNum = widget.arrivalIndex;
    var destStop = widget.arrivalName;
    // print(startNum);
    // print(startStop);
    // print(destNum);
    // print(destStop);

    loadShuttleSchedule().then((db) async {
      final int dir = startNum < destNum ? 0 : 1;
      print("dir:$dir");
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

      final busTime = await getArriveDest(startNum : startNum, destNum: destNum, start: startXY, dest: destXY);
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('결과 화면'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('출발지: ${widget.departureName} (${widget.departureIndex})', style: TextStyle(fontSize: 20)),
              SizedBox(height: 20),
              Text('도착지: ${widget.arrivalName} (${widget.arrivalIndex})', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
