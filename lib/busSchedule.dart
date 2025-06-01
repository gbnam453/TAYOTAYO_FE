//정류장 주소 Map
final Map<String, String> addressAtoC = {
  "Asan Campus": "충청남도 아산시 배방읍 호서로79번길 20 호서대학교",
  "Cheonan-Asan Station": "충청남도 아산시 배방읍 장재리 316-7",
  "Ssangyong 2-dong": "충청남도 천안시 서북구 쌍용13길 15",
  "Chungmu Hospital": "충청남도 천안시 서북구 쌍용동 540-1",
  "Cheonan Station": "충남 천안시 동남구 문화1길 5-1",
  "Cheonan Terminal": "충청남도 천안시 동남구 만남로 40 1층 서해약국",
  "Cheonan Campus": "충남 천안시 동남구 호서대길 12 호서대학교천안캠퍼스",
};

final Map<String, String> addressCtoA = {
  "Asan Campus": "충청남도 아산시 배방읍 호서로79번길 20 호서대학교",
  "Cheonan-Asan Station": "충청남도 아산시 배방읍 장재리 316-7",
  "Ssangyong 3-dong": "충청남도 천안시 서북구 쌍용동 2031",
  "Chungmu Hospital": "충청남도 천안시 서북구 쌍용동 538-16",
  "Cheonan Station": "충남 천안시 동남구 버들로 16",
  "Cheonan Terminal": "충청남도 천안시 동남구 신부동 811",
  "Cheonan Campus": "충남 천안시 동남구 호서대길 12 호서대학교천안캠퍼스"
};

// 방향에 따른 정류장 주소 Map 정하기
String? getAddress(String str, int dir) {
  if(dir == 0){
    return addressAtoC[str];
  }
  else{
    return addressCtoA[str];
  }
}

// 버스 스케줄 클래스
class busSchedule {
  final Map<String, String> stops;

  busSchedule(this.stops);

// JSON 데이터를 Map 형태로 변환하여 스케쥴 객체 생성
  factory busSchedule.fromJson(Map<String, dynamic> json) {
    return busSchedule(Map<String, String>.from(json));
  }

  Map<String, dynamic> toJson() {
    return stops;
  }

}

// 노선별 버스 스케쥴 디비
class busScheduleDB {
  final List<busSchedule> cheonanToAsan;
  final List<busSchedule> asanToCheonan;

  busScheduleDB({required this.cheonanToAsan, required this.asanToCheonan});

  // 받아온 시간표를 기반으로 JSON 데이터를 Map 형태로 변환하여 스케쥴 객체 생성
  factory busScheduleDB.fromJson(Map<String, dynamic> json) {
    return busScheduleDB(
      cheonanToAsan: List<Map<String, dynamic>>.from(json['cheonan_to_asan'])
          .map((e) => busSchedule.fromJson(e))
          .toList(),
      asanToCheonan: List<Map<String, dynamic>>.from(json['asan_to_cheonan'])
          .map((e) => busSchedule.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cheonan_to_asan': cheonanToAsan.map((e) => e.toJson()).toList(),
      'asan_to_cheonan': asanToCheonan.map((e) => e.toJson()).toList(),
    };
  }
}

List<busSchedule> getSchedules ({
  required busScheduleDB busSche,
  required int dir
}) {
  if (dir == 0){
    return busSche.asanToCheonan;
  }
  else {
    return busSche.cheonanToAsan;
  }
}
