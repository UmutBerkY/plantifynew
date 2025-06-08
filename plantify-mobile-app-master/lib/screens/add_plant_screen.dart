import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPlantScreen extends StatelessWidget {
  const AddPlantScreen({super.key});

  Future<void> addPlantToMyPlants(Map<String, dynamic> plant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userPlantRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('my_plants')
        .doc(plant['name']);

    final int waterInterval = plant['waterIntervalDays'] ?? 3;
    final int sunHours = plant['sunExposureHours'] ?? 6;

    await userPlantRef.set({
      'name': plant['name'],
      'description': plant['description'],
      'image': plant['image'],
      'health': 'İyi',
      'addedAt': Timestamp.now(),
      'waterIntervalDays': waterInterval,
      'sunExposureHours': sunHours,
      'nextWaterTime': Timestamp.fromDate(DateTime.now().add(Duration(days: waterInterval))),
      'nextSunTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: sunHours))),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bitki Ekle'), backgroundColor: Colors.green),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('plant_templates').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Şu anda hiç sabit bitki tanımlı değil.'));
          }

          final plants = snapshot.data!.docs;

          return ListView.builder(
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index].data() as Map<String, dynamic>;
              final waterInterval = plant['waterIntervalDays'] ?? 3;
              final sunHours = plant['sunExposureHours'] ?? 6;

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/${plant['image']}', height: 150),
                      const SizedBox(height: 8),
                      Text(
                        plant['name'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(plant['description'] ?? ''),
                      const SizedBox(height: 8),
                      Text('💧 Sulama Aralığı: $waterInterval gün'),
                      Text('☀️ Güneşlenme Süresi: $sunHours saat'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await addPlantToMyPlants(plant);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${plant['name']} eklendi!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Bitkiyi Ekle'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
