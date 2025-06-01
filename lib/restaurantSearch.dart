import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const KAKAO_API_KEY = '61b38d6ed4f530323a885956d6715767';
const NAVER_CLIENT_ID = 'pmT2ZpND_xq3RKu5mJsl';
const NAVER_CLIENT_SECRET = 'EAN7GXvag4';

class RestaurantSearchPage extends StatefulWidget {
  @override
  State<RestaurantSearchPage> createState() => _RestaurantSearchPageState();
}

class _RestaurantSearchPageState extends State<RestaurantSearchPage> {
  List<Map<String, dynamic>> _restaurants = [];

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      // 1. 위치 권한 요청
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      // 2. 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 3. 좌표 → 주소 변환
      final placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      final placemark = placemarks.first;
      final dong = placemark.locality ?? placemark.subLocality ?? '맛집';

      // 4. 검색 키워드 생성
      final keyword = '$dong 맛집';

      print('🔍 현재 위치 검색 키워드: $keyword');

      // 5. Kakao API 호출
      final url =
          'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeComponent(keyword)}';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'KakaoAK $KAKAO_API_KEY'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List docs = data['documents'];
        List<Map<String, dynamic>> withImages = [];

        for (var doc in docs) {
          final name = doc['place_name'];
          final image = await _fetchNaverThumbnail(name);
          withImages.add({
            'name': name,
            'category': doc['category_name'],
            'thumbnail': image,
          });
        }

        setState(() => _restaurants = withImages);
      } else {
        print('Kakao API 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('위치 기반 맛집 검색 실패: $e');
    }
  }

  Future<String?> _fetchNaverThumbnail(String query) async {
    final url =
        'https://openapi.naver.com/v1/search/image.json?query=${Uri.encodeComponent(query)}&display=1';
    final res = await http.get(Uri.parse(url), headers: {
      'X-Naver-Client-Id': NAVER_CLIENT_ID,
      'X-Naver-Client-Secret': NAVER_CLIENT_SECRET,
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['items'].isNotEmpty) {
        return data['items'][0]['thumbnail'];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text('주위 맛집 찾기'),
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.activeBlue,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: _restaurants.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(10),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3 / 4,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: _restaurants.take(4).map((place) {
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 3,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.network(
                      place['thumbnail'] ??
                          'https://picsum.photos/seed/restaurant/300/200',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: Icon(Icons.image_not_supported, size: 50),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          place['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          place['category']
                              .toString()
                              .split('>')
                              .last
                              .trim() ??
                              '',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
