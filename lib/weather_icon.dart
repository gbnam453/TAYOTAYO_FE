import 'package:flutter/material.dart';

IconData getWeatherIconByCondition(String condition) {
  switch (condition.toLowerCase()) {
    case 'thunderstorm':
      return Icons.flash_on; // 천둥
    case 'drizzle':
      return Icons.grain; // 이슬비
    case 'rain':
      return Icons.beach_access; // 비
    case 'snow':
      return Icons.ac_unit; // 눈
    case 'haze':
      return Icons.blur_on; // 안개
    case 'smoke':
      return Icons.smoking_rooms; // 연기
    case 'ash':
      return Icons.cloud; // 먼지/모래/재
    case 'squall':
    case 'tornado':
      return Icons.warning; // 돌풍/토네이도
    case 'clear':
      return Icons.wb_sunny; // 맑음
    case 'clouds':
      return Icons.cloud; // 구름
    default:
      return Icons.help_outline; // 알 수 없는 상태
  }
}
