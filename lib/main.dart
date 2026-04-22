import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:async';
import 'dart:convert';

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

  // graphMode: 'press' = 気圧グラフ固定, 'rotate' = 4種ローテーション
  const String barometricGraphMode = 'press'; // 'press' または 'rotate'

  ui_web.platformViewRegistry.registerViewFactory('barometric-view', (
    int viewId,
  ) {
    final el = web.document.createElement('iframe') as web.HTMLIFrameElement;
    el.src = 'barometric.html?graphMode=$barometricGraphMode';
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
        fontFamily: 'Roboto',
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
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // 上部: 時計と天気
                SizedBox(
                  height: constraints.maxHeight * 0.20,
                  child: const Row(
                    children: [
                      Expanded(flex: 4, child: DigitalClock()),
                      VerticalDivider(color: Colors.white24, width: 32),
                      Expanded(flex: 6, child: WeatherPanel()),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 中央: 頭痛予報、カレンダー
                const Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: PanelContainer(
                          title: "頭痛予報（頭痛ナビ）Created by 情報技術部アプリ班",
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
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 下部: お知らせ、時刻表
                SizedBox(
                  height: constraints.maxHeight * 0.28,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: PanelContainer(
                          title: "お知らせ",
                          icon: Icons.campaign,
                          headerColor: Colors.orange[800]!,
                          child: const Information(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        flex: 6,
                        child: PanelContainer(
                          title: "交通機関時刻表",
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: headerColor ?? Colors.blueGrey[800],
            child: Row(
              children: [
                Icon(icon, size: 22, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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
                style: const TextStyle(fontSize: 24, color: Colors.white70),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                      color: Colors.cyanAccent,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    secondStr,
                    style: TextStyle(
                      fontSize: 40,
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
  Timer? _scrollTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchNews().then((_) {
      Future.delayed(const Duration(seconds: 2), () => _startAutoScroll());
    });
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) => fetchNews());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double currentScroll = _scrollController.position.pixels;
        if (maxScroll > 0) {
          if (currentScroll >= maxScroll) {
            _scrollTimer?.cancel();
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                );
                Future.delayed(
                  const Duration(seconds: 3),
                  () => _startAutoScroll(),
                );
              }
            });
          } else {
            _scrollController.jumpTo(currentScroll + 0.6);
          }
        }
      }
    });
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
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController.jumpTo(0);
              _startAutoScroll();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("お知らせ取得エラー: $e");
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
    final double fontSize = newsMessage.length > 200 ? 32 : 44;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Text(
              newsMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                height: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
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
  String errorMsg = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchWeather();
    _timer = Timer.periodic(
      const Duration(hours: 1),
      (timer) => fetchWeather(),
    );
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
            errorMsg = "";
          });
        }
      } else {
        throw Exception("Status code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("天気取得エラー: $e");
      if (mounted) {
        setState(() => errorMsg = "天気予報の取得に失敗しました");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMsg.isNotEmpty && today == null) {
      return Center(
        child: Text(errorMsg, style: const TextStyle(color: Colors.redAccent)),
      );
    }
    if (today == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildWeatherColumn("今日", today!),
        const VerticalDivider(color: Colors.white10, indent: 20, endIndent: 20),
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
            Text(
              label,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            Image.network(
              'https://www.jma.go.jp/bosai/forecast/img/$displayCode.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.wb_cloudy, size: 64),
            ),
            Text(
              data['desc'] ?? "",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['high'] != null && data['high'] != "--")
                  Text(
                    "${data['high']}°",
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (data['low'] != null && data['low'] != "--") ...[
                  const SizedBox(width: 8),
                  Text(
                    "${data['low']}°",
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
    if (["103", "106", "107", "108", "120", "121", "140"].contains(code)) {
      return "102";
    }
    if (["105", "160", "170"].contains(code)) return "104";
    if (code == "111") return "110";
    if (["113", "114", "118", "119", "125", "126", "127", "128"].contains(code)) {
      return "112";
    }
    if (["116", "117", "181"].contains(code)) return "115";
    if (["123", "124", "130", "131"].contains(code)) return "100";
    if (code == "132") return "101";
    if (["209", "231"].contains(code)) return "200";
    if (code == "223") return "201";
    if (["203", "206", "207", "208", "220", "221", "240"].contains(code)) {
      return "202";
    }
    if (["205", "250", "260", "270"].contains(code)) return "204";
    if (code == "211") return "210";
    if (["214", "213", "218", "219", "222", "224", "225", "226"].contains(code)) {
      return "212";
    }
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
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'calendar-view');
  }
}

class HeadacheForecastView extends StatelessWidget {
  const HeadacheForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'barometric-view');
  }
}

class TripleTimetable extends StatelessWidget {
  const TripleTimetable({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: SingleTimetable(
            title: "JR佐土原駅 上り",
            url:
                "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_nobori.csv",
            accentColor: Colors.blueAccent,
          ),
        ),
        Divider(height: 1, color: Colors.white10),
        Expanded(
          child: SingleTimetable(
            title: "JR佐土原駅 下り",
            url:
                "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_kudari.csv",
            accentColor: Colors.redAccent,
          ),
        ),
        Divider(height: 1, color: Colors.white10),
        Expanded(
          child: SingleTimetable(
            title: "バス（佐土原高校前）",
            url:
                "https://sadowara.sakura.ne.jp/sadowara_display_csv/sadowara_bus.csv",
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

  const SingleTimetable({
    super.key,
    required this.title,
    required this.url,
    required this.accentColor,
  });

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
      final response = await http
          .get(Uri.parse(widget.url))
          .timeout(const Duration(seconds: 10));
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final now = DateTime.now();
    final int currentTotalMinutes = now.hour * 60 + now.minute;

    List<List<dynamic>> displayData = _data.skip(1).where((row) {
      if (row.length < 3) return false;
      final String timeStr = row[1].toString().trim();
      final List<String> parts = timeStr.split(':');
      if (parts.length != 2) return false;
      final int rowHour = int.parse(parts[0]);
      final int rowMinute = int.parse(parts[1]);
      return (rowHour * 60 + rowMinute) >= currentTotalMinutes;
    }).toList();

    if (displayData.isEmpty && _data.length > 1) {
      displayData = _data.skip(1).toList();
    }

    final List<List<dynamic>> finalItems = displayData.take(20).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: finalItems.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final List<dynamic> row = finalItems[index];
                return Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          row[1].toString(),
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            height: 1.0,
                          ),
                        ),
                        Text(
                          row[2].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
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
