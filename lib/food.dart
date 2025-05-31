import 'package:flutter/cupertino.dart';

class foodPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('맛집 이미지')),
      child: Center(
        child: Text('맛집 화면입니다'),
      ),
    );
  }
}
