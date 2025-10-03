import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_log.dart';
import '../models/maintenance_log.dart';
import '../utils/constants.dart';

// The main page widget that now holds the TabBar structure.
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We use an AppBar here to host the TabBar.
      appBar: AppBar(
        title: Text("Vehicle Records",
            style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        // The TabBar for switching views.
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
      // TabBarView contains the content for each tab.
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Content for the "Fuel" tab.
          _FuelHistoryTab(),
          // Content for the "Maintenance" tab.
          _MaintenanceHistoryTab(),
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
    if (mounted) {
      setState(() {
        _allLogs = stored.map((e) => FuelLog.fromJson(jsonDecode(e))).toList();
        _allLogs.sort(
            (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

        final uniqueVehicles =
            LinkedHashSet<String>.from(_allLogs.map((log) => log.vehicleId))
                .toList();
        _vehicleList = ['All Vehicles', ...uniqueVehicles];
        _selectedVehicle = prefs.getString('selectedVehicle') ?? 'All Vehicles';
        if (!_vehicleList.contains(_selectedVehicle)) {
          _selectedVehicle = 'All Vehicles';
        }

        _filterLogs();
      });
    }
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    _allLogs.sort((a, b) => a.mileage.compareTo(b.mileage));
    final encoded = _allLogs.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("fuel_logs", encoded);
    _loadLogs();
  }

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

  void _showEditDeleteDialog(FuelLog logToEdit) {
    // This is the same dialog as before, no changes needed here.
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
                _confirmDelete(logToEdit);
              },
              child: const Text("Delete",
                  style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () {
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
          _buildVehicleFilter(),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search by date, note, or vehicle...",
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
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

class _MaintenanceHistoryTab extends StatefulWidget {
  const _MaintenanceHistoryTab();

  @override
  State<_MaintenanceHistoryTab> createState() => __MaintenanceHistoryTabState();
}

class __MaintenanceHistoryTabState extends State<_MaintenanceHistoryTab> {
  List<MaintenanceLog> _maintenanceLogs = [];

  @override
  void initState() {
    super.initState();
    _loadMaintenanceLogs();
  }

  Future<void> _loadMaintenanceLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("maintenance_logs") ?? [];
    if (mounted) {
      setState(() {
        _maintenanceLogs =
            stored.map((e) => MaintenanceLog.fromJson(jsonDecode(e))).toList();
        _maintenanceLogs.sort(
            (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
      });
    }
  }

  Future<void> _saveMaintenanceLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        _maintenanceLogs.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("maintenance_logs", encoded);
    _loadMaintenanceLogs();
  }

  void _addOrEditLog({MaintenanceLog? log}) async {
    final result = await showDialog<MaintenanceLog>(
      context: context,
      builder: (context) => _AddMaintenanceDialog(log: log),
    );

    if (result != null) {
      setState(() {
        if (log == null) {
          _maintenanceLogs.add(result);
        } else {
          final index =
              _maintenanceLogs.indexWhere((item) => item.id == log.id);
          if (index != -1) {
            _maintenanceLogs[index] = result;
          }
        }
      });
      _saveMaintenanceLogs();
    }
  }

  void _confirmDelete(MaintenanceLog logToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text(
            "Are you sure you want to delete the '${logToDelete.serviceType}' record?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                _maintenanceLogs.removeWhere((log) => log.id == logToDelete.id);
              });
              _saveMaintenanceLogs();
              Navigator.of(context).pop();
            },
            child:
                const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _maintenanceLogs.isEmpty
          ? const Center(
              child: Text("No maintenance logs yet.\nTap '+' to add one.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kSecondaryTextColor)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _maintenanceLogs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = _maintenanceLogs[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.build_circle_outlined),
                    title: Text("${log.vehicleId}: ${log.serviceType}"),
                    subtitle: Text(
                        "On ${DateFormat.yMMMd().format(DateTime.parse(log.date))} at ${log.mileage} km"),
                    trailing: log.cost != null && log.cost! > 0
                        ? Text("₱${log.cost?.toStringAsFixed(2)}")
                        : null,
                    onTap: () => _addOrEditLog(log: log),
                    onLongPress: () => _confirmDelete(log),
                  ),
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

class _AddMaintenanceDialog extends StatefulWidget {
  final MaintenanceLog? log;
  const _AddMaintenanceDialog({this.log});

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

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    if (widget.log != null) {
      _serviceController.text = widget.log!.serviceType;
      _mileageController.text = widget.log!.mileage.toString();
      _costController.text = widget.log!.cost?.toString() ?? '';
      _notesController.text = widget.log!.notes ?? '';
      _selectedVehicle = widget.log!.vehicleId;
      _selectedDate = DateTime.parse(widget.log!.date);
      if (widget.log!.nextReminderMileage != null) {
        _reminderMileageController.text =
            widget.log!.nextReminderMileage.toString();
      }
      if (widget.log!.nextReminderDate != null) {
        _reminderDate = DateTime.parse(widget.log!.nextReminderDate!);
      }
    }
  }

  Future<void> _loadVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList("fuel_logs") ?? [];
    final allLogs = stored.map((e) => FuelLog.fromJson(jsonDecode(e))).toList();
    final uniqueVehicles =
        LinkedHashSet<String>.from(allLogs.map((log) => log.vehicleId))
            .toList();
    setState(() {
      _vehicleList = uniqueVehicles;
      if (widget.log == null && _vehicleList.isNotEmpty) {
        _selectedVehicle = _vehicleList.first;
      }
    });
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _mileageController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _reminderMileageController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final newLog = MaintenanceLog(
        id: widget.log?.id,
        vehicleId: _selectedVehicle!,
        serviceType: _serviceController.text.trim(),
        date: _selectedDate.toIso8601String(),
        mileage: double.parse(_mileageController.text),
        cost: double.tryParse(_costController.text),
        notes: _notesController.text.trim(),
        nextReminderMileage: double.tryParse(_reminderMileageController.text),
        nextReminderDate: _reminderDate?.toIso8601String(),
      );
      Navigator.of(context).pop(newLog);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(labelText: "Mileage (km)"),
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
                decoration: const InputDecoration(
                    labelText: "At Mileage (e.g., 60000)"),
                keyboardType: TextInputType.number,
              ),
              ListTile(
                title: Text(
                    "On Date: ${_reminderDate == null ? 'Not Set' : DateFormat.yMMMd().format(_reminderDate!)}"),
                trailing: const Icon(Icons.calendar_today),
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
