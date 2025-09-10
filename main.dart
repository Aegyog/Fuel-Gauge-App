import 'dart:convert';
 import 'package:flutter/material.dart';
 import 'package:provider/provider.dart';
 import 'package:shared_preferences/shared_preferences.dart';
 import 'package:syncfusion_flutter_charts/charts.dart';
 import 'package:intl/intl.dart';

 // --- NEW: Provider for Theme Management ---
 class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', isDark);
    notifyListeners();
  }
 }

 // --- UI Design Constants ---
 const Color kDarkScaffoldBackgroundColor = Color(0xFF0A1931);
 const Color kDarkCardBackgroundColor = Color(0xFF183A5A);
 const Color kLightScaffoldBackgroundColor = Color(0xFFF4F6FD);
 const Color kLightCardBackgroundColor = Colors.white;
 const Color kPrimaryTextColorDark = Colors.white;
 const Color kPrimaryTextColorLight = Color(0xFF0A1931);
 const Color kSecondaryTextColor = Color(0xFF9E9E9E);
 const Color kAccentColor = Color(0xFF3B72FF);
 const Color kChartLineColor = Color(0xFF33D69F);
 const Color kWarningColor = Color(0xFFFFA000);

 // Entry point
 void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: const FuelTrackerApp(),
    ),
  );
 }

 //Data model with an optional note
 class FuelLog {
  final double mileage;
  final double liters;
  final double pricePerLiter;
  final double cost;
  final String date;
  final String? note; // Added for search functionality

  FuelLog({
    required this.mileage,
    required this.liters,
    required this.pricePerLiter,
    required this.cost,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'mileage': mileage,
    'liters': liters,
    'pricePerLiter': pricePerLiter,
    'cost': cost,
    'date': date,
    'note': note,
  };

  factory FuelLog.fromJson(Map<String, dynamic> json) => FuelLog(
    mileage: json['mileage'],
    liters: json['liters'],
    pricePerLiter: json['pricePerLiter'],
    cost: json['cost'],
    date: json['date'],
    note: json['note'],
  );
 }

 // Main app - theme management
 class FuelTrackerApp extends StatelessWidget {
  const FuelTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'FuelGauge',
          themeMode: themeManager.themeMode,
          // --- NEW: Light Theme Definition ---
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: kLightScaffoldBackgroundColor,
            primaryColor: kAccentColor,
            fontFamily: 'Inter',
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: kPrimaryTextColorLight),
              bodyMedium: TextStyle(color: kPrimaryTextColorLight),
              headlineLarge: TextStyle(
                color: kPrimaryTextColorLight, fontWeight: FontWeight.bold),
              titleLarge: TextStyle(color: kPrimaryTextColorLight),
            ),
            cardTheme: CardThemeData( 
              elevation: 1,
              color: kLightCardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[200],
              hintStyle: const TextStyle(color: kSecondaryTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: kLightCardBackgroundColor,
              selectedItemColor: kAccentColor,
              unselectedItemColor: kSecondaryTextColor,
              elevation: 2,
            ),
          ),
          //Dark Theme Definition
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: kDarkScaffoldBackgroundColor,
            primaryColor: kAccentColor,
            fontFamily: 'Inter',
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: kPrimaryTextColorDark),
              bodyMedium: TextStyle(color: kPrimaryTextColorDark),
              headlineLarge: TextStyle(
                color: kPrimaryTextColorDark, fontWeight: FontWeight.bold),
              titleLarge: TextStyle(color: kPrimaryTextColorDark),
            ),
            cardTheme: CardThemeData(
              color: kDarkCardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: kDarkCardBackgroundColor,
              hintStyle: const TextStyle(color: kSecondaryTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: kDarkCardBackgroundColor,
              selectedItemColor: kAccentColor,
              unselectedItemColor: kSecondaryTextColor,
            ),
          ),
          home: const MainNavigation(),
        );
      },
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
  // Use a PageController to preserve state between tabs
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          DashboardPage(),
          HistoryPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
  List<FuelLog> _fuelLogs = [];
  final _mileageController = TextEditingController();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController(); // Controller for the note
  DateTime _selectedDate = DateTime.now();

  // --- NEW: State variables for settings ---
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
        // FIXED: Corrected typo from toIso86-01String to toIso8601String
        date: _selectedDate.toIso8601String().split("T").first,
        note: note.isNotEmpty ? note : null,
      );
      
      // Update the state immediately and sort the list for the charts
      setState(() {
        _fuelLogs.add(log);
        _fuelLogs.sort((a, b) => a.mileage.compareTo(b.mileage));
      });

      // Save the new list in the background without reloading
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
    double totalFuel = _fuelLogs.sublist(0, _fuelLogs.length - 1).fold(0.0, (sum, log) => sum + log.liters);

    if (totalDistance <= 0 || totalFuel <= 0) return null;

    double kmPerLiter = totalDistance / totalFuel;
    // Convert to MPG if necessary
    return _isMiles ? (kmPerLiter * 2.35215) : kmPerLiter;
  }

  List<_MonthlyData> get _monthlySpend {
    final Map<String, double> monthlyTotals = {};
    for (var log in _fuelLogs) {
      final month = DateFormat("MMM yyyy").format(DateTime.parse(log.date));
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + log.cost;
    }
    return monthlyTotals.entries.map((e) => _MonthlyData(e.key, e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    String? recommendationMessage;
    final avgConsumption = _averageConsumption;
    final unit = _isMiles ? "mpg" : "km/L";
    final thresholdInCurrentUnit = _isMiles ? (_efficiencyThreshold * 2.35215) : _efficiencyThreshold;

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
              Text("Dashboard", style: Theme.of(context).textTheme.headlineLarge),
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
                    leading: Icon(Icons.warning_amber_rounded, color: kWarningColor),
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
                decoration: InputDecoration(hintText: "Total Mileage (${_isMiles ? 'mi' : 'km'})"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _litersController,
                decoration: const InputDecoration(hintText: "Fuel Consumed (Liters)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(hintText: "Price per Liter"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField( // New note field
                controller: _noteController,
                decoration: const InputDecoration(hintText: "Note (e.g., City driving)"),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.calendar_today, color: kSecondaryTextColor),
                title: Text("Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}"),
                trailing: const Icon(Icons.edit, color: kSecondaryTextColor, size: 18),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Add Fuel Log", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
              if (_fuelLogs.length < 2)
                const Center(
                  child: Text("Add at least two logs to see charts.",
                    style: TextStyle(color: kSecondaryTextColor)))
              else ...[
                _buildChart(
                  "Fuel Consumed vs Total Mileage", "Mileage", "Liters",
                  LineSeries<FuelLog, double>(
                    dataSource: _fuelLogs,
                    xValueMapper: (log, _) => log.mileage,
                    yValueMapper: (log, _) => log.liters,
                    markerSettings: const MarkerSettings(isVisible: true),
                    color: kAccentColor,
                  )),
                const SizedBox(height: 16),
                _buildChart(
                  "Fuel Cost vs Total Mileage", "Mileage", "Fuel Cost (₱)",
                  LineSeries<FuelLog, double>(
                    dataSource: _fuelLogs,
                    xValueMapper: (log, _) => log.mileage,
                    yValueMapper: (log, _) => log.cost,
                    markerSettings: const MarkerSettings(isVisible: true),
                    color: kChartLineColor,
                  )),
                const SizedBox(height: 16),
                _buildChart(
                  "Monthly Spend", "Month", "Cost (₱)",
                  ColumnSeries<_MonthlyData, String>(
                    dataSource: _monthlySpend,
                    xValueMapper: (data, _) => data.month,
                    yValueMapper: (data, _) => data.cost,
                    color: kAccentColor,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
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
            Text(title, style: TextStyle(color: kSecondaryTextColor, fontSize: 14)),
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
    CartesianSeries series, {bool isCategory = false}) {
    final axisTextStyle = TextStyle(color: kSecondaryTextColor, fontSize: 12);
    final titleTextStyle = TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16);

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
            majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey.withOpacity(0.2)),
          ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: yAxisTitle, textStyle: axisTextStyle),
          labelStyle: axisTextStyle,
          majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey.withOpacity(0.2)),
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

 // --- NEW: History page with Edit, Delete, Search, and Filter ---
 class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
 }

 class _HistoryPageState extends State<HistoryPage> {
  List<FuelLog> _allLogs = [];
  List<FuelLog> _filteredLogs = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _searchController.addListener(_filterLogs);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLogs);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("fuel_logs") ?? [];
    setState(() {
      _allLogs = stored.map((e) => FuelLog.fromJson(jsonDecode(e))).toList();
      // Sort by date descending (newest first)
      _allLogs.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      _filteredLogs = _allLogs;
    });
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    // Sort by mileage before saving to keep dashboard charts consistent
    _allLogs.sort((a, b) => a.mileage.compareTo(b.mileage));
    final encoded = _allLogs.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("fuel_logs", encoded);
    _loadLogs(); // Reload to apply sorting for history view
  }

  void _filterLogs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLogs = _allLogs.where((log) {
        final dateMatch = log.date.contains(query);
        final noteMatch = log.note?.toLowerCase().contains(query) ?? false;
        return dateMatch || noteMatch;
      }).toList();
    });
  }

  void _showEditDeleteDialog(FuelLog logToEdit) {
    final mileageController = TextEditingController(text: logToEdit.mileage.toString());
    final litersController = TextEditingController(text: logToEdit.liters.toString());
    final priceController = TextEditingController(text: logToEdit.pricePerLiter.toString());
    final noteController = TextEditingController(text: logToEdit.note);
    DateTime selectedDate = DateTime.parse(logToEdit.date);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Log"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: mileageController, decoration: const InputDecoration(labelText: "Mileage")),
                TextField(controller: litersController, decoration: const InputDecoration(labelText: "Liters")),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price/Liter")),
                TextField(controller: noteController, decoration: const InputDecoration(labelText: "Note")),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Delete logic
                Navigator.of(context).pop(); // Close edit dialog
                _confirmDelete(logToEdit);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () {
                // Edit logic
                final updatedLog = FuelLog(
                  mileage: double.parse(mileageController.text),
                  liters: double.parse(litersController.text),
                  pricePerLiter: double.parse(priceController.text),
                  cost: double.parse(litersController.text) * double.parse(priceController.text),
                  date: selectedDate.toIso8601String().split('T').first,
                  note: noteController.text,
                );
                final index = _allLogs.indexWhere((log) => log.date == logToEdit.date && log.mileage == logToEdit.mileage);
                if (index != -1) {
                  setState(() => _allLogs[index] = updatedLog);
                  _saveLogs();
                }
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(FuelLog logToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this log?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                _allLogs.removeWhere((log) => log.date == logToDelete.date && log.mileage == logToDelete.mileage);
              });
              _saveLogs();
              Navigator.of(context).pop();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by date or note...",
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredLogs.isEmpty
                ? const Center(
                  child: Text("No logs found.", style: TextStyle(color: kSecondaryTextColor)))
                : ListView.separated(
                  itemCount: _filteredLogs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final log = _filteredLogs[i];
                    return Card(
                      child: ListTile(
                        onTap: () => _showEditDeleteDialog(log),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        leading: const Icon(Icons.local_gas_station, size: 30),
                        title: Text(
                          "₱${log.cost.toStringAsFixed(2)} for ${log.liters} L",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mileage: ${log.mileage} km • Date: ${log.date}"),
                            if (log.note != null && log.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text("Note: ${log.note}",
                                  style: const TextStyle(color: kSecondaryTextColor, fontStyle: FontStyle.italic)),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.edit, size: 18, color: kSecondaryTextColor),
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

 // --- NEW: Settings page with Theme, Units, and Efficiency Goal ---
 class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
 }

 class _SettingsPageState extends State<SettingsPage> {
  bool _isMiles = false;
  double _efficiencyThreshold = 9.0;
  final _thresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMiles = prefs.getBool('isMiles') ?? false;
      _efficiencyThreshold = prefs.getDouble('efficiencyThreshold') ?? 9.0;
      _thresholdController.text = _efficiencyThreshold.toString();
    });
  }

  Future<void> _setUnit(bool isMiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMiles', isMiles);
    setState(() => _isMiles = isMiles);
  }

  Future<void> _setEfficiencyThreshold(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('efficiencyThreshold', value);
    setState(() => _efficiencyThreshold = value);
  }

  void _showThresholdDialog() {
    _thresholdController.text = _efficiencyThreshold.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Efficiency Goal"),
        content: TextField(
          controller: _thresholdController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Efficiency (km/L)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final newValue = double.tryParse(_thresholdController.text);
              if (newValue != null && newValue > 0) {
                _setEfficiencyThreshold(newValue);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _resetData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text(
          'Are you sure you want to delete all your fuel logs? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
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
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkTheme = themeManager.themeMode == ThemeMode.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Dark Theme"),
                    value: isDarkTheme,
                    onChanged: (value) => themeManager.toggleTheme(value),
                    secondary: Icon(isDarkTheme ? Icons.dark_mode : Icons.light_mode),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("Use Miles (mpg)"),
                    subtitle: const Text("Default is Kilometers (km/L)"),
                    value: _isMiles,
                    onChanged: _setUnit,
                    secondary: const Icon(Icons.straighten),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.track_changes),
                title: const Text("Efficiency Goal"),
                subtitle: Text("Recommendation appears below ${_efficiencyThreshold.toStringAsFixed(1)} km/L"),
                trailing: const Icon(Icons.edit),
                onTap: _showThresholdDialog,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).brightness == Brightness.dark
                ? kDarkCardBackgroundColor
                : Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text("Reset All Data", style: TextStyle(color: Colors.redAccent)),
                onTap: () => _resetData(context),
              ),
            )
          ],
        ),
      ),
    );
  }
}
