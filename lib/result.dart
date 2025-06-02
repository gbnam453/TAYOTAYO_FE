// lib/result.dart

import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';            // Material 위젯 사용
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';  // ← 반드시 추가
import 'busSchedule.dart';
import 'calcTime.dart';
import 'getTrafficTime.dart';

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
  String? _departureTime;
  String? _travelDuration;
  String? _arrivalTime;
  bool _isLoading = true;

  // 영문 → 한글 매핑
  static const Map<String, String> _stationNameMap = {
    'Asan Campus': '아산캠퍼스',
    'Cheonan-Asan Station': '천안아산역',
    'Ssangyong 2-dong': '쌍용2동',
    'Chungmu Hospital': '충무병원',
    'Cheonan Station': '천안역',
    'Cheonan Terminal': '천안터미널',
    'Cheonan Campus': '천안캠퍼스',
  };

  // 한글 역명 → 카카오지도 링크 매핑
  static const Map<String, String> _stationUrlMap = {
    '아산캠퍼스': 'https://kko.kakao.com/61e0wlaR0B',
    '천안아산역': 'https://kko.kakao.com/sOzl9IKTs4',
    '쌍용2동': 'https://kko.kakao.com/SKTdC2oRDm',
    '충무병원': 'https://kko.kakao.com/wcRiin_WCV',
    '천안역': 'https://kko.kakao.com/UuK4gJfkeM',
    '천안터미널': 'https://kko.kakao.com/8KPtXVjKAT',
    '천안캠퍼스': 'https://kko.kakao.com/o-5m0LiiMJ',
  };

  String _toKorean(String eng) => _stationNameMap[eng] ?? eng;

  @override
  void initState() {
    super.initState();
    _loadAndComputeTimes();
  }

  Future<busScheduleDB> _loadShuttleSchedule() async {
    final jsonStr =
    await rootBundle.loadString('assets/ShuttleScheduleDB.json');
    final jsonMap = jsonDecode(jsonStr);
    return busScheduleDB.fromJson(jsonMap);
  }

  void _loadAndComputeTimes() async {
    final db = await _loadShuttleSchedule();
    int startNum = widget.departureIndex;
    String startStop = widget.departureName;
    int destNum = widget.arrivalIndex;
    String destStop = widget.arrivalName;
    final int dir = (startNum < destNum) ? 0 : 1;

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

    Coordinates startXY = await getLocation(address: getAddress(startStop, dir));
    Coordinates destXY = await getLocation(address: getAddress(destStop, dir));
    double busTravelTime = await getArriveDest(
      startNum: startNum,
      destNum: destNum,
      start: startXY,
      dest: destXY,
    );

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

  Widget _buildContent(BuildContext context) {
    final String departureKorean = _toKorean(widget.departureName);
    final String arrivalKorean   = _toKorean(widget.arrivalName);

    return SingleChildScrollView(
      child: Column(
        children: [
          // 상단 일러스트
          Image.network(
            'https://img.freepik.com/free-vector/city-bus-concept-illustration_114360-11574.jpg?semt=ais_hybrid&w=740',
            fit: BoxFit.fitWidth,
            width: double.infinity,
          ),

          SizedBox(height: 24),

          // 점선 배경 + 카드 배치
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    // top:68 으로 두어 점선이 출발 카드 뒤에 가려짐
                    padding: const EdgeInsets.only(left: 40, top: 68),
                    child: CustomPaint(
                      painter: _VerticalDashedLinePainter(),
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 출발지 카드: 터치 시 WebView 열기
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

                    // 이동 소요시간: 점선 바로 오른쪽
                    Row(
                      children: [
                        SizedBox(width: 40),
                        SizedBox(width: 16),
                        Text(
                          _travelDuration ?? '',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // 도착지 카드: 터치 시 WebView 열기
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

/// 출발지/도착지 카드 위젯
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        // 카드 높이를 약 68px로 설정 (vertical:20 + icon 28 + margin)
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

/// 점선을 그리는 CustomPainter
class _VerticalDashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double dx = 0.0; // 이미 Padding으로 40px을 띄워 두었으므로, 0.0에서 중앙 그리기
    double startY = 0;
    final dashHeight = 6.0;
    final dashSpace = 6.0;
    final totalHeight = size.height;

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
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) =>
      false;
}


/// 웹뷰 페이지
/// 웹뷰 페이지 (webview_flutter 4.x 버전용)
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
    // 4.x 기준으로 WebViewController를 생성해 주고, 로드할 URL을 지정해야 합니다.
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
            // WebViewWidget(controller: …) 형태로 화면에 뿌려줍니다.
            WebViewWidget(controller: _controller),
            if (_isLoadingPage)
              Center(child: CupertinoActivityIndicator(radius: 20)),
          ],
        ),
      ),
    );
  }
}
