import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
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

  Future<void> _logout() async {
    await supabase.auth.signOut();
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

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Password"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: "Current Password"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: "New Password"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password.';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: "Confirm New Password"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your new password.';
                      }
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final email = _currentUser?.email;
                  if (email == null) return;

                  try {
                    // Step 1: Verify current password by attempting to sign in.
                    await supabase.auth.signInWithPassword(
                      email: email,
                      password: currentPasswordController.text,
                    );

                    // Step 2: If sign-in is successful, update to the new password.
                    await supabase.auth.updateUser(UserAttributes(
                      password: newPasswordController.text,
                    ));

                    if (!mounted) return;
                    Navigator.of(context).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text("Password updated successfully!")),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.of(context).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text("Error: Incorrect current password.")),
                    );
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetData() async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text(
            'Are you sure you want to delete all your fuel and maintenance logs? This action cannot be undone.'),
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
    if (confirmed == true) {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('fuel_logs').delete().eq('user_id', userId);
      await supabase.from('maintenance_logs').delete().eq('user_id', userId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // This will also clear theme and unit settings

      if (!mounted) return;
      _loadSettings(); // Reload to reset UI state

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.green,
            content: Text("All account data has been reset.")),
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
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text("Logged In As"),
                    subtitle: Text(_currentUser?.email ?? "Not available"),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text("Change Password"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                ],
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
                    title: const Text("Display units in Miles"),
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
                    title: Text("Reset Data",
                        style: TextStyle(color: Colors.orange.shade700)),
                    onTap: _resetData,
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
