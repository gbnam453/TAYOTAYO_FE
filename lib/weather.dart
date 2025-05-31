import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'weather_icon.dart'; // ← 날씨 상태별 아이콘 매핑 함수

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic> weatherData = {};
  double? latitude;
  double? longitude;
  final apiKey = '15ee2cf13d5afe85b451fa051955bf7e';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스가 비활성화되어 있습니다.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구적으로 거부되었습니다.');
    }

    Position position =
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      fetchData(latitude!, longitude!);
    });
  }

  Future<Map<String, dynamic>> fetchWeather(double lat, double lon, String apiKey) async {
    final response = await http.get(
      Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      ),
    );

    if (response.statusCode == 200) {
      Logger logger = Logger();
      final encoder = JsonEncoder.withIndent(' ');
      final prettyJson = encoder.convert(response.body);
      logger.d(prettyJson);

      return json.decode(response.body);
    } else {
      throw Exception('날씨 정보를 가져오지 못했습니다.');
    }
  }

  Future<void> fetchData(double lat, double lon) async {
    try {
      Map<String, dynamic> data = await fetchWeather(lat, lon, apiKey);
      setState(() {
        weatherData = data;
      });
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return weatherData.isEmpty
        ? const CircularProgressIndicator()
        : Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          getWeatherIconByCondition(weatherData["weather"][0]["main"]),
          size: 80,
          color: Colors.black,
        ),
        const SizedBox(height: 8),
        Text(
          '기온: ${weatherData["main"]["temp"].toStringAsFixed(1)}°C', // ← 소수점 1자리로 표시
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
