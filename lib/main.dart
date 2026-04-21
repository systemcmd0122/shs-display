import 'dart:ui_web' as ui_web; // Web用の新しいライブラリ
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Web用（これを動かすにはWebで実行する必要があります）
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:async';
import 'dart:convert';

void main() {

  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: SchoolBoard(),
  ));
}

class SchoolBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // 上半分
          Expanded(
            flex: 3, //少し大きめに確保
            child: Column(
              children: [

                // 左上：天気
                Expanded( flex: 7,child: _buildPanel(child: WeatherPanel())),
                // 右上：時刻表
                Expanded( flex: 3,child: _buildPanel(child: TripleTimetable())),
              ],
            ),
          ),
          // 下半分
          Expanded(
            flex: 4, // 少し小さめに確保
            child: Column(
              children: [
                // 左下：時刻表
                Expanded( flex: 7,child: _buildPanel(child: GoogleCalendarView())),
                // 右下：現在時刻
                Expanded( flex: 3,child: _buildPanel(child: DigitalClock())),
              ],
            ),
          ),
          Expanded(
            flex: 3, // 少し小さめに確保
            child: Row(
              children: [
                // 右下：現在時刻
                Expanded(child: _buildPanel(child: Information())),
              ],
            ),
          ),
        ],
      ),

    );
  }

  // パネルの枠組みを作る共通関数
  Widget _buildPanel({String? title, Widget? child}) {
    return Container(
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: child ?? Center(
        child: Text(title ?? "", style: TextStyle(color: Colors.white, fontSize: 24)),
      ),
    );
  }
}

// 右下：現在時刻を表示する時計ウィジェット
class DigitalClock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
        final dateStr = "${now.year}年${now.month}月${now.day}日";

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(timeStr, style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontFamily: 'monospace')),
            Text(dateStr, style: TextStyle(fontSize: 30, color: Colors.white70)),
          ],
        );
      },
    );
  }
}

class Information extends StatefulWidget {
  @override
  _InformationState createState() => _InformationState();
}

class _InformationState extends State<Information> {
  String newsMessage = "お知らせを読み込み中...";

  @override
  void initState() {
    super.initState();
    fetchNews();
    // 5分ごとにお知らせを更新するタイマー
    Timer.periodic(Duration(minutes: 5), (timer) => fetchNews());
  }

