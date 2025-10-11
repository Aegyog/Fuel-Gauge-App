import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // To get the global supabase client
import '../providers/theme_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // State variables for local settings
  bool _isMiles = false;
  double? _efficiencyThreshold;
  final _thresholdController = TextEditingController();

  // MODIFIED: State variable for the current Supabase user
  final _currentUser = supabase.auth.currentUser;

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

  // MODIFIED: Method to log the user out using Supabase
  Future<void> _logout() async {
    await supabase.auth.signOut();
    // The AuthGate widget will automatically navigate back to the LoginPage
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isMiles = prefs.getBool('isMiles') ?? false;
        _efficiencyThreshold = prefs.getDouble('efficiencyThreshold');
      });
    }
  }

  Future<void> _setUnit(bool isMiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMiles', isMiles);
    setState(() => _isMiles = isMiles);
  }

  Future<void> _setEfficiencyThreshold(double? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('efficiencyThreshold');
    } else {
      await prefs.setDouble('efficiencyThreshold', value);
    }
    setState(() => _efficiencyThreshold = value);
  }

  void _showThresholdDialog() {
    final isMiles = _isMiles;
    final unit = isMiles ? 'MPG' : 'km/L';

    if (_efficiencyThreshold != null) {
      final currentDisplayValue =
          isMiles ? (_efficiencyThreshold! * 2.35215) : _efficiencyThreshold;
      _thresholdController.text = currentDisplayValue!.toStringAsFixed(1);
    } else {
      _thresholdController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Custom Efficiency Goal"),
        content: TextField(
          controller: _thresholdController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "Efficiency ($unit)"),
        ),
        actions: [
          TextButton(
              onPressed: () {
                _setEfficiencyThreshold(null);
                Navigator.pop(context);
              },
              child: const Text("Clear Goal")),
          ElevatedButton(
            onPressed: () {
              final newValue = double.tryParse(_thresholdController.text);
              if (newValue != null && newValue > 0) {
                if (isMiles) {
                  final kmLValue = newValue / 2.35215;
                  _setEfficiencyThreshold(kmLValue);
                } else {
                  _setEfficiencyThreshold(newValue);
                }
              } else {
                _setEfficiencyThreshold(null);
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
    if (!mounted) return;
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
    if (confirmed == true && mounted) {
      // NOTE: This only resets local data. We will need to update this to delete from Supabase.
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

    String subtitleText;
    if (_efficiencyThreshold == null) {
      subtitleText =
          "Not set. No fuel efficiency recommendations will be shown.";
    } else {
      if (_isMiles) {
        final mpgThreshold = _efficiencyThreshold! * 2.35215;
        subtitleText =
            "Recommendation appears below ${mpgThreshold.toStringAsFixed(1)} MPG";
      } else {
        subtitleText =
            "Recommendation appears below ${_efficiencyThreshold!.toStringAsFixed(1)} km/L";
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings", style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 24),
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
                    title: const Text("Display units in Miles (MPG)"),
                    subtitle:
                        const Text("Default is Kilometers per Liter (km/L)"),
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
                subtitle: Text(subtitleText),
                trailing: const Icon(Icons.edit),
                onTap: _showThresholdDialog,
              ),
            ),
            const SizedBox(height: 24),
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
