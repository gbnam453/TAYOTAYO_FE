import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:date_format/date_format.dart';
import 'package:timer_builder/timer_builder.dart';
import 'weather.dart'; // 날씨 위젯 파일
import 'busstop.dart'; // 버스 정보 페이지
import 'restaurantSearch.dart'; // 학식 정보 페이지

// 앱 시작점
void main() => runApp(MyApp());

// 최상위 앱 클래스, Cupertino 스타일 적용
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: MainScreen(), // 홈 화면으로 MainScreen 사용
      debugShowCheckedModeBanner: false, // 디버그 배너 제거
    );
  }
}

// 메인 홈 화면
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white, // 배경 흰색 설정
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
          children: [

            // 시간과 날씨 표시
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Column(
                children: [

                  // 실시간으로 시간 업데이트 (1초마다)
                  TimerBuilder.periodic(
                    const Duration(seconds: 1),
                    builder: (context) {
                      return Text(
                        formatDate(DateTime.now(), [hh, ':', nn, ':', ss, ' ', am]), // hh:mm:ss AM/PM 포맷
                        style: const TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 30), // 시간과 날씨 사이 여백

                  WeatherWidget(), // 날씨 위젯 호출 (현재 위치의 날씨 표시)
                ],
              ),
            ),

            // 기능 버튼 2개 (맛집 / 버스) 가로 정렬
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // 맛집 버튼
                  _buildIconButton(
                    icon: Icons.restaurant,
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => RestaurantSearchPage()), // restaurantSearch.dart 페이지로 이동
                      );
                    },
                  ),

                  SizedBox(width: 40), // 버튼 사이 간격

                  // 버스 버튼
                  _buildIconButton(
                    icon: Icons.directions_bus,
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => BusStopPage()), // busstop.dart 페이지로 이동
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 버튼 UI
  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap, // 탭 시 onTap 함수 실행
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.black), // 검정색 테두리
          borderRadius: BorderRadius.circular(16), // 모서리 둥글게
        ),
        child: Center(
          child: Icon(
            icon, // 아이콘 표시
            size: 72,
            color: CupertinoColors.black,
          ),
        ),
      ),
    );
  }
}
