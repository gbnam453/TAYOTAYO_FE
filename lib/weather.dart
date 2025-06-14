import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // 위치 정보를 가져오기 위한 패키지
import 'package:http/http.dart' as http; // HTTP 요청을 보내기 위한 패키지
import 'dart:convert'; // JSON 데이터 처리를 위한 패키지
import 'package:logger/logger.dart'; // 로그 출력을 위한 패키지
import 'weather_icon.dart'; // 날씨 상태에 따른 아이콘을 반환하는 사용자 정의 함수

// 날씨 정보를 보여주는 위젯
class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic> weatherData = {}; // 날씨 정보를 저장할 맵
  double? latitude; // 현재 위도
  double? longitude; // 현재 경도
  final apiKey = '15ee2cf13d5afe85b451fa051955bf7e'; // OpenWeatherMap API 키

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 위젯이 초기화될 때 현재 위치를 가져옴
  }

  // 현재 위치를 가져오는 함수
  Future<void> _getCurrentLocation() async {
    // 위치 서비스 사용 가능 여부 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { //비활성화된 경우
      return Future.error('위치 서비스가 비활성화되어 있습니다.'); //에러 반환
    }

    // 위치 권한 확인 및 요청
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) { //권한이 거부된 경우
      permission = await Geolocator.requestPermission(); //권한 요청
      if (permission == LocationPermission.denied) { //거부된 경우
        return Future.error('위치 권한이 거부되었습니다.'); //에러 반환
      }
    }

    // 영구적으로 거부된 경우 처리
    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구적으로 거부되었습니다.'); // 에러 반환
    }

    // 현재 위치 가져오기
    Position position =
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // 위치 상태 갱신 및 날씨 데이터 요청
    setState(() {
      latitude = position.latitude; //위도 저장
      longitude = position.longitude; //경도 저장
      fetchData(latitude!, longitude!); // 위도와 경도로 날씨 데이터 요청
    });
  }

  // 날씨 API 호출 함수
  Future<Map<String, dynamic>> fetchWeather(double lat, double lon, String apiKey) async {
    final response = await http.get(
      Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      ),
    );

    // 요청 성공 시
    if (response.statusCode == 200) {
      Logger logger = Logger(); //로그 객체 생성
      final encoder = JsonEncoder.withIndent(' '); // JSON 정렬
      final prettyJson = encoder.convert(response.body); //JSON 문자열 반환
      logger.d(prettyJson); // 로그 출력

      return json.decode(response.body); // JSON 문자열을 맵으로 변환하여 반환
    } else { //실패한 경우
      throw Exception('날씨 정보를 가져오지 못했습니다.');
    }
  }

  // 날씨 데이터를 가져와 상태 갱신
  Future<void> fetchData(double lat, double lon) async {
    try {
      Map<String, dynamic> data = await fetchWeather(lat, lon, apiKey);
      setState(() {
        weatherData = data; // 가져온 데이터를 상태에 저장
      });
    } catch (error) {
      print(error); // 에러 출력
    }
  }

  // 화면에 날씨 정보를 표시
  @override
  Widget build(BuildContext context) {
    return weatherData.isEmpty
    // 데이터가 없으면 로딩 표시
        ? const CircularProgressIndicator()
    // 데이터가 있으면 날씨 아이콘과 온도 표시
        : Column(
      mainAxisAlignment: MainAxisAlignment.center, //수직 정렬
      children: [
        Icon(
          getWeatherIconByCondition(weatherData["weather"][0]["main"]), // 날씨 상태에 따른 아이콘 표시
          size: 80, //아이콘 크기
          color: Colors.black, //아이콘 색상
        ),
        const SizedBox(height: 8), //간격
        Text(
          '기온: ${weatherData["main"]["temp"].toStringAsFixed(1)}°C', // 기온 소수점 1자리로 표시
          style: const TextStyle(fontSize: 18), //텍스트 스타일
        ),
      ],
    );
  }
}
