import 'busSchedule.dart';
import 'getTrafficTime.dart';
import 'package:intl/intl.dart';

// 맨 끝 정류장에서 다음 셔틀 시간 구하기
// 매개변수 스케줄 객체, 도착지 정류장
String? getNextBusTime({
  required List<busSchedule> schedules,
  required String stopName,
}) {
  final now = DateTime.now();
  String? time = null;
  //도착 정류장의 시간들만 추출
  List<String> times = schedules
      .map((s) => s.stops[stopName])
      .where((t) => t != null)
      .cast<String>()
      .toList();

  //시간을 DateTime으로 파싱해서 비교
  for (String time in times) {
    DateTime timeToday = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(time.split(":")[0]),
      int.parse(time.split(":")[1]),
    );

    if (timeToday.isAfter(now)) {
      time = DateFormat.Hm().format(timeToday);
      return time; // 현재 시간이 지난 다음 시간 반환
    }
  }
  if(time == null) {
    DateTime timeToday = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(times.first.split(":")[0]),
      int.parse(times.first.split(":")[1]),
    );
    final str = DateFormat.Hm().format(timeToday);
    return str; // 시간표에 없으면 첫 차 시간 반환
  }
}

// 맨 끝 정류장에서 다음 셔틀 시간 구하기
// 매개변수 스케줄 객체, 도착지 정류장
Future<String?> getNextTime({
  required List<busSchedule> schedules,
  required String stopName,
}) async {
  final now = DateTime.now();
  //시간표에서 추출한 도착시간 변수
  DateTime? dbTime = null;

  //도착 정류장의 시간들만 추출
  List<String> times = schedules
      .map((s) => s.stops[stopName])
      .where((t) => t != null)
      .cast<String>()
      .toList();

  //시간을 DateTime으로 파싱해서 비교
  for (String time in times) {
    DateTime timeToday = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(time.split(":")[0]),
      int.parse(time.split(":")[1]),
    );
    if (timeToday.isAfter(now)) {
      dbTime = timeToday; // 현재 시간 이후 다음 오는 버스 시간
      break;
    }
  }

  if (dbTime == null){
    DateTime timeToday = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(times.first.split(":")[0]),
      int.parse(times.first.split(":")[1]),
    );
    dbTime = timeToday; // 시간표에 없으면 첫 차 시간 반환
  }

  //네이버 api를 이용해서 각 끝 정류장에서 오는 데 걸리는 실제 시간 구하기
  final firstStop = schedules.first.stops.keys.first;
  final dir = firstStop == "Asan Campus" ? 0 : 1;
  final schoolXY = await getLocation(address: getAddress(firstStop, dir));
  final startXY = await getLocation(address: getAddress(stopName, dir));
  final stopNum = schedules.first.stops.keys.toList().indexOf(stopName);

  var time = await getArriveDest(startNum: 0, destNum: stopNum, start: schoolXY, dest: startXY);
  //네이버 api를 통해서 구한 시간
  DateTime apiTime = now.add(Duration(minutes: time.round()));
  Duration? timediff = dbTime?.difference(apiTime);

  //서로의 시간 차이를 통해서 격차가 크지 않으면 시간표 시간 사용, 아니면 api 시간 사용
  if(timediff!.inMinutes.abs() > 10){ //lmg
    final str = DateFormat.Hm().format(apiTime);
    return str;
  } else{
    final str = DateFormat.Hm().format(dbTime!);
    return str;
  }
}
