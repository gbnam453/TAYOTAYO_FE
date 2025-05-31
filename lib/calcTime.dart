import 'busSchedule.dart';
import 'getTrafficTime.dart';
import 'package:intl/intl.dart';

// 가장 가까운 다음 셔틀 시간 구하기
String? getNextBusTime({
  required List<busSchedule> schedules,
  required String stopName,
}) {
  final now = DateTime.now();
  // 1. 해당 정류장의 시간들만 추출
  List<String> times = schedules
      .map((s) => s.stops[stopName])
      .where((t) => t != null)
      .cast<String>()
      .toList();

  // 2. 시간을 DateTime으로 파싱해서 비교
  for (String time in times) {
    DateTime timeToday = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(time.split(":")[0]),
      int.parse(time.split(":")[1]),
    );
    if (timeToday.isAfter(now)) {
      final str = DateFormat.Hm().format(timeToday);
      return str; // 아직 지나지 않은 가장 빠른 시간 반환
    } else{
      DateTime timeToday = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(times.first.split(":")[0]),
        int.parse(times.first.split(":")[1]),
      );
      final str = DateFormat.Hm().format(timeToday);
      return str;
    }
  }
}

Future<String?> getNextTime({
  required List<busSchedule> schedules,
  required String stopName,
}) async {
  final now = DateTime.now();
  DateTime? dbTime;

  // 1. 해당 정류장의 시간들만 추출
  List<String> times = schedules
      .map((s) => s.stops[stopName])
      .where((t) => t != null)
      .cast<String>()
      .toList();
  // 2. 시간을 DateTime으로 파싱해서 비교
  for (String time in times) {
    DateTime timeToday = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(time.split(":")[0]),
      int.parse(time.split(":")[1]),
    );
    if (timeToday.isAfter(now)) {
      dbTime = timeToday;
      break;// 아직 지나지 않은 가장 빠른 시간 반환
    } else{
      DateTime timeToday = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(times.first.split(":")[0]),
        int.parse(times.first.split(":")[1]),
      );
      dbTime = timeToday;
    }
  }
  final firstStop = schedules.first.stops.keys.first;
  final dir = firstStop == "Asan Campus" ? 0 : 1;
  final schoolXY = await getLocation(address: getAddress(firstStop, dir));
  final startXY = await getLocation(address: getAddress(stopName, dir));
  final stopNum = schedules.first.stops.keys.toList().indexOf(stopName);

  var time = await getArriveDest(dir:dir, startNum: 0, destNum: stopNum, start: schoolXY, dest: startXY);
  DateTime apiTime = now.add(Duration(minutes: time.round()));
  Duration? timediff = dbTime?.difference(apiTime);

  if(timediff!.inMinutes > 10){
    final str = DateFormat.Hm().format(apiTime);
    return str;
  } else{
    final str = DateFormat.Hm().format(dbTime!);
    return str;
  }
}
