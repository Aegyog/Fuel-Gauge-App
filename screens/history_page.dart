import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_log.dart';
import '../utils/constants.dart';

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
      _allLogs.sort(
          (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
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
    final mileageController =
        TextEditingController(text: logToEdit.mileage.toString());
    final litersController =
        TextEditingController(text: logToEdit.liters.toString());
    final priceController =
        TextEditingController(text: logToEdit.pricePerLiter.toString());
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
                Navigator.of(context).pop(); // Close edit dialog
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
                      child: Text("No logs found.",
                          style: TextStyle(color: kSecondaryTextColor)))
                  : ListView.separated(
                      itemCount: _filteredLogs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final log = _filteredLogs[i];
                        return Card(
                          child: ListTile(
                            onTap: () => _showEditDeleteDialog(log),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            leading:
                                const Icon(Icons.local_gas_station, size: 30),
                            title: Text(
                              "₱${log.cost.toStringAsFixed(2)} for ${log.liters} L",
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
      ),
    );
  }
}
