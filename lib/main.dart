import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  // カレンダーのビューを一度だけ登録
  final String calendarId1 = "c_gfriete7qicavqkos59v358q7g%40group.calendar.google.com";
  final String calendarId2 = "c_sj0eumk3n4tan8kmgb4qjb0t78%40group.calendar.google.com&ctz=Asia%2FTokyo";
  final String combinedUrl =
      "https://calendar.google.com/calendar/embed"
      "?src=$calendarId1"
      "&src=$calendarId2"
      "&ctz=Asia%2FTokyo"
      "&showTitle=0"
      "&showNav=1"
      "&showDate=1"
      "&showPrint=0"
      "&showTabs=0"
      "&mode=AGENDA"
      "&bgcolor=%23ffffff";

  ui_web.platformViewRegistry.registerViewFactory(
    'calendar-view',
    (int viewId) => html.IFrameElement()
      ..src = combinedUrl
      ..style.border = 'none'
      ..width = '100%'
      ..height = '100%',
  );

  ui_web.platformViewRegistry.registerViewFactory(
    'barometric-view',
    (int viewId) => html.IFrameElement()
      ..src = 'barometric.html?hideHeader=true'
      ..style.border = 'none'
      ..width = '100%'
      ..height = '100%',
  );

  runApp(MaterialApp(
    title: '佐土原高校 デジタルサイネージ',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.blueGrey[900],
      scaffoldBackgroundColor: Colors.black,
      fontFamily: 'Roboto',
    ),
    home: SchoolBoard(),
  ));
}

class SchoolBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // 上部: 時計と天気
                Container(
                  height: constraints.maxHeight * 0.25,
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: DigitalClock()),
                      VerticalDivider(color: Colors.white24, width: 32),
                      Expanded(flex: 6, child: WeatherPanel()),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // 中央: 頭痛予報、カレンダー、時刻表
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PanelContainer(
                          title: "頭痛予報",
                          icon: Icons.speed,
                          child: HeadacheForecastView(),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: PanelContainer(
                          title: "学校行事予定",
                          icon: Icons.calendar_month,
                          child: GoogleCalendarView(),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: PanelContainer(
                          title: "交通機関時刻表",
                          icon: Icons.directions_bus,
                          child: TripleTimetable(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // 下部: お知らせ
                Container(
                  height: constraints.maxHeight * 0.15,
                  child: PanelContainer(
                    title: "お知らせ",
                    icon: Icons.campaign,
                    headerColor: Colors.orange[800]!,
                    child: Information(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PanelContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData icon;
  final Color? headerColor;

  const PanelContainer({
    required this.title,
    required this.child,
    required this.icon,
    this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: headerColor ?? Colors.blueGrey[800],
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class DigitalClock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        final secondStr = now.second.toString().padLeft(2, '0');
        final dateStr = "${now.year}年 ${now.month}月 ${now.day}日";
        final weekDays = ["日", "月", "火", "水", "木", "金", "土"];
        final weekDayStr = "（${weekDays[now.weekday % 7]}）";

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dateStr + weekDayStr,
                style: TextStyle(fontSize: 24, color: Colors.white70),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                      color: Colors.cyanAccent,
                      fontFamily: 'monospace',
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    secondStr,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent.withOpacity(0.7),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
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
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    fetchNews();
    _timer = Timer.periodic(Duration(minutes: 5), (timer) => fetchNews());
    _startScrolling();
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;
        if (maxScroll > 0) {
          if (currentScroll >= maxScroll) {
            _scrollController.jumpTo(0);
          } else {
            _scrollController.animateTo(
              currentScroll + 1,
              duration: Duration(milliseconds: 50),
              curve: Curves.linear,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchNews() async {
    const String gasUrl = "https://script.google.com/a/macros/g.miyazaki-c.ed.jp/s/AKfycbx73zYIPvjer7PG2vDc3LU46anf52pc0alkJY9p5bhMkK6963LaAO_2FDrV-wOHv-Kg/exec";
    try {
      final response = await http.get(Uri.parse(gasUrl)).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            newsMessage = data['message'] ?? "お知らせはありません。";
          });
        }
      }
    } catch (e) {
      print("お知らせ取得エラー: $e");
      if (mounted) {
        setState(() {
          if (newsMessage == "お知らせを読み込み中...") {
            newsMessage = "お知らせを取得できませんでした。";
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = 32;
    if (newsMessage.length > 300) {
      fontSize = 20;
    } else if (newsMessage.length > 150) {
      fontSize = 24;
    } else if (newsMessage.length > 50) {
      fontSize = 28;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Text(
          newsMessage,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class WeatherPanel extends StatefulWidget {
  @override
  _WeatherPanelState createState() => _WeatherPanelState();
}

class _WeatherPanelState extends State<WeatherPanel> {
  Map<String, dynamic>? today;
  Map<String, dynamic>? tomorrow;
  String errorMsg = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchWeather();
    _timer = Timer.periodic(Duration(hours: 1), (timer) => fetchWeather());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchWeather() async {
    const String gasUrl = "https://script.google.com/macros/s/AKfycbySkWR4QxPsT7elLSs4-41tTOc1_VbsUjA1xjPVMpMdzaAWUqUTOMdDA7WuhySqwF74/exec";
    try {
      final response = await http.get(Uri.parse(gasUrl)).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            today = data['today'];
            tomorrow = data['tomorrow'];
            errorMsg = "";
          });
        }
      } else {
        throw Exception("Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("天気取得エラー: $e");
      if (mounted) {
        setState(() => errorMsg = "天気予報の取得に失敗しました");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMsg.isNotEmpty && today == null) {
      return Center(child: Text(errorMsg, style: TextStyle(color: Colors.redAccent)));
    }
    if (today == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildWeatherColumn("今日", today!),
        VerticalDivider(color: Colors.white10, indent: 20, endIndent: 20),
        _buildWeatherColumn("明日", tomorrow!),
      ],
    );
  }

  Widget _buildWeatherColumn(String label, Map<String, dynamic> data) {
    String code = data['code'] ?? "100";
    String displayCode = _convertWeatherCode(code);

    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 18, color: Colors.white70)),
            Image.network(
              'https://www.jma.go.jp/bosai/forecast/img/$displayCode.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.wb_cloudy, size: 64),
            ),
            Text(
              data['desc'] ?? "",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['high'] != null && data['high'] != "--")
                  Text("${data['high']}°", style: TextStyle(fontSize: 24, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                if (data['low'] != null && data['low'] != "--") ...[
                  SizedBox(width: 8),
                  Text("${data['low']}°", style: TextStyle(fontSize: 24, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _convertWeatherCode(String code) {
    if (code.length != 3) return code;
    // 既存のロジックを流用（簡略化も可能だが互換性を重視）
    if (["103", "106", "107", "108", "120", "121", "140"].contains(code)) return "102";
    if (["105", "160", "170"].contains(code)) return "104";
    if (code == "111") return "110";
    if (["113", "114", "118", "119", "125", "126", "127", "128"].contains(code)) return "112";
    if (["116", "117", "181"].contains(code)) return "115";
    if (["123", "124", "130", "131"].contains(code)) return "100";
    if (code == "132") return "101";
    if (["209", "231"].contains(code)) return "200";
    if (code == "223") return "201";
    if (["203", "206", "207", "208", "220", "221", "240"].contains(code)) return "202";
    if (["205", "250", "260", "270"].contains(code)) return "204";
    if (code == "211") return "210";
    if (["214", "213", "218", "219", "222", "224", "225", "226"].contains(code)) return "212";
    if (["216", "217", "228", "229", "230", "281"].contains(code)) return "215";
    if (["304", "306", "328", "329", "350"].contains(code)) return "300";
    if (["309", "322"].contains(code)) return "303";
    if (["316", "320", "323", "324", "325"].contains(code)) return "311";
    if (["317", "321"].contains(code)) return "313";
    if (["315", "326", "327"].contains(code)) return "314";
    return code;
  }
}

class GoogleCalendarView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: 'calendar-view');
  }
}

class HeadacheForecastView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: 'barometric-view');
  }
}

class TripleTimetable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleTimetable(
            title: "JR佐土原駅 上り",
            url: "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_nobori.csv",
            accentColor: Colors.blueAccent,
          ),
        ),
        Divider(height: 1, color: Colors.white10),
        Expanded(
          child: SingleTimetable(
            title: "JR佐土原駅 下り",
            url: "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_kudari.csv",
            accentColor: Colors.redAccent,
          ),
        ),
        Divider(height: 1, color: Colors.white10),
        Expanded(
          child: SingleTimetable(
            title: "バス（佐土原高校前）",
            url: "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_bus.csv",
            accentColor: Colors.greenAccent,
          ),
        ),
      ],
    );
  }
}

class SingleTimetable extends StatefulWidget {
  final String title;
  final String url;
  final Color accentColor;

  SingleTimetable({required this.title, required this.url, required this.accentColor});

  @override
  _SingleTimetableState createState() => _SingleTimetableState();
}

class _SingleTimetableState extends State<SingleTimetable> {
  List<List<dynamic>> _data = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchCSV();
    _timer = Timer.periodic(Duration(minutes: 5), (t) => _fetchCSV());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCSV() async {
    try {
      final response = await http.get(Uri.parse(widget.url)).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        String csvData = utf8.decode(response.bodyBytes);
        if (mounted) {
          setState(() {
            _data = const CsvDecoder().convert(csvData);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("${widget.title} エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator(strokeWidth: 2));

    final now = DateTime.now();
    final currentTotalMinutes = now.hour * 60 + now.minute;

    List<List<dynamic>> displayData = _data.skip(1).where((row) {
      if (row.length < 3) return false;
      final String timeStr = row[1].toString().trim();
      final parts = timeStr.split(':');
      if (parts.length != 2) return false;
      final int rowHour = int.parse(parts[0]);
      final int rowMinute = int.parse(parts[1]);
      return (rowHour * 60 + rowMinute) >= currentTotalMinutes;
    }).toList();

    if (displayData.isEmpty && _data.length > 1) {
      displayData = _data.skip(1).toList();
    }

    final finalItems = displayData.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: TextStyle(fontSize: 12, color: widget.accentColor, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: finalItems.length,
              itemBuilder: (context, index) {
                final row = finalItems[index];
                return Container(
                  width: 100,
                  margin: EdgeInsets.only(right: 8, top: 4, bottom: 4),
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(row[1].toString(), style: TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      Text(row[2].toString(), style: TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
