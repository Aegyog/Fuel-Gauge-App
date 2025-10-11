import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_page.dart';
import '../screens/main_navigation.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.session == null) {
          // User is not signed in
          return const LoginPage();
        }
        // User is signed in
        return const MainNavigation();
      },
    );
  }
}
