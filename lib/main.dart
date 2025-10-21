import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'providers/theme_manager.dart';
import 'utils/constants.dart';
import 'widgets/auth_gate.dart';

// Make the supabase client globally available
final supabase = Supabase.instance.client;

Future<void> main() async {
  // Make main async
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase using environment variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, // Get URL from env
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // Get Key from env
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: const FuelTrackerApp(),
    ),
  );
}

class FuelTrackerApp extends StatelessWidget {
  const FuelTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'FuelGauge',
          themeMode: themeManager.themeMode,
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
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: kLightCardBackgroundColor,
              selectedItemColor: kAccentColor,
              unselectedItemColor: kSecondaryTextColor,
              elevation: 2,
            ),
          ),
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
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: kDarkCardBackgroundColor,
              hintStyle: TextStyle(color: kSecondaryTextColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: kDarkCardBackgroundColor,
              selectedItemColor: kAccentColor,
              unselectedItemColor: kSecondaryTextColor,
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}
