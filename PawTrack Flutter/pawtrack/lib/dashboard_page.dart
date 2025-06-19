// Your imports
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool petDetected = false;
  int waterLevel = 0;
  bool isSendingCommand = false;
  bool isLoading = true;
  String? commandStatus;
  List<FlSpot> waterLevelSpots = [];
  Map<DateTime, List<String>> refillEvents = {};
  Map<String, int> refillCounts = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    await Future.wait([fetchGraphData(), fetchRefillHistory()]);
    setState(() => isLoading = false);
  }

  Future<void> fetchGraphData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '1';

    try {
      final response = await http.get(Uri.parse(
          'https://humancc.site/shifaqmawaddah/pawtrack/get_history.php?user_id=$userId&device_id=1'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isEmpty) return;

        // Use the first item directly — assuming API returns newest to oldest
        final latest = data.first;
        final pirValue = latest['pir'];
        final waterValue = latest['water_level'];

        setState(() {
          petDetected = pirValue == 1 || pirValue == '1';
          waterLevel = int.tryParse(waterValue.toString()) ?? 0;
        });

        if (waterLevel == 0 && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("⚠️ Water level is very low! Please refill."),
              backgroundColor: Colors.red.shade400,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // For chart, reverse to show from oldest to newest
        final reversed = data.reversed.toList();

        List<FlSpot> spots = [];
        for (int i = 0; i < reversed.length; i++) {
          final level = int.tryParse(reversed[i]['water_level'].toString()) ?? 0;
          spots.add(FlSpot(i.toDouble(), level.toDouble()));
        }

        setState(() {
          waterLevelSpots = spots;
        });
      }
    } catch (e) {
      debugPrint('Error fetching graph data: $e');
    }
  }

  Future<void> fetchRefillHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '1';

    try {
      final response = await http.get(Uri.parse(
          'https://humancc.site/shifaqmawaddah/pawtrack/get_refill_history.php?user_id=$userId&device_id=1'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List eventsData = data['refill_events'];
        final Map<String, dynamic> countsData = data['refill_counts'];

        Map<DateTime, List<String>> events = {};

        for (var item in eventsData) {
          DateTime date = DateTime.parse(item['timestamp']).toLocal();
          DateTime day = DateTime(date.year, date.month, date.day);
          events.putIfAbsent(day, () => []);
          events[day]!.add(item['command']);
        }

        setState(() {
          refillEvents = events;
          refillCounts = countsData.map((k, v) => MapEntry(k, v as int));
        });
      }
    } catch (e) {
      debugPrint('Error fetching refill history: $e');
    }
  }

  Future<void> sendCommand(String command) async {
    setState(() {
      isSendingCommand = true;
      commandStatus = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '1';

    final response = await http.post(
      Uri.parse('https://humancc.site/shifaqmawaddah/pawtrack/insert_command.php'),
      body: {
        'user_id': userId,
        'device_id': '1',
        'command': command,
        'relay': '1',
      },
    );

    setState(() {
      isSendingCommand = false;
      commandStatus = response.statusCode == 200
          ? (command == "REFILL_WATER" ? "✅ Water Refilled" : "✅ Food Refilled")
          : "❌ Command Failed";
    });

    fetchData();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  Widget buildChart(double width) {
    if (isLoading) return const Text('Loading water level graph...');
    if (waterLevelSpots.isEmpty) return const Text('No water level data available');

    double maxY = waterLevelSpots.map((e) => e.y).fold<double>(0, (a, b) => a > b ? a : b);
    maxY = (maxY / 20).ceil() * 20;

    return SizedBox(
      height: 240,
      width: width,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: waterLevelSpots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              belowBarData: BarAreaData(show: false),
            )
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: const Text('Water Level'),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) =>
                    Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text('Time'),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          minY: 0,
          maxY: maxY,
        ),
      ),
    );
  }

  Widget buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2026, 12, 31),
      focusedDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      eventLoader: (day) =>
          refillEvents[DateTime(day.year, day.month, day.day)] ?? [],
      calendarStyle: const CalendarStyle(
        markerDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
      ),
      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      onDaySelected: (selectedDay, focusedDay) {
        final day = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
        final events = refillEvents[day] ?? [];

        int waterRefills = events.where((e) => e == "REFILL_WATER").length;
        int foodRefills = events.where((e) => e == "REFILL_FOOD").length;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Refill Events"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (events.isEmpty)
                  const Text("No refill events on this day.")
                else ...[
                  Text("💧 Water Refills: $waterRefills"),
                  Text("🍽️ Food Refills: $foodRefills"),
                  const SizedBox(height: 8),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            backgroundColor: theme.colorScheme.primary,
            actions: [
              IconButton(icon: const Icon(Icons.logout), onPressed: logout),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: fetchData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/pet_home.png', height: 180),
                  const SizedBox(height: 20),
                  Text(
                    "Pet Detected: ${petDetected ? 'Yes 🐾' : 'No'}",
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text("Water Level: $waterLevel", style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.water),
                        label: const Text("Refill Water"),
                        onPressed: isSendingCommand
                            ? null
                            : () => sendCommand("REFILL_WATER"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.restaurant),
                        label: const Text("Refill Food"),
                        onPressed: isSendingCommand
                            ? null
                            : () => sendCommand("REFILL_FOOD"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (commandStatus != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      commandStatus!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: commandStatus!.contains("✅")
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  const Text("Water Level History", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  buildChart(screenWidth * 0.9),
                  const SizedBox(height: 30),
                  const Text("Refill Calendar", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  buildCalendar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
