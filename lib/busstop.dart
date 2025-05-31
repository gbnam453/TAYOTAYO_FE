import 'package:flutter/cupertino.dart';
import 'result.dart';

class BusStopPage extends StatefulWidget {
  @override
  _BusStopPageState createState() => _BusStopPageState();
}

class _BusStopPageState extends State<BusStopPage> {
  final List<String> locationsKr = [
    '아산캠퍼스',
    '천안아산역',
    '쌍용2동',
    '충무병원',
    '천안역',
    '천안터미널',
    '천안캠퍼스',
  ];

  final List<String> locationsEn = [
    'Asan Campus',
    'Cheonan-Asan Station',
    'Ssangyong 2-dong',
    'Chungmu Hospital',
    'Cheonan Station',
    'Cheonan Terminal',
    'Cheonan Campus',
  ];

  int departureIndex = 0;
  int arrivalIndex = 1;

  void _showPicker({
    required int initialIndex,
    required Function(int) onSelected,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 40,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 16),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text('완료', style: TextStyle(color: CupertinoColors.black)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController:
                FixedExtentScrollController(initialItem: initialIndex),
                itemExtent: 40.0,
                onSelectedItemChanged: onSelected,
                children: locationsKr
                    .map((loc) => Text(
                  loc,
                  style: TextStyle(fontSize: 22),
                ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text('출발지 / 도착지 선택'),
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.activeBlue,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 120, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('출발지', style: TextStyle(fontSize: 25)),
                    SizedBox(width: 60),
                    Icon(CupertinoIcons.right_chevron, size: 30),
                    SizedBox(width: 60),
                    Text('도착지', style: TextStyle(fontSize: 25)),
                  ],
                ),
                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLocationButton(
                      title: locationsKr[departureIndex],
                      onPressed: () {
                        _showPicker(
                          initialIndex: departureIndex,
                          onSelected: (index) {
                            setState(() {
                              departureIndex = index;
                            });
                          },
                        );
                      },
                    ),
                    SizedBox(width: 40),
                    _buildLocationButton(
                      title: locationsKr[arrivalIndex],
                      onPressed: () {
                        _showPicker(
                          initialIndex: arrivalIndex,
                          onSelected: (index) {
                            setState(() {
                              arrivalIndex = index;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 40),

                SizedBox(
                  width: 200,
                  child: CupertinoButton(
                    color: CupertinoColors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('검색',
                        style: TextStyle(
                            color: CupertinoColors.black, fontSize: 20)),
                    onPressed: () {
                      if (departureIndex == arrivalIndex) {
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: Text('알림'),
                            content: Text('출발지와 도착지는 달라야 합니다.'),
                            actions: [
                              CupertinoDialogAction(
                                child: Text('확인'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => ResultPage(
                              departureIndex: departureIndex,
                              departureName: locationsEn[departureIndex],
                              arrivalIndex: arrivalIndex,
                              arrivalName: locationsEn[arrivalIndex],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.symmetric(vertical: 18),
          color: CupertinoColors.white,
          child: Text(
            title,
            style: TextStyle(color: CupertinoColors.black, fontSize: 20),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
