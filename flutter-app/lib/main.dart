import 'package:bme_scanner/pages/allergies_select.dart';
import 'package:bme_scanner/pages/camera_ocr_page.dart';
import 'package:bme_scanner/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/Components/AllergyState.dart';
import 'pages/Components/ScanHistoryState.dart';
import 'pages/home_page.dart';

Future<bool> _hasCompletedOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AllergyState()),
        ChangeNotifierProvider(create: (_) => ScanHistoryState()),
      ],
      child: const IngredientScannerApp(),
    ),
  );
}

class IngredientScannerApp extends StatelessWidget {
  const IngredientScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Ingredient Scanner",
      theme: ThemeData(primarySwatch: Colors.green),
      home: const _HomeDecider(),
    );
  }
}

class _HomeDecider extends StatelessWidget {
  const _HomeDecider();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasCompletedOnboarding(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data ?? false) {
          return const MainNavigation();
        } else {
          return const OnboardingPage();
        }
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1;

  final List<Widget> _screens = const [
    AllergiesSelectPage(),
    HomePage(),
    CameraOCRPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 0) {
            Provider.of<AllergyState>(context, listen: false).tryServerUpdate();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Allergieën",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.house_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_rounded),
            label: "Scan",
          ),
        ],
      ),
    );
  }
}
