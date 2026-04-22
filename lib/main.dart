import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:async';
import 'dart:convert';

const String barometricApiKey = "AIzaSyAsueqj-8qHU6nejrrCqC2jY45OJMHy50I";

void main() {
  final String calendarId1 =
      "c_gfriete7qicavqkos59v358q7g%40group.calendar.google.com";
  final String calendarId2 =
      "c_sj0eumk3n4tan8kmgb4qjb0t78%40group.calendar.google.com&ctz=Asia%2FTokyo";
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

  ui_web.platformViewRegistry.registerViewFactory('calendar-view', (
    int viewId,
  ) {
    final el = web.document.createElement('iframe') as web.HTMLIFrameElement;
    el.src = combinedUrl;
    el.style.border = 'none';
    el.width = '100%';
    el.height = '100%';
    return el;
  });

  ui_web.platformViewRegistry.registerViewFactory('barometric-view', (
    int viewId,
  ) {
    final el = web.document.createElement('iframe') as web.HTMLIFrameElement;
    el.src = 'barometric.html?key=$barometricApiKey';
    el.style.border = 'none';
    el.width = '100%';
    el.height = '100%';
    return el;
  });

  runApp(
    MaterialApp(
      title: '佐土原高校 デジタルサイネージ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Noto Sans JP',
      ),
      home: const SchoolBoard(),
    ),
  );
}

