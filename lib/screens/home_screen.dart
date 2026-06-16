import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({super.key, required this.cameras});

  static const missions = [
    {
      'title': 'Snap 5 Flowers',
      'emoji': '🌸',
      'target': 'flower',
      'count': 5,
      'color': 0xFFE24B8A,
      'bg': 0xFF2A0F1A,
      'desc': 'Find flowers around you!',
    },
    {
      'title': 'Find 5 Animals',
      'emoji': '🐾',
      'target': 'animal',
      'count': 5,
      'color': 0xFF1D9E75,
      'bg': 0xFF0A1F18,
      'desc': 'Spot animals near you!',
    },
    {
      'title': 'Collect 5 Toys',
      'emoji': '🧸',
      'target': 'toy',
      'count': 5,
      'color': 0xFFFFD840,
      'bg': 0xFF1A1500,
      'desc': 'Find your toys!',
    },
    {
      'title': 'Find 5 Devices',
      'emoji': '📱',
      'target': 'device',
      'count': 5,
      'color': 0xFF7F77DD,
      'bg': 0xFF0F0A2A,
      'desc': 'Find gadgets at home!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0515),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Curator
            const Text('🎩', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text(
              'CURATOR BARNABAS',
              style: TextStyle(
                color: Color(0x664B3F8A),
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose your mission!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Snap items to collect them for the museum',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.9,
                ),
                itemCount: missions.length,
                itemBuilder: (context, i) {
                  final m = missions[i];
                  return _MissionCard(
                    mission: m,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraScreen(
                          cameras: cameras,
                          mission: m,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Map<String, dynamic> mission;
  final VoidCallback onTap;

  const _MissionCard({required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(mission['color'] as int);
    final bg = Color(mission['bg'] as int);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mission['emoji'] as String,
                style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(
              mission['title'] as String,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              mission['desc'] as String,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
