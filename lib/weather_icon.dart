import 'package:flutter/material.dart';

//날씨 상태 문자열을 받아 아이콘을 받환하는 함수
IconData getWeatherIconByCondition(String condition) {
  switch (condition.toLowerCase()) { //입력된 날씨 상태 문자열을 소문자로 변환
    case 'thunderstorm': //천둥번개인 경우
      return Icons.flash_on; // 천둥 아이콘 반환
    case 'drizzle': //이슬비인 경우
      return Icons.grain; // 이슬비 아이콘 반환
    case 'rain': //비인 경우
      return Icons.beach_access; // 비 아이콘 반환
    case 'snow': //눈인 경우
      return Icons.ac_unit; // 눈 아이콘 반환
    case 'haze': //안개인 경우
      return Icons.blur_on; // 안개 아이콘 반환
    case 'smoke': //연기인 경우
      return Icons.smoking_rooms; // 연기 아이콘 반환
    case 'ash': //먼지인 경우
      return Icons.cloud; // 먼지 아이콘 반환
    case 'tornado': //토네이도인 경우
      return Icons.warning; // 토네이도 아이콘 반환
    case 'clear': //맑은 날씨인 경우
      return Icons.wb_sunny; // 맑음 아이콘 반환
    case 'clouds': //구름인 경우
      return Icons.cloud; // 구름 아이콘 반환
    default: //위 조건들에 해당하지 않는 경우
      return Icons.help_outline; // 알 수 없는 상태
  }
}
