import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../models/fuel_log.dart';
import '../utils/constants.dart';

// Dashboard with graphs and input form
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<FuelLog> _fuelLogs = [];
  final _mileageController = TextEditingController();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController(); // Controller for the note
  DateTime _selectedDate = DateTime.now();

  bool _isMiles = false;
  double _efficiencyThreshold = 9.0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await _loadSettings();
    await _loadLogs();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _litersController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMiles = prefs.getBool('isMiles') ?? false;
      _efficiencyThreshold = prefs.getDouble('efficiencyThreshold') ?? 9.0;
    });
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("fuel_logs") ?? [];
    setState(() {
      _fuelLogs = stored.map((e) => FuelLog.fromJson(jsonDecode(e))).toList();
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
    final note = _noteController.text;

    if (mileage != null && liters != null && price != null) {
      final log = FuelLog(
        mileage: mileage,
        liters: liters,
        pricePerLiter: price,
        cost: liters * price,
        date: _selectedDate.toIso8601String().split("T").first,
        note: note.isNotEmpty ? note : null,
      );

      setState(() {
        _fuelLogs.add(log);
        _fuelLogs.sort((a, b) => a.mileage.compareTo(b.mileage));
      });

      _saveLogs();

      _mileageController.clear();
      _litersController.clear();
      _priceController.clear();
      _noteController.clear();
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

  double? get _averageConsumption {
    if (_fuelLogs.length < 2) return null;

    double totalDistance = _fuelLogs.last.mileage + _fuelLogs.first.mileage;
    double totalFuel = _fuelLogs
        .sublist(0, _fuelLogs.length - 1)
        .fold(0.0, (sum, log) => sum + log.liters);

    if (totalDistance <= 0 || totalFuel <= 0) return null;

    double kmPerLiter = totalDistance / totalFuel;
    return _isMiles ? (kmPerLiter * 2.35215) : kmPerLiter;
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
    final avgConsumption = _averageConsumption;
    final unit = _isMiles ? "mpg" : "km/L";
    final thresholdInCurrentUnit =
        _isMiles ? (_efficiencyThreshold * 2.35215) : _efficiencyThreshold;

    if (avgConsumption != null && avgConsumption < thresholdInCurrentUnit) {
      recommendationMessage =
          "You may be driving too aggressively. Consider checking tire pressure and avoiding rapid acceleration.";
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Dashboard",
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: _buildSummaryCard(
                          "Avg. Consumption",
                          avgConsumption == null
                              ? "N/A"
                              : "${avgConsumption.toStringAsFixed(2)} $unit")),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildSummaryCard(
                          "Total Cost", "₱${_totalCost.toStringAsFixed(2)}")),
                ],
              ),
              if (recommendationMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF5A4A18)
                      : kWarningColor.withOpacity(0.2),
                  child: ListTile(
                    leading:
                        Icon(Icons.warning_amber_rounded, color: kWarningColor),
                    title: Text(
                      recommendationMessage,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _mileageController,
                decoration: InputDecoration(
                    hintText: "Total Mileage (${_isMiles ? 'mi' : 'km'})"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _litersController,
                decoration:
                    const InputDecoration(hintText: "Fuel Consumed (Liters)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(hintText: "Price per Liter"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                    hintText: "Note (e.g., City driving)"),
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
                tileColor: Theme.of(context).inputDecorationTheme.fillColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.calendar_today,
                    color: kSecondaryTextColor),
                title: Text(
                    "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}"),
                trailing: const Icon(Icons.edit,
                    color: kSecondaryTextColor, size: 18),
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
                          borderRadius: BorderRadius.circular(12))),
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
                    "Mileage",
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
                    "Mileage",
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
                      dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? kPrimaryTextColorDark
                                    : kPrimaryTextColorLight,
                          )),
                    ),
                    isCategory: true),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: isDark ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(color: kSecondaryTextColor, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String title, String xAxisTitle, String yAxisTitle,
      CartesianSeries series,
      {bool isCategory = false}) {
    final axisTextStyle = TextStyle(color: kSecondaryTextColor, fontSize: 12);
    final titleTextStyle = TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16);

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
                majorGridLines: MajorGridLines(
                    width: 0.5, color: Colors.grey.withOpacity(0.2)),
              ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: yAxisTitle, textStyle: axisTextStyle),
          labelStyle: axisTextStyle,
          majorGridLines:
              MajorGridLines(width: 0.5, color: Colors.grey.withOpacity(0.2)),
        ),
        plotAreaBorderWidth: 0,
        series: <CartesianSeries>[series],
      ),
    );
  }
}

// Helper class for monthly chart
class _MonthlyData {
  final String month;
  final double cost;
  _MonthlyData(this.month, this.cost);
}
