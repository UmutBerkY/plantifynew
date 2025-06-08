import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vibration/vibration.dart';

class PlantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;
  const PlantDetailScreen({super.key, required this.plantData});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late DateTime nextWaterTime;
  late DateTime sunStartTime;
  late int waterIntervalDays;
  late int sunExposureHours;
  late String health;
  late String docId;

  Timer? _timer;
  Duration _remainingWater = Duration.zero;
  Duration _remainingSun = Duration.zero;

  @override
  void initState() {
    super.initState();
    docId = widget.plantData['id'] ?? '';
    nextWaterTime = (widget.plantData['nextWaterTime'] as Timestamp).toDate();
    waterIntervalDays = widget.plantData['waterIntervalDays'] ?? 3;
    sunExposureHours = widget.plantData['sunExposureHours'] ?? 6;
    sunStartTime = DateTime.now();

    _startTimer();
    final now = DateTime.now();
    health = now.isAfter(nextWaterTime) ? 'Kötü' : (widget.plantData['health'] ?? 'İyi');
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingWater = nextWaterTime.difference(DateTime.now());
        _remainingSun = sunStartTime.add(Duration(hours: sunExposureHours)).difference(DateTime.now());
      });
    });
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$hours sa $minutes dk $seconds sn';
  }

  Future<void> updateXP(int xpToAdd) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final currentXP = snapshot.data()?['xp'] ?? 0;

    await userRef.update({'xp': currentXP + xpToAdd});
  }

  Future<void> waterPlant() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || docId.isEmpty) return;

    final newTime = DateTime.now().add(Duration(days: waterIntervalDays));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('my_plants')
        .doc(docId)
        .update({
      'nextWaterTime': Timestamp.fromDate(newTime),
      'health': 'İyi',
    });

    await updateXP(10);

    setState(() {
      nextWaterTime = newTime;
      health = 'İyi';
    });

    // 🔔 Titreşim buraya taşındı
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bitki sulandı! +10 XP')),
    );
  }


  Future<void> giveSun() async {
    sunStartTime = DateTime.now();
    await updateXP(10);

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Güneşe bırakıldı! +10 XP')),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.plantData['name'];
    final image = widget.plantData['image'];
    final description = widget.plantData['description'];
    final isLate = _remainingWater.isNegative;

    return Scaffold(
      appBar: AppBar(
        title: Text(name ?? 'Bitki Detayı'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Image.asset('assets/images/$image', height: 180),
            const SizedBox(height: 16),
            Text(name ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('Sağlık Durumu: $health'),
            const SizedBox(height: 8),
            Text(
              isLate
                  ? '❗ Sulama süresi geçti!'
                  : 'Sulama için kalan süre: ${formatDuration(_remainingWater)}',
              style: TextStyle(
                color: isLate ? Colors.red : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Güneşlenme süresi: ${formatDuration(_remainingSun)}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: waterPlant,
              icon: const Icon(Icons.water_drop),
              label: const Text('Suladım'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: giveSun,
              icon: const Icon(Icons.wb_sunny),
              label: const Text('Güneşe Bıraktım'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                minimumSize: const Size.fromHeight(50),
              ),
            )
          ],
        ),
      ),
    );
  }
}
