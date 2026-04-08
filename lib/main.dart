import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state.dart';
import 'home.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teacher Scheduler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12121C),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E5CC),
          surface: const Color(0xFF1E1E2C),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          labelLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const Home(),
    );
  }
}
