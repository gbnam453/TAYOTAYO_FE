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
  final Map<String, String> way = dir == 0 ? addressAtoC : addressCtoA;

  if(dir == 1){
    startNum = startNum % 6;
    destNum = destNum % 6;
  }
  print(startNum);
  print(destNum);
  if((startNum - destNum) >= 2) {
    for (int i = startNum; i < destNum; i++) {
      print("test:${way.keys.elementAt(i)}");
      coordinates = await getLocation(address: way.values.elementAt(i));
      String str = '${coordinates.x},${coordinates.y}';
      buffer.write('$str');
      if (i < destNum - 1) {
        buffer.write('|');
      }
    }
  }
  final waypoint = buffer.toString();
  print(waypoint);

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

    // Logger logger = Logger();
    // final encoder = JsonEncoder.withIndent('  ');
    // final prettyJson = encoder.convert(json);
    // logger.d(prettyJson);

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

Future getArriveBus({
  required Coordinates start,
  required Coordinates dest,
  required int stopNum
}) async {

  StringBuffer buffer = StringBuffer();
  Coordinates coordinates;

  for (int i = 1; i < stopNum; i++) {
    print(addressAtoC.keys.elementAt(i));
    coordinates = await getLocation(address:addressAtoC.values.elementAt(i));
    String str = '${coordinates.x},${coordinates.y}';
    buffer.write('$str');
    if (i < stopNum - 1) {
      buffer.write('|');
    }
  }
  final waypoint = buffer.toString();
  print(waypoint);

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

    // Logger logger = Logger();
    // final encoder = JsonEncoder.withIndent('  ');
    // final prettyJson = encoder.convert(json);
    // logger.d(prettyJson);

    final route = json['route'];
    final trafast = route['trafast'];
    final summary = trafast[0]['summary'];
    final arrivalTime = summary['duration'];
    print(arrivalTime / 60000);

    final section = trafast[0]['section'];
    final totalCongestion = section
        .map((e){
      var value = e['congestion'] as int;
      // print('congestion 값: $value');
      return value;
    }).reduce((a, b) => a + b);
    print(totalCongestion);

    return arrivalTime / 60000.0;
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




