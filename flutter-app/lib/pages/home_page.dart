import 'package:bme_scanner/pages/Components/allergy_listing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Components/AllergyState.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ingrediënten Scanner")),

      body: Padding(
        padding: const EdgeInsets.all(16), 
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welkom bij de \nIngrediënten Scanner",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "Scan makkelijk product Ingrediënten om op allergenen te checken.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                context.watch<AllergyState>().selectedAllergies.isEmpty
                    ? "Geen allergieën geselecteerd. \nKlik hieronder op allergieën om ze toe te voegen."
                    : (context.watch<AllergyState>().selectedAllergies.length == 1) 
                      ? "Je hebt 1 allergie geselecteerd. \nKlik op Scan hieronder om te beginnen met scannen."
                      :"Je hebt ${context.watch<AllergyState>().selectedAllergies.length} allergieën geselecteerd. \nKlik op Scan onderaan om te beginnen met scannen.",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: context.watch<AllergyState>().selectedAllergies.length,
                  itemBuilder: (context, index) {
                    final name = context.watch<AllergyState>().selectedAllergies.toList()[index];
                    final item = context.watch<AllergyState>().allergies.firstWhere(
                      (allergy) => allergy["stof"] == name,
                      orElse: () => {"stof": name, "synoniemen": []},
                    );

                    return AllergyListingWidget(
                      item: item,
                      isSelected: false,
                      onChanged: (isSelected) {},
                      selectable: false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
