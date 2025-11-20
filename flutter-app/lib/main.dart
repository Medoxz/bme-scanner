import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/camera_ocr_page.dart';

void main() {
  runApp(const IngredientScannerApp());
}

class IngredientScannerApp extends StatelessWidget {
  const IngredientScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Ingredient Scanner",
      theme: ThemeData(primarySwatch: Colors.green),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [HomePage(), CameraOCRPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Results"),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Camera OCR",
          ),
        ],
      ),
    );
  }
}
