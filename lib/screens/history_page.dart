import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/fuel_log.dart';
import '../models/maintenance_log.dart';
import '../utils/constants.dart';

const double kmPerMile = 1.60934;
const double litersPerGallon = 3.78541;

// Main screen showing both Fuel and Maintenance history tabs
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Initializes the state and sets up the TabController.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Two tabs
  }

  /// Cleans up the controller when the widget is removed.
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Builds the UI for the History page, including the AppBar and TabBar.
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
  late Future<List<FuelLog>> _logsFuture;
  List<FuelLog> _allLogs = [];
  List<FuelLog> _displayLogs = [];
  final _searchController = TextEditingController();

  List<String> _vehicleList = ['All Vehicles'];
  String _selectedVehicle = 'All Vehicles';
  bool _isMiles = false;

  /// Initializes the state for the fuel history tab.
  @override
  void initState() {
    super.initState();
    _logsFuture = _loadSettingsAndLogs(); // Load saved fuel logs
    _searchController.addListener(_filterLogs); // Listen for search updates
  }

  /// Cleans up controllers when the widget is removed.
  @override
  void dispose() {
    _searchController.removeListener(_filterLogs);
    _searchController.dispose();
    super.dispose();
  }

  Future<List<FuelLog>> _loadSettingsAndLogs() async {
    await _loadSettings();
    return _loadLogs();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isMiles = prefs.getBool('isMiles') ?? false;
      });
    }
  }

  /// Loads all saved fuel logs from the Supabase database.
  Future<List<FuelLog>> _loadLogs() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('fuel_logs')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    final logs = response.map((data) => FuelLog.fromJson(data)).toList();

    if (mounted) {
      setState(() {
        _allLogs = logs;
        // Extract unique vehicle names for dropdown filter
        final uniqueVehicles =
            LinkedHashSet<String>.from(_allLogs.map((log) => log.vehicleId))
                .toList();
        _vehicleList = ['All Vehicles', ...uniqueVehicles];
        _filterLogs();
      });
    }

    return logs;
  }

  /// Refreshes the data from the database.
  void _refreshData() {
    setState(() {
      _logsFuture = _loadSettingsAndLogs();
    });
  }

  /// Filters the displayed logs based on the search text and selected vehicle.
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

  /// Shows a dialog for editing or deleting a selected fuel log entry.
  void _showEditDeleteDialog(FuelLog logToEdit) async {
    final displayMileage =
        _isMiles ? (logToEdit.mileage / kmPerMile) : logToEdit.mileage;
    final displayVolume =
        _isMiles ? (logToEdit.liters / litersPerGallon) : logToEdit.liters;
    final displayPrice = _isMiles
        ? (logToEdit.pricePerLiter * litersPerGallon)
        : logToEdit.pricePerLiter;

    final mileageController =
        TextEditingController(text: displayMileage.toStringAsFixed(2));
    final litersController =
        TextEditingController(text: displayVolume.toStringAsFixed(2));
    final priceController =
        TextEditingController(text: displayPrice.toStringAsFixed(2));
    final noteController = TextEditingController(text: logToEdit.note);
    final vehicleController = TextEditingController(text: logToEdit.vehicleId);
    DateTime selectedDate = DateTime.parse(logToEdit.date);

    final updatedLog = await showDialog<FuelLog>(
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
                    decoration: InputDecoration(
                        labelText: "Mileage (${_isMiles ? 'mi' : 'km'})")),
                TextField(
                    controller: litersController,
                    decoration: InputDecoration(
                        labelText:
                            "Fuel Consumed (${_isMiles ? 'gallons' : 'Liters'})")),
                TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                        labelText:
                            "Price per ${_isMiles ? 'Gallon' : 'Liter'}")),
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
                final mileageInput = double.parse(mileageController.text);
                final volumeInput = double.parse(litersController.text);
                final priceInput = double.parse(priceController.text);

                // Return updated log
                final log = FuelLog(
                  id: logToEdit.id,
                  userId: logToEdit.userId,
                  mileage: _isMiles ? (mileageInput * kmPerMile) : mileageInput,
                  liters:
                      _isMiles ? (volumeInput * litersPerGallon) : volumeInput,
                  pricePerLiter:
                      _isMiles ? (priceInput / litersPerGallon) : priceInput,
                  cost: (_isMiles
                          ? (volumeInput * litersPerGallon)
                          : volumeInput) *
                      (_isMiles ? (priceInput / litersPerGallon) : priceInput),
                  date: selectedDate.toIso8601String().split('T').first,
                  note: noteController.text,
                  vehicleId: vehicleController.text.trim(),
                );
                Navigator.of(context).pop(log);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (updatedLog != null) {
      await supabase
          .from('fuel_logs')
          .update(updatedLog.toJson())
          .match({'id': updatedLog.id!});
      _refreshData();
    }
  }

  /// Shows a confirmation dialog before deleting a fuel log.
  void _confirmDelete(FuelLog logToDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this log?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await supabase.from('fuel_logs').delete().match({'id': logToDelete.id!});
      _refreshData();
    }
  }

  /// Updates the selected vehicle filter.
  void _setSelectedVehicle(String vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _filterLogs();
    });
  }

  /// Builds the UI for the fuel history tab.
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
            child: FutureBuilder<List<FuelLog>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (_displayLogs.isEmpty) {
                  return const Center(
                      child: Text("No logs found.",
                          style: TextStyle(color: kSecondaryTextColor)));
                }

                return ListView.separated(
                  itemCount: _displayLogs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final currentLog = _displayLogs[i];
                    String consumptionText = 'N/A'; // Default value

                    // Calculate consumption based on current log's mileage and liters.
                    if (currentLog.liters > 0) {
                      final double consumption =
                          currentLog.mileage / currentLog.liters;
                      if (_isMiles) {
                        final double mpg = consumption * 2.35215;
                        consumptionText = '${mpg.toStringAsFixed(2)} MPG';
                      } else {
                        consumptionText =
                            '${consumption.toStringAsFixed(2)} km/L';
                      }
                    }

                    final formattedDate = DateFormat('MM/dd/yyyy')
                        .format(DateTime.parse(currentLog.date));

                    final displayMileage = _isMiles
                        ? (currentLog.mileage / kmPerMile)
                        : currentLog.mileage;
                    final displayLiters = _isMiles
                        ? (currentLog.liters / litersPerGallon)
                        : currentLog.liters;
                    final mileageUnit = _isMiles ? 'mi' : 'km';
                    final volumeUnit = _isMiles ? 'gal' : 'L';

                    return Card(
                      child: ListTile(
                        onTap: () => _showEditDeleteDialog(currentLog),
                        onLongPress: () => _confirmDelete(currentLog),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        leading: const Icon(Icons.directions_car, size: 30),
                        title: Text(
                          "${currentLog.vehicleId}: ₱${currentLog.cost.toStringAsFixed(2)} for ${displayLiters.toStringAsFixed(2)} $volumeUnit",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Mileage: ${displayMileage.toStringAsFixed(1)} $mileageUnit • Date: $formattedDate"),
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "Average Consumption: $consumptionText",
                                style: const TextStyle(
                                    color: kSecondaryTextColor,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                            if (currentLog.note != null &&
                                currentLog.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text("Note: ${currentLog.note}",
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the dropdown widget for filtering by vehicle.
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

// --- WIDGET FOR THE "MAINTENANCE" TAB ---
class _MaintenanceHistoryTab extends StatefulWidget {
  const _MaintenanceHistoryTab();

  @override
  State<_MaintenanceHistoryTab> createState() => __MaintenanceHistoryTabState();
}

class __MaintenanceHistoryTabState extends State<_MaintenanceHistoryTab> {
  late Future<List<MaintenanceLog>> _logsFuture;
  bool _isMiles = false;

  /// Initializes the state for the maintenance history tab.
  @override
  void initState() {
    super.initState();
    _logsFuture = _loadSettingsAndLogs();
  }

  Future<List<MaintenanceLog>> _loadSettingsAndLogs() async {
    await _loadSettings();
    return _loadMaintenanceLogs();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isMiles = prefs.getBool('isMiles') ?? false;
      });
    }
  }

  /// Refreshes the data from the database.
  Future<void> _refreshData() async {
    setState(() {
      _logsFuture = _loadSettingsAndLogs();
    });
  }

  /// Loads all saved maintenance logs from the Supabase database.
  Future<List<MaintenanceLog>> _loadMaintenanceLogs() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('maintenance_logs')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return response.map((data) => MaintenanceLog.fromJson(data)).toList();
  }

  /// Shows a dialog to add a new maintenance log or edit an existing one.
  void _addOrEditLog({MaintenanceLog? log}) async {
    if (!mounted) return;
    final result = await showDialog<MaintenanceLog>(
      context: context,
      builder: (context) => _AddMaintenanceDialog(log: log, isMiles: _isMiles),
    );

    if (result != null) {
      if (log == null) {
        // Insert new log
        final Map<String, dynamic> logData = result.toJson();
        logData.remove('id'); // Remove ID for insertion
        await supabase.from('maintenance_logs').insert(logData);
      } else {
        // Update existing log
        await supabase
            .from('maintenance_logs')
            .update(result.toJson())
            .match({'id': result.id!});
      }
      _refreshData();
    }
  }

  /// Shows a confirmation dialog before deleting a maintenance log.
  void _confirmDelete(MaintenanceLog logToDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text(
            "Are you sure you want to delete the '${logToDelete.serviceType}' record?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await supabase
          .from('maintenance_logs')
          .delete()
          .match({'id': logToDelete.id!});
      _refreshData();
    }
  }

  /// Builds the UI for the maintenance history tab.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<MaintenanceLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(
                child: Text("No maintenance logs yet.\nTap '+' to add one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kSecondaryTextColor)));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              final displayMileage =
                  _isMiles ? (log.mileage / kmPerMile) : log.mileage;
              final mileageUnit = _isMiles ? 'mi' : 'km';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.build_circle_outlined),
                  title: Text("${log.vehicleId}: ${log.serviceType}"),
                  subtitle: Text(
                      "On ${DateFormat('MM/dd/yyyy').format(DateTime.parse(log.date))} at ${displayMileage.toStringAsFixed(1)} $mileageUnit"),
                  trailing: log.cost != null && log.cost! > 0
                      ? Text("₱${log.cost?.toStringAsFixed(2)}")
                      : null,
                  onTap: () => _addOrEditLog(log: log),
                  onLongPress: () => _confirmDelete(log),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditLog(),
        backgroundColor: kAccentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// --- DIALOG FOR ADDING/EDITING MAINTENANCE ---
class _AddMaintenanceDialog extends StatefulWidget {
  final MaintenanceLog? log;
  final bool isMiles;
  const _AddMaintenanceDialog({this.log, required this.isMiles});

  @override
  State<_AddMaintenanceDialog> createState() => _AddMaintenanceDialogState();
}

class _AddMaintenanceDialogState extends State<_AddMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serviceController = TextEditingController();
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _reminderMileageController = TextEditingController();

  List<String> _vehicleList = [];
  String? _selectedVehicle;
  DateTime _selectedDate = DateTime.now();
  DateTime? _reminderDate;

  /// Initializes the state for the add/edit maintenance dialog.
  @override
  void initState() {
    super.initState();
    _loadVehicles();
    if (widget.log != null) {
      final log = widget.log!;
      _serviceController.text = log.serviceType;
      _mileageController.text =
          (widget.isMiles ? (log.mileage / kmPerMile) : log.mileage)
              .toStringAsFixed(1);
      _costController.text = log.cost?.toString() ?? '';
      _notesController.text = log.notes ?? '';
      _selectedVehicle = log.vehicleId;
      _selectedDate = DateTime.parse(log.date);
      if (log.nextReminderMileage != null) {
        _reminderMileageController.text = (widget.isMiles
                ? (log.nextReminderMileage! / kmPerMile)
                : log.nextReminderMileage!)
            .toStringAsFixed(1);
      }
      if (log.nextReminderDate != null) {
        _reminderDate = DateTime.parse(log.nextReminderDate!);
      }
    }
  }

  /// Fetches unique vehicle names from fuel logs to populate the dropdown.
  Future<void> _loadVehicles() async {
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('fuel_logs')
        .select('vehicle_id')
        .eq('user_id', userId);

    final uniqueVehicles = LinkedHashSet<String>.from(
        response.map((row) => row['vehicle_id'] as String)).toList();

    if (mounted) {
      setState(() {
        _vehicleList = uniqueVehicles;
        if (widget.log == null && _vehicleList.isNotEmpty) {
          _selectedVehicle = _vehicleList.first;
        }
      });
    }
  }

  /// Cleans up controllers when the widget is removed.
  @override
  void dispose() {
    _serviceController.dispose();
    _mileageController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _reminderMileageController.dispose();
    super.dispose();
  }

  /// Validates the form and saves the new or updated maintenance log.
  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final userId = supabase.auth.currentUser!.id;
      final mileageInput = double.parse(_mileageController.text);
      final reminderMileageInput =
          double.tryParse(_reminderMileageController.text);

      final newLog = MaintenanceLog(
        id: widget.log?.id,
        userId: userId,
        vehicleId: _selectedVehicle!,
        serviceType: _serviceController.text.trim(),
        date: _selectedDate.toIso8601String(),
        mileage: widget.isMiles ? (mileageInput * kmPerMile) : mileageInput,
        cost: double.tryParse(_costController.text),
        notes: _notesController.text.trim(),
        nextReminderMileage: reminderMileageInput != null
            ? (widget.isMiles
                ? (reminderMileageInput * kmPerMile)
                : reminderMileageInput)
            : null,
        nextReminderDate: _reminderDate?.toIso8601String(),
      );
      Navigator.of(context).pop(newLog);
    }
  }

  /// Builds the UI for the add/edit maintenance dialog.
  @override
  Widget build(BuildContext context) {
    final mileageUnit = widget.isMiles ? 'mi' : 'km';
    return AlertDialog(
      title: Text(widget.log == null ? "Add Maintenance" : "Edit Maintenance"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedVehicle,
                items: _vehicleList
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedVehicle = value),
                decoration: const InputDecoration(labelText: "Vehicle"),
                validator: (v) => v == null ? "Please select a vehicle" : null,
              ),
              TextFormField(
                controller: _serviceController,
                decoration: const InputDecoration(labelText: "Service Type"),
                validator: (v) =>
                    v!.isEmpty ? "Please enter a service type" : null,
              ),
              TextFormField(
                controller: _mileageController,
                decoration:
                    InputDecoration(labelText: "Mileage ($mileageUnit)"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Please enter mileage" : null,
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: "Cost (Optional)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: "Notes (Optional)"),
              ),
              const SizedBox(height: 20),
              const Text("Next Reminder (Optional)",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _reminderMileageController,
                decoration: InputDecoration(
                    labelText: "At Mileage (e.g., 60000 $mileageUnit)"),
                keyboardType: TextInputType.number,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    "On Date: ${_reminderDate == null ? 'Not Set' : DateFormat.yMMMd().format(_reminderDate!)}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_reminderDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _reminderDate = null),
                      ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _reminderDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _reminderDate = picked);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel")),
        ElevatedButton(onPressed: _onSave, child: const Text("Save")),
      ],
    );
  }
}
