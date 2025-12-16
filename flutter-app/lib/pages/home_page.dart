import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Components/AllergyState.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ingredient Scanner")),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to the Ingredient Scanner!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "Easily scan product ingredients to check for allergens.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              context.watch<AllergyState>().selectedAllergies.isEmpty
                  ? "No allergies selected. \nClick selected allergies below to add."
                  : "You have selected ${context.watch<AllergyState>().selectedAllergies.length} allergies. \nClick Scan below to start scanning.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
