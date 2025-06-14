import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'busSchedule.dart';

//네이버 API ID, 키
String API_KEY_ID = 'v5fmhtkemt';
String API_KEY = '7Mkwu25Ue2YgjRNsFdUetz0S1d9xJANRBkzV7kzk';

//위도 경도를 받기 위한 좌표계 클래스
class Coordinates {
  final String x;
  final String y;

  Coordinates(this.x, this.y);
}

// 네이버 geocode를 이용해서 위도 경도 받기
// 매개변수 주소
Future<Coordinates> getLocation({
  String? address,
}) async {
  final dio = Dio();
  final response = await dio.get(
    'https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=$address',
    queryParameters: {
    },
    options: Options(headers: {
      'X-NCP-APIGW-API-KEY-ID': '$API_KEY_ID',
      'X-NCP-APIGW-API-KEY': '$API_KEY',
      'Accept' : 'application/json',
    }),
  );
  if (response.statusCode == 200) {
    final json = jsonDecode(response.toString());

    final addresses = json['addresses'];
    final x = addresses[0]['x'];
    final y = addresses[0]['y'];

    return Coordinates(x,y);
  } else {
    print('에러: ${response.statusCode}');
    throw Exception("error");
  }
}

//네이버 길찾기 API 통신 코드
//출발지, 도착지, 정류장 번호, 방향을 받아서 출발지에서 도착지까지 걸리는 시간을 반환
Future getArriveDest({
  required Coordinates start,
  required Coordinates dest,
  required int startNum,
  required int destNum,
}) async {

  StringBuffer buffer = StringBuffer();
  Coordinates coordinates;
  Map<String, String>? way;

  //출발지와 도착지 사이의 정류장 위치를 받아서 경유지 쿼리 만들기
  if (startNum < destNum) {
    for (int i = startNum + 1; i < destNum; i++) {
      way = addressAtoC;
      // print("busstop:${way!.keys.elementAt(i)}");
      coordinates = await getLocation(address: way.values.elementAt(i));
      String str = '${coordinates.x},${coordinates.y}';
      buffer.write('$str');
      if (i < destNum - 1) {
        buffer.write('|');
      }
    }
  } else {
    for (int i = startNum - 1; i > destNum; i--) {
      // print("busstop:${way!.keys.elementAt(i)}");
      way = addressCtoA;
      coordinates = await getLocation(address: way!.values.elementAt(i));
      String str = '${coordinates.x},${coordinates.y}';
      buffer.write('$str');
      if (i > destNum + 1) {
        buffer.write('|');
      }
    }
  }

  final waypoint = buffer.toString();
  // print(waypoint);

  //API 통신 코드
  final dio = Dio();
  final response = await dio.get(
    'https://maps.apigw.ntruss.com/map-direction-15/v1/driving',
    queryParameters: {
      'start': '${start.x},${start.y}',  // 경도, 위도
      'goal': '${dest.x},${dest.y}', // 목적지 경도, 위도
      'waypoints' : waypoint,
      'option': 'trafast', // 빠른 길: trafast, 일반 길: tracom, 최단 거리: trawalk
    },
    options: Options(headers: {
      'X-NCP-APIGW-API-KEY-ID': '$API_KEY_ID',
      'X-NCP-APIGW-API-KEY': '$API_KEY',
    }),
  );
  //통신 성공 후 파싱
  if (response.statusCode == 200) {
    final json = jsonDecode(response.toString());

    // debugJson(json);

    final route = json['route'];
    final trafast = route['trafast'];
    final summary = trafast[0]['summary'];
    var arrivalTime = summary['duration'];

    final section = trafast[0]['section'];
    final totalCongestion = section
        .map((e){
      var value = e['congestion'] as int;
      // print('congestion 값: $value');
      return value;
    }).reduce((a, b) => a + b);
    print(totalCongestion);
    // 도착시간을 밀리초에서 분으로 변환
    arrivalTime = arrivalTime / 60000.0;
    return arrivalTime;
  } else {
    print('에러: ${response.statusCode}');
    return response.statusCode;
  }
}

//Json 출력용
void debugJson(dynamic json){
  Logger logger = Logger();
  final encoder = JsonEncoder.withIndent('  ');
  final prettyJson = encoder.convert(json);
  logger.d(prettyJson);
}




