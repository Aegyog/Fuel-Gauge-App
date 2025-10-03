import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/fuel_log.dart';
import '../models/maintenance_log.dart';
import '../utils/constants.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Fuel Log State
  List<FuelLog> _allFuelLogs = [];
  final _mileageController = TextEditingController();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  final _vehicleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Settings State
  bool _isMiles = false;
  double _efficiencyThreshold = 9.0;

  // Chart State
  final PageController _chartPageController = PageController();
  int _currentChartIndex = 0;

  // Vehicle State
  List<String> _vehicleList = ['All Vehicles'];
  String _selectedVehicle = 'All Vehicles';

  // Maintenance State
  List<MaintenanceLog> _dueReminders = [];

  // Computed list of logs based on the vehicle filter
  List<FuelLog> get _filteredLogs {
    if (_selectedVehicle == 'All Vehicles' || _selectedVehicle.isEmpty) {
      return _allFuelLogs;
    }
    return _allFuelLogs
        .where((log) => log.vehicleId == _selectedVehicle)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _litersController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _vehicleController.dispose();
    _chartPageController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await _loadSettings();
    await _loadLogs();
    await _checkReminders();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isMiles = prefs.getBool('isMiles') ?? false;
        _efficiencyThreshold = prefs.getDouble('efficiencyThreshold') ?? 9.0;
      });
    }
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("fuel_logs") ?? [];
    if (mounted) {
      setState(() {
        _allFuelLogs =
            stored.map((e) => FuelLog.fromJson(jsonDecode(e))).toList();
        _allFuelLogs.sort((a, b) => a.mileage.compareTo(b.mileage));

        final uniqueVehicles =
            LinkedHashSet<String>.from(_allFuelLogs.map((log) => log.vehicleId))
                .toList();
        _vehicleList = ['All Vehicles', ...uniqueVehicles];

        _selectedVehicle = prefs.getString('selectedVehicle') ?? 'All Vehicles';
        if (!_vehicleList.contains(_selectedVehicle)) {
          _selectedVehicle = 'All Vehicles';
        }
      });
    }
  }

  Future<void> _checkReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("maintenance_logs") ?? [];
    if (!mounted) return;

    final allMaintenance =
        stored.map((e) => MaintenanceLog.fromJson(jsonDecode(e))).toList();

    final latestLog = _filteredLogs.isNotEmpty ? _filteredLogs.last : null;
    if (latestLog == null && _selectedVehicle != 'All Vehicles') {
      setState(() {
        _dueReminders = [];
      });
      return;
    }

    List<MaintenanceLog> due = [];
    for (var mLog in allMaintenance) {
      if (mLog.vehicleId == _selectedVehicle) {
        bool isDue = false;
        if (mLog.nextReminderMileage != null &&
            latestLog != null &&
            latestLog.mileage >= mLog.nextReminderMileage!) {
          isDue = true;
        }
        if (mLog.nextReminderDate != null &&
            mLog.nextReminderDate!.isNotEmpty &&
            DateTime.now().isAfter(DateTime.parse(mLog.nextReminderDate!))) {
          isDue = true;
        }
        if (isDue) {
          due.add(mLog);
        }
      }
    }

    if (mounted) {
      setState(() {
        _dueReminders = due;
      });
    }
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _allFuelLogs.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("fuel_logs", encoded);
  }

  void _addLog() {
    final mileage = double.tryParse(_mileageController.text);
    final liters = double.tryParse(_litersController.text);
    final price = double.tryParse(_priceController.text);
    final note = _noteController.text;
    final vehicleId = _vehicleController.text.trim();

    if (mileage != null &&
        liters != null &&
        price != null &&
        vehicleId.isNotEmpty) {
      final log = FuelLog(
        mileage: mileage,
        liters: liters,
        pricePerLiter: price,
        cost: liters * price,
        date: _selectedDate.toIso8601String().split("T").first,
        note: note.isNotEmpty ? note : null,
        vehicleId: vehicleId,
      );

      setState(() {
        _allFuelLogs.add(log);
        _allFuelLogs.sort((a, b) => a.mileage.compareTo(b.mileage));

        if (!_vehicleList.contains(vehicleId)) {
          _vehicleList.add(vehicleId);
        }
      });

      _saveLogs();

      _mileageController.clear();
      _litersController.clear();
      _priceController.clear();
      _noteController.clear();
      _vehicleController.clear();
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Please enter valid numbers and a vehicle name")),
      );
    }
  }

  double get _totalCost =>
      _filteredLogs.fold(0.0, (sum, log) => sum + log.cost);

  double? get _averageConsumption {
    if (_filteredLogs.length < 2) return null;

    double totalDistance =
        _filteredLogs.last.mileage - _filteredLogs.first.mileage;
    double totalFuel = _filteredLogs
        .sublist(0, _filteredLogs.length - 1)
        .fold(0.0, (sum, log) => sum + log.liters);

    if (totalDistance <= 0 || totalFuel <= 0) return null;

    double kmPerLiter = totalDistance / totalFuel;
    return _isMiles ? (kmPerLiter * 2.35215) : kmPerLiter;
  }

  List<_MonthlyData> get _monthlySpend {
    final Map<String, double> monthlyTotals = {};
    for (var log in _filteredLogs) {
      final month = DateFormat("MMM yyyy").format(DateTime.parse(log.date));
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + log.cost;
    }
    return monthlyTotals.entries
        .map((e) => _MonthlyData(e.key, e.value))
        .toList();
  }

  Future<void> _setSelectedVehicle(String vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedVehicle', vehicle);
    setState(() {
      _selectedVehicle = vehicle;
      if (vehicle != 'All Vehicles') {
        _vehicleController.text = vehicle;
      } else {
        _vehicleController.clear();
      }
    });
    await _checkReminders();
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
              const SizedBox(height: 16),
              _buildVehicleFilter(),
              const SizedBox(height: 16),
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
              if (_dueReminders.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text("Maintenance Due",
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ..._dueReminders
                    .map((log) => Card(
                          color: kWarningColor.withOpacity(0.2),
                          child: ListTile(
                            leading: const Icon(Icons.build_circle,
                                color: kWarningColor),
                            title: Text(log.serviceType),
                            subtitle:
                                const Text("This vehicle is due for service."),
                          ),
                        ))
                    .toList(),
              ],
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
                controller: _vehicleController,
                decoration: const InputDecoration(
                    hintText: "Vehicle Name (e.g., My Sedan)"),
              ),
              const SizedBox(height: 12),
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
              if (_filteredLogs.length < 2)
                Center(
                    child: Text(
                        _selectedVehicle == 'All Vehicles'
                            ? "Add at least two logs to see charts."
                            : "Add at least two logs for this vehicle to see charts.",
                        style: const TextStyle(color: kSecondaryTextColor)))
              else
                Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: PageView(
                        controller: _chartPageController,
                        onPageChanged: (int index) {
                          setState(() {
                            _currentChartIndex = index;
                          });
                        },
                        children: [
                          _buildChart(
                              "Fuel Consumed vs Total Mileage",
                              "Mileage",
                              "Liters",
                              LineSeries<FuelLog, double>(
                                dataSource: _filteredLogs,
                                xValueMapper: (log, _) => log.mileage,
                                yValueMapper: (log, _) => log.liters,
                                markerSettings:
                                    const MarkerSettings(isVisible: true),
                                color: kAccentColor,
                              )),
                          _buildChart(
                              "Fuel Cost vs Total Mileage",
                              "Mileage",
                              "Fuel Cost (₱)",
                              LineSeries<FuelLog, double>(
                                dataSource: _filteredLogs,
                                xValueMapper: (log, _) => log.mileage,
                                yValueMapper: (log, _) => log.cost,
                                markerSettings:
                                    const MarkerSettings(isVisible: true),
                                color: kChartLineColor,
                              )),
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
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? kPrimaryTextColorDark
                                        : kPrimaryTextColorLight,
                                  ),
                                ),
                              ),
                              isCategory: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildChartIndicator(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedVehicle,
          isExpanded: true,
          items: _vehicleList.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              _setSelectedVehicle(newValue);
            }
          },
          hint: const Text("Select Vehicle"),
        ),
      ),
    );
  }

  Widget _buildChartIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return GestureDetector(
          onTap: () {
            _chartPageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentChartIndex == index
                  ? kAccentColor
                  : kSecondaryTextColor.withOpacity(0.5),
            ),
          ),
        );
      }),
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
    return SfCartesianChart(
      title: ChartTitle(
          text: title,
          textStyle:
              Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
      primaryXAxis: isCategory
          ? CategoryAxis(
              title: AxisTitle(
                  text: xAxisTitle,
                  textStyle: const TextStyle(
                      color: kSecondaryTextColor, fontSize: 12)),
              labelStyle:
                  const TextStyle(color: kSecondaryTextColor, fontSize: 12),
              majorGridLines: const MajorGridLines(width: 0),
            )
          : NumericAxis(
              title: AxisTitle(
                  text: xAxisTitle,
                  textStyle: const TextStyle(
                      color: kSecondaryTextColor, fontSize: 12)),
              labelStyle:
                  const TextStyle(color: kSecondaryTextColor, fontSize: 12),
              majorGridLines: MajorGridLines(
                  width: 0.5, color: Colors.grey.withOpacity(0.2)),
            ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(
            text: yAxisTitle,
            textStyle:
                const TextStyle(color: kSecondaryTextColor, fontSize: 12)),
        labelStyle: const TextStyle(color: kSecondaryTextColor, fontSize: 12),
        majorGridLines:
            MajorGridLines(width: 0.5, color: Colors.grey.withOpacity(0.2)),
      ),
      plotAreaBorderWidth: 0,
      series: <CartesianSeries>[series],
    );
  }
}

class _MonthlyData {
  final String month;
  final double cost;
  _MonthlyData(this.month, this.cost);
}