class SchoolBoard extends StatelessWidget {
  const SchoolBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 上部: 時計と天気 (18%)
                SizedBox(
                  height: constraints.maxHeight * 0.18,
                  child: const Row(
                    children: [
                      Expanded(flex: 4, child: DigitalClock()),
                      VerticalDivider(color: Colors.white10, width: 40),
                      Expanded(flex: 6, child: WeatherPanel()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 中央: 頭痛予報 (3) vs カレンダー (7) (34%)
                Expanded(
                  flex: 34,
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: PanelContainer(
                          title: "頭痛予報",
                          icon: Icons.speed,
                          child: HeadacheForecastView(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: const PanelContainer(
                          title: "学校行事予定",
                          icon: Icons.calendar_month,
                          child: GoogleCalendarView(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 下部: お知らせ (5) vs 時刻表 (5) (42%)
                Expanded(
                  flex: 42,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: PanelContainer(
                          title: "お知らせ",
                          icon: Icons.campaign,
                          headerColor: Colors.deepOrange[900]!,
                          child: const Information(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        flex: 5,
                        child: PanelContainer(
                          title: "交通機関時刻表・運行情報",
                          icon: Icons.directions_bus,
                          child: TripleTimetable(),
                        ),
                      ),
                    ],
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
    super.key,
    required this.title,
    required this.child,
    required this.icon,
    this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: headerColor ?? Colors.blueGrey[900],
              border: const Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 24, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
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
  const DigitalClock({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final timeStr =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        final secondStr = now.second.toString().padLeft(2, '0');
        final dateStr = "${now.year}年 ${now.month}月 ${now.day}日";
        const weekDays = ["日", "月", "火", "水", "木", "金", "土"];
        final weekDayStr = "（${weekDays[now.weekday % 7]}）";

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dateStr + weekDayStr,
                style: const TextStyle(fontSize: 28, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      color: Colors.cyanAccent,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    secondStr,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent.withValues(alpha: 0.7),
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
  const Information({super.key});

  @override
  InformationState createState() => InformationState();
}

class InformationState extends State<Information> {
  String newsMessage = "お知らせを読み込み中...";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchNews();
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) => fetchNews());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchNews() async {
    const String gasUrl =
        "https://script.google.com/a/macros/g.miyazaki-c.ed.jp/s/AKfycbx73zYIPvjer7PG2vDc3LU46anf52pc0alkJY9p5bhMkK6963LaAO_2FDrV-wOHv-Kg/exec";
    try {
      final response = await http
          .get(Uri.parse(gasUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            newsMessage = data['message'] ?? "お知らせはありません。";
          });
        }
      }
    } catch (e) {
      debugPrint("お知らせ取得エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 収まるようにFittedBoxを使用しつつ、極端に小さくならないようにする
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.9),
                child: Text(
                  newsMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44, // 基本は大きく表示
                    height: 1.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WeatherPanel extends StatefulWidget {
  const WeatherPanel({super.key});

  @override
  WeatherPanelState createState() => WeatherPanelState();
}

class WeatherPanelState extends State<WeatherPanel> {
  Map<String, dynamic>? today;
  Map<String, dynamic>? tomorrow;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchWeather();
    _timer = Timer.periodic(const Duration(hours: 1), (timer) => fetchWeather());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchWeather() async {
    const String gasUrl =
        "https://script.google.com/macros/s/AKfycbySkWR4QxPsT7elLSs4-41tTOc1_VbsUjA1xjPVMpMdzaAWUqUTOMdDA7WuhySqwF74/exec";
    try {
      final response = await http
          .get(Uri.parse(gasUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            today = data['today'];
            tomorrow = data['tomorrow'];
          });
        }
      }
    } catch (e) {
      debugPrint("天気取得エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (today == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildWeatherColumn("今日", today!),
        const VerticalDivider(color: Colors.white10, indent: 15, endIndent: 15),
        _buildWeatherColumn("明日", tomorrow!),
      ],
    );
  }

  Widget _buildWeatherColumn(String label, Map<String, dynamic> data) {
    final String code = data['code'] ?? "100";
    final String displayCode = _convertWeatherCode(code);

    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Image.network(
              'https://www.jma.go.jp/bosai/forecast/img/$displayCode.png',
              width: 90, height: 90,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_cloudy, size: 64),
            ),
            const SizedBox(height: 4),
            Text(data['desc'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['high'] != null && data['high'] != "--")
                  Text("${data['high']}°", style: const TextStyle(fontSize: 28, color: Colors.orangeAccent, fontWeight: FontWeight.w900)),
                if (data['low'] != null && data['low'] != "--") ...[
                  const SizedBox(width: 12),
                  Text("${data['low']}°", style: const TextStyle(fontSize: 28, color: Colors.blueAccent, fontWeight: FontWeight.w900)),
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
  const GoogleCalendarView({super.key});
  @override
  Widget build(BuildContext context) => const HtmlElementView(viewType: 'calendar-view');
}

class HeadacheForecastView extends StatelessWidget {
  const HeadacheForecastView({super.key});
  @override
  Widget build(BuildContext context) => const HtmlElementView(viewType: 'barometric-view');
}

class TripleTimetable extends StatefulWidget {
  const TripleTimetable({super.key});
  @override
  State<TripleTimetable> createState() => _TripleTimetableState();
}

class _TripleTimetableState extends State<TripleTimetable> {
  String delayInfo = "運行情報: 日豊本線 取得中...";
  Color delayColor = Colors.white54;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    fetchDelayInfo();
    _delayTimer = Timer.periodic(const Duration(minutes: 5), (t) => fetchDelayInfo());
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchDelayInfo() async {
    const String statusUrl = "https://www.jrkyushu.co.jp/trains/info/miya.html";
    const String proxyUrl = "https://api.allorigins.win/raw?url=";
    try {
      final response = await http.get(Uri.parse(proxyUrl + statusUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final html = response.body;
        if (html.contains("メンテナンス中")) {
          setState(() {
            delayInfo = "運行情報: JR九州 メンテナンス中";
            delayColor = Colors.orangeAccent;
          });
        } else if (html.contains("平常通り") || html.contains("遅れ等の情報はありません")) {
          setState(() {
            delayInfo = "運行情報: 日豊本線 平常通り";
            delayColor = Colors.greenAccent;
          });
        } else {
          // 詳しい遅延情報がある場合
          setState(() {
            delayInfo = "運行情報: 日豊本線 遅延・運休情報あり (JR九州HPを確認)";
            delayColor = Colors.redAccent;
          });
        }
      }
    } catch (e) {
      debugPrint("遅延情報取得エラー: $e");
      if (mounted) {
        setState(() {
          delayInfo = "運行情報: 日豊本線 取得失敗 (平常通りの見込み)";
          delayColor = Colors.white54;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          decoration: BoxDecoration(
            color: delayColor.withValues(alpha: 0.1),
            border: Border(bottom: BorderSide(color: delayColor.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: delayColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  delayInfo,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: delayColor, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: SingleTimetable(
            title: "JR佐土原駅 上り (延岡方面)",
            url: "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_nobori.csv",
            accentColor: Colors.blueAccent,
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
        const Expanded(
          child: SingleTimetable(
            title: "JR佐土原駅 下り (宮崎方面)",
            url: "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_kudari.csv",
            accentColor: Colors.redAccent,
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
        const Expanded(
          child: SingleTimetable(
            title: "宮崎交通バス (佐土原高校前)",
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
  const SingleTimetable({super.key, required this.title, required this.url, required this.accentColor});
  @override
  SingleTimetableState createState() => SingleTimetableState();
}

class SingleTimetableState extends State<SingleTimetable> {
  List<List<dynamic>> _data = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchCSV();
    _timer = Timer.periodic(const Duration(minutes: 5), (t) => _fetchCSV());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCSV() async {
    try {
      final response = await http.get(Uri.parse(widget.url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final String csvData = utf8.decode(response.bodyBytes);
        if (mounted) {
          setState(() {
            _data = const CsvDecoder().convert(csvData);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("${widget.title} エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

    final now = DateTime.now();
    final int currentTotalMinutes = now.hour * 60 + now.minute;

    List<List<dynamic>> displayData = _data.skip(1).where((row) {
      if (row.length < 3) return false;
      final String timeStr = row[1].toString().trim();
      final List<String> parts = timeStr.split(':');
      if (parts.length != 2) return false;
      return (int.parse(parts[0]) * 60 + int.parse(parts[1])) >= currentTotalMinutes;
    }).toList();

    if (displayData.isEmpty && _data.length > 1) displayData = _data.skip(1).toList();
    final List<List<dynamic>> finalItems = displayData.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: finalItems.map((row) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: widget.accentColor.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(row[1].toString(), style: const TextStyle(color: Colors.orangeAccent, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                            Text(row[2].toString(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
