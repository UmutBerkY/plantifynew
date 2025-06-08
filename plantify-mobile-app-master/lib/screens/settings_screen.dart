import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            title: Text("Email: umutb940@gmail.com"),
          ),
          const ListTile(
            title: Text("Email: iztefedmrc@gmail.com"),
          ),
          const ListTile(
            title: Text("App Version: 1.0.0"),
          ),
          const Divider(),
          const ListTile(
            title: Text("Hakkımızda"),
            subtitle: Text("Bitki Bakımı Uygulaması - Kastamonu"),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(41.3887, 33.7827), // Kastamonu Merkez koordinatları
                zoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(41.3887, 33.7827),
                      width: 150,
                      height: 80,
                      child: Column(
                        children: const [
                          Text(
                            'Kastamonu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              backgroundColor: Colors.white,
                              color: Colors.black,
                            ),
                          ),
                          Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
