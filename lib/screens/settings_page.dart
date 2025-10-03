import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // State variables for local settings
  bool _isMiles = false;
  double _efficiencyThreshold = 9.0;
  final _thresholdController = TextEditingController();

  // State variable for the current user
  final _currentUser = FirebaseAuth.instance.currentUser;

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

  // Method to log the user out
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // The AuthGate widget will automatically navigate back to the LoginPage
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
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
            'Are you sure you want to delete all your local fuel logs? This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
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
      await prefs.remove("selectedVehicle");
      await prefs.remove("maintenance_logs");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text("All local data has been reset.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkTheme = themeManager.themeMode == ThemeMode.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 24),

            // --- Profile Section ---
            const Text("PROFILE"),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Logged In As"),
                subtitle: Text(_currentUser?.email ?? "Not available"),
              ),
            ),
            const SizedBox(height: 24),

            // --- General Settings ---
            const Text("GENERAL"),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Dark Theme"),
                    value: isDarkTheme,
                    onChanged: (value) => themeManager.toggleTheme(value),
                    secondary:
                        Icon(isDarkTheme ? Icons.dark_mode : Icons.light_mode),
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
                subtitle: Text(
                    "Recommendation appears below ${_efficiencyThreshold.toStringAsFixed(1)} km/L"),
                trailing: const Icon(Icons.edit),
                onTap: _showThresholdDialog,
              ),
            ),
            const SizedBox(height: 24),

            // --- DATA & ACCOUNT ---
            const Text("DATA & ACCOUNT"),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.delete_forever,
                        color: Colors.orange.shade700),
                    title: Text("Reset Local Data",
                        style: TextStyle(color: Colors.orange.shade700)),
                    onTap: () => _resetData(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text("Log Out",
                        style: TextStyle(color: Colors.redAccent)),
                    onTap: _logout,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
