import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

// --- UI Design Constants ---
const Color kScaffoldBackgroundColor = Color(0xFF0A1931);
const Color kCardBackgroundColor = Color(0xFF183A5A);
const Color kLightCardBackgroundColor = Color(0xFFEAEFFB);
const Color kPrimaryTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFF9E9E9E);
const Color kAccentColor = Color(0xFF3B72FF);
const Color kChartLineColor = Color(0xFF33D69F);

// Entry point
void main() {
  runApp(const FuelTrackerApp());
}

// Data model for a fuel log entry.
class FuelLog {
  final double mileage;
  final double liters;
  final double pricePerLiter;
  final double cost;
  final String date;

  FuelLog({
    required this.mileage,
    required this.liters,
    required this.pricePerLiter,
    required this.cost,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'mileage': mileage,
        'liters': liters,
        'pricePerLiter': pricePerLiter,
        'cost': cost,
        'date': date,
      };

  factory FuelLog.fromJson(Map<String, dynamic> json) => FuelLog(
        mileage: json['mileage'],
        liters: json['liters'],
        pricePerLiter: json['pricePerLiter'],
        cost: json['cost'],
        date: json['date'],
      );
}

// Main app
class FuelTrackerApp extends StatelessWidget {
  const FuelTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FuelGauge',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kScaffoldBackgroundColor,
        primaryColor: kAccentColor,
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: kPrimaryTextColor),
          bodyMedium: TextStyle(color: kPrimaryTextColor),
          headlineLarge:
              TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: kPrimaryTextColor),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kCardBackgroundColor,
          hintStyle: const TextStyle(color: kSecondaryTextColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// Bottom navigation scaffold
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const DashboardPage(),
    const HistoryPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: kCardBackgroundColor,
        selectedItemColor: kAccentColor,
        unselectedItemColor: kSecondaryTextColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

// Dashboard with graphs and input form
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<FuelLog> _fuelLogs = [];
  final _mileageController = TextEditingController();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _litersController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("fuel_logs") ?? [];
    setState(() {
      _fuelLogs.clear();
      _fuelLogs.addAll(stored.map((e) => FuelLog.fromJson(jsonDecode(e))));
      _fuelLogs.sort((a, b) => a.mileage.compareTo(b.mileage));
    });
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _fuelLogs.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("fuel_logs", encoded);
  }

  void _addLog() {
    final mileage = double.tryParse(_mileageController.text);
    final liters = double.tryParse(_litersController.text);
    final price = double.tryParse(_priceController.text);

    if (mileage != null && liters != null && price != null) {
      final cost = liters * price;
      final log = FuelLog(
        mileage: mileage,
        liters: liters,
        pricePerLiter: price,
        cost: cost,
        date: _selectedDate.toIso8601String().split("T").first,
      );
      setState(() {
        _fuelLogs.add(log);
        _fuelLogs.sort((a, b) => a.mileage.compareTo(b.mileage));
      });
      _saveLogs();
      _mileageController.clear();
      _litersController.clear();
      _priceController.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Please enter valid numbers in all fields")),
      );
    }
  }

  // --- SUMMARY HELPERS ---
  double get _totalCost => _fuelLogs.fold(0.0, (sum, log) => sum + log.cost);

  double? get _averageConsumptionKmPerLiter {
    if (_fuelLogs.length < 2) return null;
    double totalDistance = _fuelLogs.last.mileage + _fuelLogs.first.mileage;

    double totalFuel =
        _fuelLogs.sublist(1).fold(0.0, (sum, log) => sum + log.liters);

    if (totalDistance <= 0 || totalFuel <= 0) return null;

    return totalDistance / totalFuel;
  }

  List<_MonthlyData> get _monthlySpend {
    final Map<String, double> monthlyTotals = {};
    for (var log in _fuelLogs) {
      final month = DateFormat("MMM yyyy").format(DateTime.parse(log.date));
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + log.cost;
    }
    return monthlyTotals.entries
        .map((e) => _MonthlyData(e.key, e.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    String? recommendationMessage;
    final avgConsumption = _averageConsumptionKmPerLiter;
    if (avgConsumption != null && avgConsumption < 8.0) {
      recommendationMessage =
          "You may be driving too aggressively. Consider checking tire pressure and avoiding rapid acceleration.";
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildSummaryCard(
                        "Avg. Consumption",
                        _averageConsumptionKmPerLiter == null
                            ? "N/A"
                            : "${_averageConsumptionKmPerLiter!.toStringAsFixed(2)} km/L")),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildSummaryCard(
                        "Total Cost", "₱${_totalCost.toStringAsFixed(2)}")),
              ],
            ),
            if (recommendationMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF5A4A18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded,
                      color: Colors.yellow[600]),
                  title: Text(
                    recommendationMessage,
                    style: const TextStyle(color: kPrimaryTextColor, height: 1.4),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _mileageController,
              decoration: const InputDecoration(hintText: "Total Mileage(km)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _litersController,
              decoration: const InputDecoration(hintText: "Fuel Consumed"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(hintText: "Price per Liter"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ListTile(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              tileColor: kCardBackgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.calendar_today,
                  color: kSecondaryTextColor),
              title: Text(
                  "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                  style: const TextStyle(color: kPrimaryTextColor)),
              trailing:
                  const Icon(Icons.edit, color: kSecondaryTextColor, size: 18),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addLog,
                style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    )),
                child: const Text("Add Fuel Log",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            if (_fuelLogs.length < 2)
              const Center(
                  child: Text("Add at least two logs to see charts.",
                      style: TextStyle(color: kSecondaryTextColor)))
            else ...[
              _buildChart(
                  "Fuel Consumed vs Total Mileage",
                  "Mileage (km)",
                  "Liters",
                  LineSeries<FuelLog, double>(
                    dataSource: _fuelLogs,
                    xValueMapper: (log, _) => log.mileage,
                    yValueMapper: (log, _) => log.liters,
                    markerSettings: const MarkerSettings(isVisible: true),
                    color: kAccentColor,
                  )),
              const SizedBox(height: 16),
              _buildChart(
                  "Fuel Cost vs Total Mileage",
                  "Mileage (km)",
                  "Fuel Cost (₱)",
                  LineSeries<FuelLog, double>(
                    dataSource: _fuelLogs,
                    xValueMapper: (log, _) => log.mileage,
                    yValueMapper: (log, _) => log.cost,
                    markerSettings: const MarkerSettings(isVisible: true),
                    color: kChartLineColor,
                  )),
              const SizedBox(height: 16),
              _buildChart(
                  "Monthly Spend",
                  "Month",
                  "Cost (₱)",
                  ColumnSeries<_MonthlyData, String>(
                    dataSource: _monthlySpend,
                    xValueMapper: (data, _) => data.month,
                    yValueMapper: (data, _) => data.cost,
                    color: kAccentColor,
                    dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        textStyle: TextStyle(color: Colors.white)),
                  ),
                  isCategory: true),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kLightCardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChart(String title, String xAxisTitle, String yAxisTitle,
      CartesianSeries series,
      {bool isCategory = false}) {
    final axisTextStyle =
        const TextStyle(color: kSecondaryTextColor, fontSize: 12);
    final titleTextStyle =
        const TextStyle(color: kPrimaryTextColor, fontSize: 16);

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        title: ChartTitle(text: title, textStyle: titleTextStyle),
        primaryXAxis: isCategory
            ? CategoryAxis(
                title: AxisTitle(text: xAxisTitle, textStyle: axisTextStyle),
                labelStyle: axisTextStyle,
                majorGridLines: const MajorGridLines(width: 0),
              )
            : NumericAxis(
                title: AxisTitle(text: xAxisTitle, textStyle: axisTextStyle),
                labelStyle: axisTextStyle,
                majorGridLines: const MajorGridLines(
                    width: 0.5, color: kCardBackgroundColor),
              ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: yAxisTitle, textStyle: axisTextStyle),
          labelStyle: axisTextStyle,
          majorGridLines:
              const MajorGridLines(width: 0.5, color: kCardBackgroundColor),
        ),
        plotAreaBorderWidth: 0,
        series: <CartesianSeries>[series],
      ),
    );
  }
}

