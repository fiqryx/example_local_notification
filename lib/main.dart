import 'package:flutter/material.dart';
import 'package:example_local_notification/advanced_scheduler.dart';
import 'package:example_local_notification/basic_notification.dart'; // Fixed typo in filename

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example Local Notifications',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(), // Renamed for clarity (Main → MainScreen)
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Basic'),
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Advanced'),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [BasicNotification(), AdvanceScheduler()],
      ),
    );
  }
}
