import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';            // Material 위젯 사용 (Card 등)
import 'package:flutter/services.dart';            // JSON 불러오기용
import 'package:intl/intl.dart';                   // 시간 포맷팅
import 'package:webview_flutter/webview_flutter.dart';  // 웹뷰 플러그인
import 'busSchedule.dart';
import 'calcTime.dart';
import 'getTrafficTime.dart';

/// 결과 페이지: 출발지~도착지까지의 다음 셔틀 시간, 예상 소요 시간, 도착 시간 출력
class ResultPage extends StatefulWidget {
  final int departureIndex;
  final String departureName; // 영문
  final int arrivalIndex;
  final String arrivalName;   // 영문

  ResultPage({
    required this.departureIndex,
    required this.departureName,
    required this.arrivalIndex,
    required this.arrivalName,
  });

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String? _departureTime;    // 다음 셔틀 출발 시간
  String? _travelDuration;   // 소요 시간
  String? _arrivalTime;      // 도착 예상 시간
  bool _isLoading = true;    // 로딩 상태

  // 영문 → 한글 정류장 이름 매핑
  static const Map<String, String> _stationNameMap = {
    'Asan Campus': '아산캠퍼스',
    'Cheonan-Asan Station': '천안아산역',
    'Ssangyong 2-dong': '쌍용2동',
    'Chungmu Hospital': '충무병원',
    'Cheonan Station': '천안역',
    'Cheonan Terminal': '천안터미널',
    'Cheonan Campus': '천안캠퍼스',
  };

  // 한글 역명 → 카카오 지도 링크
  static const Map<String, String> _stationUrlMap = {
    '아산캠퍼스': 'https://map.kakao.com/link/map/호서대학교 아산캠퍼스,36.736388,127.0751324',
    '천안아산역': 'https://map.kakao.com/link/map/천안아산역,36.794123,127.104567',
    '쌍용2동': 'https://map.kakao.com/link/map/쌍용2동,36.793456,127.123789',
    '충무병원': 'https://map.kakao.com/link/map/충무병원,36.801234,127.142345',
    '천안역': 'https://map.kakao.com/link/map/천안역,36.815678,127.156789',
    '천안터미널': 'https://map.kakao.com/link/map/천안터미널,36.819908,127.1565357',
    '천안캠퍼스': 'https://map.kakao.com/link/map/호서대학교 천안캠퍼스,36.8279104,127.1833844',
  };

  // 영어 정류장명을 한글로 변환
  String _toKorean(String eng) => _stationNameMap[eng] ?? eng;

  @override
  void initState() {
    super.initState();
    _loadAndComputeTimes(); // 초기 데이터 불러오기
  }

  /// JSON 파일에서 셔틀 시간표 로드
  Future<busScheduleDB> _loadShuttleSchedule() async {
    final jsonStr =
        await rootBundle.loadString('assets/ShuttleScheduleDB.json');
    final jsonMap = jsonDecode(jsonStr);
    return busScheduleDB.fromJson(jsonMap);
  }

  /// 출발/도착 정류장과 시간계산 함수
  void _loadAndComputeTimes() async {
    final db = await _loadShuttleSchedule();
    int startNum = widget.departureIndex;
    String startStop = widget.departureName;
    int destNum = widget.arrivalIndex;
    String destStop = widget.arrivalName;
    final int dir = (startNum < destNum) ? 0 : 1;

    // 다음 셔틀 출발 시간 계산
    String arriveTimeString;
    if (startNum == 0 || startNum == 6) {
      arriveTimeString = getNextBusTime(
            stopName: startStop,
            schedules: getSchedules(dir: dir, busSche: db),
          ) ??
          "00:00";
    } else {
      arriveTimeString = (await getNextTime(
            stopName: startStop,
            schedules: getSchedules(dir: dir, busSche: db),
          )) ??
          "00:00";
    }

    // 실제 위치 기반 도착 시간 계산
    Coordinates startXY = await getLocation(address: getAddress(startStop, dir));
    Coordinates destXY = await getLocation(address: getAddress(destStop, dir));
    double busTravelTime = await getArriveDest(
      startNum: startNum,
      destNum: destNum,
      start: startXY,
      dest: destXY,
    );

    // 도착 시간 계산
    DateFormat format = DateFormat.Hm();
    DateTime parsedDeparture = format.parse(arriveTimeString);
    DateTime computedArrival =
        parsedDeparture.add(Duration(minutes: busTravelTime.round()));
    String finalArrivalString = DateFormat.Hm().format(computedArrival);

    setState(() {
      _departureTime = arriveTimeString;
      _travelDuration = "${busTravelTime.round()}분";
      _arrivalTime = finalArrivalString;
      _isLoading = false;
    });
  }

  /// 카카오 지도 웹뷰 열기
  void _openWebView(String url) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => WebViewPage(initialUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String titleText =
        '${_toKorean(widget.departureName)} > ${_toKorean(widget.arrivalName)}';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: '뒤로',
        middle: Text(
          titleText,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(child: CupertinoActivityIndicator(radius: 20))
            : _buildContent(context),
      ),
    );
  }

  /// 결과 화면 구성
  Widget _buildContent(BuildContext context) {
    final String departureKorean = _toKorean(widget.departureName);
    final String arrivalKorean = _toKorean(widget.arrivalName);

    return SingleChildScrollView(
      child: Column(
        children: [
          // 일러스트 이미지
          Image.network(
            'https://img.freepik.com/free-vector/city-bus-concept-illustration_114360-11574.jpg?semt=ais_hybrid&w=740',
            fit: BoxFit.fitWidth,
            width: double.infinity,
          ),

          SizedBox(height: 24),

          // 시간 정보 출력 카드 + 점선 배경
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              children: [
                // 점선 배경
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40, top: 68),
                    child: CustomPaint(
                      painter: _VerticalDashedLinePainter(),
                    ),
                  ),
                ),

                // 출발지~도착지 카드 및 시간
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final url = _stationUrlMap[departureKorean];
                        if (url != null) _openWebView(url);
                      },
                      child: _StepCard(
                        icon: Icons.location_on,
                        iconColor: Colors.blueAccent,
                        label: departureKorean,
                        time: _departureTime,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(width: 56), // 점선 오른쪽에 배치
                        Text(
                          _travelDuration ?? '',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        final url = _stationUrlMap[arrivalKorean];
                        if (url != null) _openWebView(url);
                      },
                      child: _StepCard(
                        icon: Icons.flag,
                        iconColor: Colors.green,
                        label: arrivalKorean,
                        time: _arrivalTime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 출발지/도착지 카드 UI
class _StepCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? time;

  const _StepCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            if (time != null)
              Text(
                time!,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
          ],
        ),
      ),
    );
  }
}

/// 점선 라인 그리기용 커스텀 페인터
class _VerticalDashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double dx = 0.0;
    double startY = 0;
    final dashHeight = 6.0;
    final dashSpace = 6.0;
    final totalHeight = size.height;

    // 점선을 일정 간격으로 그림
    while (startY < totalHeight) {
      double segmentHeight = (startY + dashHeight > totalHeight)
          ? (totalHeight - startY)
          : dashHeight;
      canvas.drawLine(
        Offset(dx, startY),
        Offset(dx, startY + segmentHeight),
        paintLine,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) => false;
}

/// 웹뷰 페이지
class WebViewPage extends StatefulWidget {
  final String initialUrl;

  WebViewPage({required this.initialUrl});

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoadingPage = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: '뒤로',
        middle: Text('지도 보기', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoadingPage)
              Center(child: CupertinoActivityIndicator(radius: 20)),
          ],
        ),
      ),
    );
  }
}