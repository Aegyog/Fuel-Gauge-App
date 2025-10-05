import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_log.dart';
import '../models/maintenance_log.dart';
import '../utils/constants.dart';

// Main screen showing both Fuel and Maintenance history tabs
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Two tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with tabs
      appBar: AppBar(
        title: Text("Vehicle Records",
            style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).textTheme.bodyLarge?.color,
          unselectedLabelColor: kSecondaryTextColor,
          indicatorColor: kAccentColor,
          tabs: const [
            Tab(icon: Icon(Icons.local_gas_station), text: "Fuel"),
            Tab(icon: Icon(Icons.build), text: "Maintenance"),
          ],
        ),
      ),
      // Tabs content
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FuelHistoryTab(), // Fuel tab
          _MaintenanceHistoryTab(), // Maintenance tab
        ],
      ),
    );
  }
}

class _FuelHistoryTab extends StatefulWidget {
  const _FuelHistoryTab();

  @override
  State<_FuelHistoryTab> createState() => _FuelHistoryTabState();
}

class _FuelHistoryTabState extends State<_FuelHistoryTab> {
  List<FuelLog> _allLogs = [];
  List<FuelLog> _displayLogs = [];
  final _searchController = TextEditingController();

  List<String> _vehicleList = ['All Vehicles'];
  String _selectedVehicle = 'All Vehicles';

  @override
  void initState() {
    super.initState();
    _loadLogs(); // Load saved fuel logs
    _searchController.addListener(_filterLogs); // Listen for search updates
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLogs);
    _searchController.dispose();
    super.dispose();
  }

  // Load all saved fuel logs from local storage
  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("fuel_logs") ?? [];
    if (mounted) {
      setState(() {
        _allLogs = stored.map((e) => FuelLog.fromJson(jsonDecode(e))).toList();
        _allLogs.sort(
            (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

        // Extract unique vehicle names for dropdown filter
        final uniqueVehicles =
            LinkedHashSet<String>.from(_allLogs.map((log) => log.vehicleId))
                .toList();
        _vehicleList = ['All Vehicles', ...uniqueVehicles];
        _selectedVehicle = prefs.getString('selectedVehicle') ?? 'All Vehicles';

        if (!_vehicleList.contains(_selectedVehicle)) {
          _selectedVehicle = 'All Vehicles';
        }

        _filterLogs(); // Apply filters
      });
    }
  }

  // Save logs back to local storage
  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    _allLogs.sort((a, b) => a.mileage.compareTo(b.mileage));
    final encoded = _allLogs.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("fuel_logs", encoded);
    _loadLogs(); // Refresh after saving
  }

  // Filter logs by search text or selected vehicle
  void _filterLogs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      List<FuelLog> vehicleFiltered;
      if (_selectedVehicle == 'All Vehicles') {
        vehicleFiltered = _allLogs;
      } else {
        vehicleFiltered =
            _allLogs.where((log) => log.vehicleId == _selectedVehicle).toList();
      }

      if (query.isEmpty) {
        _displayLogs = vehicleFiltered;
      } else {
        _displayLogs = vehicleFiltered.where((log) {
          final dateMatch = log.date.contains(query);
          final noteMatch = log.note?.toLowerCase().contains(query) ?? false;
          final vehicleMatch = log.vehicleId.toLowerCase().contains(query);
          return dateMatch || noteMatch || vehicleMatch;
        }).toList();
      }
    });
  }

  // Dialog for editing or deleting a log entry
  void _showEditDeleteDialog(FuelLog logToEdit) {
    final mileageController =
        TextEditingController(text: logToEdit.mileage.toString());
    final litersController =
        TextEditingController(text: logToEdit.liters.toString());
    final priceController =
        TextEditingController(text: logToEdit.pricePerLiter.toString());
    final noteController = TextEditingController(text: logToEdit.note);
    final vehicleController = TextEditingController(text: logToEdit.vehicleId);
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
                TextField(
                    controller: vehicleController,
                    decoration:
                        const InputDecoration(labelText: "Vehicle Name")),
                TextField(
                    controller: mileageController,
                    decoration: const InputDecoration(labelText: "Mileage")),
                TextField(
                    controller: litersController,
                    decoration: const InputDecoration(labelText: "Liters")),
                TextField(
                    controller: priceController,
                    decoration:
                        const InputDecoration(labelText: "Price/Liter")),
                TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: "Note")),
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
                Navigator.of(context).pop();
                _confirmDelete(logToEdit); // Confirm delete dialog
              },
              child: const Text("Delete",
                  style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () {
                // Update selected log with edited data
                final updatedLog = FuelLog(
                  mileage: double.parse(mileageController.text),
                  liters: double.parse(litersController.text),
                  pricePerLiter: double.parse(priceController.text),
                  cost: double.parse(litersController.text) *
                      double.parse(priceController.text),
                  date: selectedDate.toIso8601String().split('T').first,
                  note: noteController.text,
                  vehicleId: vehicleController.text.trim(),
                );
                final index = _allLogs.indexWhere((log) =>
                    log.date == logToEdit.date &&
                    log.mileage == logToEdit.mileage);
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

  // Ask user to confirm deletion
  void _confirmDelete(FuelLog logToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this log?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                _allLogs.removeWhere((log) =>
                    log.date == logToDelete.date &&
                    log.mileage == logToDelete.mileage);
              });
              _saveLogs();
              Navigator.of(context).pop();
            },
            child:
                const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // Update selected vehicle in preferences
  Future<void> _setSelectedVehicle(String vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedVehicle', vehicle);
    setState(() {
      _selectedVehicle = vehicle;
      _filterLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVehicleFilter(), // Dropdown for vehicle filter
          const SizedBox(height: 16),
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search by date, note, or vehicle...",
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          // Display filtered logs
          Expanded(
            child: _displayLogs.isEmpty
                ? const Center(
                    child: Text("No logs found.",
                        style: TextStyle(color: kSecondaryTextColor)))
                : ListView.separated(
                    itemCount: _displayLogs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final log = _displayLogs[i];
                      return Card(
                        child: ListTile(
                          onTap: () => _showEditDeleteDialog(log),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          leading: const Icon(Icons.directions_car, size: 30),
                          title: Text(
                            "${log.vehicleId}: ₱${log.cost.toStringAsFixed(2)} for ${log.liters} L",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Mileage: ${log.mileage} km • Date: ${log.date}"),
                              if (log.note != null && log.note!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text("Note: ${log.note}",
                                      style: const TextStyle(
                                          color: kSecondaryTextColor,
                                          fontStyle: FontStyle.italic)),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.edit,
                              size: 18, color: kSecondaryTextColor),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Dropdown widget for vehicle filtering
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
}