  Future<void> fetchNews() async {
    const String gasUrl = "https://script.google.com/a/macros/g.miyazaki-c.ed.jp/s/AKfycbx73zYIPvjer7PG2vDc3LU46anf52pc0alkJY9p5bhMkK6963LaAO_2FDrV-wOHv-Kg/exec";
    try {
      final response = await http.get(Uri.parse(gasUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          newsMessage = data['message'];
        });
      }
    } catch (e) {
      print("お知らせ取得エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width*3/10;
    // 横幅に合わせてフォントサイズを計算（例：横幅の 5%）
    double FontSize = screenWidth * 0.05;
    return Row(
      children: [
        // スプレッドシートからのお知らせ
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellowAccent.withOpacity(0.2), // お知らせっぽく少し赤系に
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.yellowAccent.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text("お知らせ", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold,fontSize: FontSize)),
                  ],
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Text(
                    newsMessage,
                    style: TextStyle(color: Colors.white, fontSize: FontSize),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



class WeatherPanel extends StatefulWidget {
  @override
  _WeatherPanelState createState() => _WeatherPanelState();
}

class _WeatherPanelState extends State<WeatherPanel> {
  String temp = "--";
  String humidity = "--";
  String desc = "待機中";
  String iconUrl = "";
  String errorMsg = "";

  String todayCode = "100";
  String tomorrowCode = "100";


  @override
  void initState() {
    super.initState();
    fetchWeather();
  }
  String tomorrowDesc = "取得中";
  String tomorrowHigh = "--";
  String tomorrowLow = "--";
  Future<void> fetchWeather() async {
    // あなたのGASのURLに書き換えてください
    const String gasUrl = "https://script.google.com/macros/s/AKfycbySkWR4QxPsT7elLSs4-41tTOc1_VbsUjA1xjPVMpMdzaAWUqUTOMdDA7WuhySqwF74/exec";
    try {
      final response = await http.get(Uri.parse(gasUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          // 今日のデータ
          desc = data['today']['desc'];
          todayCode = data['today']['code'];
          temp = data['today']['high']; // 今日の最高気温

          // 明日のデータ
          tomorrowDesc = data['tomorrow']['desc'];
          tomorrowCode = data['tomorrow']['code'];
          tomorrowHigh = data['tomorrow']['high'];
          tomorrowLow = data['tomorrow']['low'];
          errorMsg = "";
        });
      }
    } catch (e) {
      setState(() => errorMsg = "予報取得エラー");
    }
  }


  Widget build(BuildContext context) {
    if (errorMsg.isNotEmpty) return Center(child: Text(errorMsg, style: TextStyle(color: Colors.red)));
    // 画面の横幅を取得
    double screenWidth = MediaQuery.of(context).size.width*3/10;

    // 横幅に合わせてフォントサイズを計算（例：横幅の 5%）
    double titleFontSize = screenWidth * 0.05;
    double tempFontSize = screenWidth * 0.07;  // 気温は大きく
    double descFontSize = screenWidth * 0.04;
    double decWidth = screenWidth * 0.5;

    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("宮崎市の天気予報", style: TextStyle(color: Colors.cyanAccent, fontSize: titleFontSize, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),

          // --- 今日の予報セクション ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text("今日", style: TextStyle(color: Colors.white70, fontSize: descFontSize)),
                  _getWeatherIcon(todayCode), // アイコン
                  SizedBox(width: decWidth, child: Text(desc, style: TextStyle(color: Colors.white, fontSize: descFontSize), textAlign: TextAlign.center, maxLines: 5)),
                ],
              ),
              Column(
                children: [
                  Text("最高気温", style: TextStyle(color: Colors.white70, fontSize: descFontSize)),
                  Text("$temp℃", style: TextStyle(color: Colors.orangeAccent, fontSize: tempFontSize, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Divider(color: Colors.white24, thickness: 1),
          ),

          // --- 明日の予報セクション ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text("明日", style: TextStyle(color: Colors.white70, fontSize: descFontSize)),
                  _getWeatherIcon(tomorrowCode), // 明日のアイコン（変数名は適宜合わせてください）
                  SizedBox(width: decWidth, child: Text(tomorrowDesc, style: TextStyle(color: Colors.white, fontSize: descFontSize), textAlign: TextAlign.center, maxLines: 5)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("最高 ", style: TextStyle(color: Colors.white70, fontSize: descFontSize)),
                      Text("$tomorrowHigh℃", style: TextStyle(color: Colors.orangeAccent, fontSize: descFontSize, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text("最低 ", style: TextStyle(color: Colors.white70, fontSize: descFontSize)),
                      Text("$tomorrowLow℃", style: TextStyle(color: Colors.blueAccent, fontSize: descFontSize, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }



// 3. アイコン表示関数を書き換え
  Widget _getWeatherIcon(String code) {
    print("code:$code");
    print("desc:$desc");
    String displayCode = code;
    if (code.length == 3) {
      // 例: 211 -> 200番台なので「くもり」の基本画像を表示させる
      // もしくは気象庁のルールに基づき特定のコードへ変換


      if ( code == "103" || code == "106"|| code == "107"|| code == "108"|| code == "120"|| code == "121" || code == "140") displayCode = "102";
      if ( code == "105"|| code == "160"|| code == "170" ) displayCode = "104";
      if ( code == "111" ) displayCode = "110";
      if ( code == "113" || code == "114" || code == "118"|| code == "119"|| code == "125" || code == "126"|| code == "127"|| code == "128") displayCode = "112";
      if ( code == "116" || code == "117" || code == "181" ) displayCode = "115";
      if ( code == "123" || code == "124"|| code == "130"|| code == "131") displayCode = "100";
      if ( code == "132" ) displayCode = "101";
      if ( code == "209" || code == "231" ) displayCode = "200";
      if ( code == "223" ) displayCode = "201";
      if ( code == "203" || code == "206" || code == "207"|| code == "208" || code == "220"|| code == "221"|| code == "240") displayCode = "202";
      if ( code == "205" || code == "250"|| code == "260"|| code == "270") displayCode = "204";
      if (code == "211")displayCode = "210";
      if ( code == "214" || code == "213" || code == "218"|| code == "219"|| code == "222"|| code == "224"|| code == "225"|| code == "226") displayCode = "212";
      if (code == "216"|| code == "217"|| code == "228"|| code == "229"|| code == "230"|| code == "281")displayCode = "215";
      if (code == "304"|| code == "306"|| code == "328"|| code == "329"|| code == "350")displayCode = "300";
      if (code == "309"|| code == "322" ) displayCode = "303";
      if ( code == "316" || code == "320" || code == "323"|| code == "324"|| code == "325") displayCode = "311";
      if ( code == "317" || code == "321" ) displayCode = "313";
      if ( code == "315"  || code == "326" || code == "327") displayCode = "314";
    }

    double screenWidth = MediaQuery.of(context).size.width*3/10;
    // 横幅に合わせてフォントサイズを計算（例：横幅の 5%）
    double IconSize = screenWidth * 0.20;

  return Image.network(
  'https://www.jma.go.jp/bosai/forecast/img/$displayCode.png',
  width: IconSize,
  height: IconSize,
    errorBuilder: (context, error, stackTrace) {
      // それでもエラーなら、もっとも近い基本コードを試す
      return Image.network(
        'https://www.jma.go.jp/bosai/forecast/img/${code[0]}00.png',
        width: 64,
        height: 64,
        errorBuilder: (c, e, s) => Icon(Icons.wb_cloudy, color: Colors.white, size: 64),
      );
    },
  );
  }
}

class GoogleCalendarView extends StatelessWidget {
  // 2つのカレンダーIDを &src= でつなげる
  final String calendarId1 = "c_gfriete7qicavqkos59v358q7g%40group.calendar.google.com";
  final String calendarId2 = "c_sj0eumk3n4tan8kmgb4qjb0t78%40group.calendar.google.com&ctz=Asia%2FTokyo";

  @override
  Widget build(BuildContext context) {
    // 統合したURLを作成
    final String combinedUrl =
        "https://calendar.google.com/calendar/embed"
        "?src=$calendarId1"
        "&src=$calendarId2"
        "&ctz=Asia%2FTokyo"
        "&showTitle=0"       // タイトル非表示
        "&showNav=1"         // ★ あえてナビ（前後ボタン）を出すと操作も可能
        "&showDate=1"        // 日付を表示
        "&showPrint=0"
        "&showTabs=0"
        "&mode=AGENDA" // リスト形式（おすすめ）
        "&bgcolor=%23ffffff"; // 背景を白に（黒背景なら %23000000）
    /*
        "https://calendar.google.com/calendar/embed"
        "?src=$calendarId1"
        "&src=$calendarId2"
        "&ctz=Asia%2FTokyo"
        "&mode=AGENDA" // リスト形式（おすすめ）
        "&showTitle=0&showNav=0&showPrint=0&showTabs=0&showCalendars=0";

     */
    ui_web.platformViewRegistry.registerViewFactory(
      'calendar-view',
          (int viewId) {
        return html.IFrameElement()
          ..src = combinedUrl
          ..style.border = 'none'
          ..width = '100%'
          ..height = '100%';
      },
    );

    return HtmlElementView(viewType: 'calendar-view');
  }
}

//時刻表
class TripleTimetable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row( // 縦(Column)から横(Row)に変更
      children: [
        // 左：JR上り
        Expanded(
          child: SingleTimetable(
            title: "JR上り",
            url: "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_nobori.csv",
            headerColor: Colors.blue[900]!,
          ),
        ),
        VerticalDivider(width: 1, color: Colors.white24), // 縦の区切り線

        // 中：JR下り
        Expanded(
          child: SingleTimetable(
            title: "JR下り",
            url: "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_kudari.csv",
            headerColor: Colors.red[900]!,
          ),
        ),
        VerticalDivider(width: 1, color: Colors.white24), // 縦の区切り線

        // 右：バス
        Expanded(
          child: SingleTimetable(
            title: "バス（佐高前）",
            url: "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_bus.csv",
            headerColor: Colors.green[900]!,
          ),
        ),
      ],
    );
  }
}

class SingleTimetable extends StatefulWidget {
  final String title;
  final String url;
  final Color headerColor;

  SingleTimetable({required this.title, required this.url, required this.headerColor});

  @override
  _SingleTimetableState createState() => _SingleTimetableState();
}

class _SingleTimetableState extends State<SingleTimetable> {
  List<List<dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCSV();
    // 5分ごとに自動更新
    Timer.periodic(Duration(minutes: 5), (t) => _fetchCSV());
  }

  Future<void> _fetchCSV() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        String csvData = utf8.decode(response.bodyBytes);
        setState(() {
          _data = const CsvDecoder().convert(csvData);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("${widget.title} エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator(strokeWidth: 2));

    final now = DateTime.now();
    // 今日の「0時0分」からの経過分を計算 (例: 22:37 -> 1357分)
    final currentTotalMinutes = now.hour * 60 + now.minute;

    // 1. CSVデータを数値で比較してフィルタリング
    List<List<dynamic>> displayData = _data.skip(1).where((row) {
      if (row.length < 3) return false;

      // CSVの時刻 (例: "22:57") を分に変換
      final String timeStr = row[1].toString().trim();
      final parts = timeStr.split(':');
      if (parts.length != 2) return false;

      final int rowHour = int.parse(parts[0]);
      final int rowMinute = int.parse(parts[1]);
      final int rowTotalMinutes = rowHour * 60 + rowMinute;

      // 現在時刻と同じ、または後のものだけ残す
      return rowTotalMinutes >= currentTotalMinutes;
    }).toList();

    // 2. もし今以降の電車がなければ、明日の始発（リストの最初）を表示
    if (displayData.isEmpty && _data.length > 1) {
      displayData = _data.skip(1).toList();
    }

    double screenWidth = MediaQuery.of(context).size.width*3/10;

    // 横幅に合わせてフォントサイズを計算（例：横幅の 5%）
    double timeFontSize = screenWidth * 0.04;
    double sakiFontSize = screenWidth * 0.03;  // 気温は大きく

    // 3. 上から10つ取り出す
    final finalItems = displayData.take(10).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: widget.headerColor,
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(widget.title, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: ListView.builder(
              padding: EdgeInsets.all(4),
              itemCount: finalItems.length,
              itemBuilder: (context, index) {
                final row = finalItems[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(row[1].toString(), style: TextStyle(color: Colors.orangeAccent, fontSize: timeFontSize, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        // 右側：特急なら赤、それ以外は白っぽい色の小さな文字
                        if (row[0].toString() == "特急")
                          Text(row[0].toString(), style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))
                        else
                          Text(row[0].toString(), style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                    Text(" ➔ ${row[2].toString()}",
                        style: TextStyle(color: Colors.white, fontSize: sakiFontSize, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                    Divider(color: Colors.white10, height: 8),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}