import 'package:flutter/material.dart';
import 'screens.dart';

const _accent = Color(0xFF00E5CC);
const _bg = Color(0xFF12121C);

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _index = 0;

  final _screens = const [
    LevelsScreen(),
    TeachersScreen(),
    TimetableScreen(),
    TeacherScheduleScreen(),
  ];

  final _labels = const ['Levels', 'Teachers', 'Timetable', 'My Schedule'];
  final _icons = const [
    Icons.school,
    Icons.person,
    Icons.grid_view,
    Icons.schedule,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.calendar_today, color: _accent, size: 20),
            const SizedBox(width: 10),
            Text(
              _labels[_index],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF1E1E2C),
        selectedItemColor: _accent,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: List.generate(
          _labels.length,
          (i) =>
              BottomNavigationBarItem(icon: Icon(_icons[i]), label: _labels[i]),
        ),
      ),
    );
  }
}
