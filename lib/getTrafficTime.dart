import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'busSchedule.dart';

Future getArriveDest({
  required Coordinates start,
  required Coordinates dest,
  required int startNum,
  required int destNum,
  required int dir
}) async {

  StringBuffer buffer = StringBuffer();
  Coordinates coordinates;
  Map<String, String>? way = addressAtoC;
  switch(dir){
    case 0: way = addressAtoC;
    case 1: way = addressCtoA;
    default: way = null; break;
  }

  if (startNum < destNum) {
    for (int i = startNum + 1; i < destNum; i++) {
      // print("busstop:${way!.keys.elementAt(i)}");
      coordinates = await getLocation(address: way!.values.elementAt(i));
      String str = '${coordinates.x},${coordinates.y}';
      buffer.write('$str');
      if (i < destNum - 1) {
        buffer.write('|');
      }
    }
  } else {
    for (int i = startNum - 1; i > destNum; i--) {
      // print("busstop:${way!.keys.elementAt(i)}");
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
      'X-NCP-APIGW-API-KEY-ID': 'v5fmhtkemt',
      'X-NCP-APIGW-API-KEY': '7Mkwu25Ue2YgjRNsFdUetz0S1d9xJANRBkzV7kzk',
    }),
  );

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
    arrivalTime = arrivalTime / 60000.0;
    return arrivalTime;
  } else {
    print('에러: ${response.statusCode}');
    return response.statusCode;
  }
}

class Coordinates {
  final String x;
  final String y;

  Coordinates(this.x, this.y);
}

Future<Coordinates> getLocation({
  String? address,
}) async {
  final dio = Dio();
  final response = await dio.get(
    'https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=$address',
    queryParameters: {
    },
    options: Options(headers: {
      'X-NCP-APIGW-API-KEY-ID': 'v5fmhtkemt',
      'X-NCP-APIGW-API-KEY': '7Mkwu25Ue2YgjRNsFdUetz0S1d9xJANRBkzV7kzk',
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

void debugJson(dynamic json){
  Logger logger = Logger();
  final encoder = JsonEncoder.withIndent('  ');
  final prettyJson = encoder.convert(json);
  logger.d(prettyJson);
}