// --- Helper class for monthly chart ---
class _MonthlyData {
  final String month;
  final double cost;
  _MonthlyData(this.month, this.cost);
}

// History page
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<FuelLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("fuel_logs") ?? [];
    setState(() {
      _logs = stored.map((e) => FuelLog.fromJson(jsonDecode(e))).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("History", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 24),
            Expanded(
              child: _logs.isEmpty
                  ? const Center(
                      child: Text("No logs yet.",
                          style: TextStyle(color: kSecondaryTextColor)))
                  : ListView.separated(
                      itemCount: _logs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final log = _logs.reversed.toList()[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          tileColor: kCardBackgroundColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          leading: const Icon(Icons.local_gas_station,
                              color: kPrimaryTextColor, size: 30),
                          title: Text(
                            "₱${log.cost.toStringAsFixed(2)} for ${log.liters} L",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            "Mileage: ${log.mileage} km • Date: ${log.date}",
                            style: const TextStyle(
                                color: kSecondaryTextColor, fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Settings page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _resetData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: kCardBackgroundColor,
        title: const Text('Confirm Reset',
            style: TextStyle(color: kPrimaryTextColor)),
        content: const Text(
            'Are you sure you want to delete all your fuel logs? This action cannot be undone.',
            style: TextStyle(color: kSecondaryTextColor)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: kSecondaryTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Reset', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("fuel_logs");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text("All data has been reset.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 24),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              tileColor: kCardBackgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text("Reset All Data",
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () => _resetData(context),
            )
          ],
        ),
      ),
    );
  }
}
