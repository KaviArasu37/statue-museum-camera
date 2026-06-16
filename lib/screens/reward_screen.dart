import 'dart:math';
import 'package:flutter/material.dart';

class RewardScreen extends StatefulWidget {
  final Map<String, dynamic> mission;
  final List<String> items;

  const RewardScreen({super.key, required this.mission, required this.items});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebController;
  late AnimationController _staggerController;
  late Animation<double> _celebAnim;
  final _rng = Random();
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _celebController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _celebAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _celebController, curve: Curves.elasticOut),
    );

    // Generate particles
    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle(rng: _rng));
    }
  }

  @override
  void dispose() {
    _celebController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.mission['color'] as int);
    final emoji = widget.mission['emoji'] as String;
    final title = widget.mission['title'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0515),
      body: Stack(
        children: [
          // Particle background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _staggerController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _staggerController.value,
                    color: color,
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Trophy
                ScaleTransition(
                  scale: _celebAnim,
                  child: const Text('🏆', style: TextStyle(fontSize: 72)),
                ),
                const SizedBox(height: 16),

                // Title
                ScaleTransition(
                  scale: _celebAnim,
                  child: Text(
                    'Mission Complete!',
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),

                // Curator verdict
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1040),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('🎩', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      const Text(
                        '"I am writing a letter to the Queen about this collection."',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '— Curator Barnabas',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Collected items grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Your Collection',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: widget.items.map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            item,
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),

                const Spacer(),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'New Mission!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;

  _Particle({required Random rng})
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = 4 + rng.nextDouble() * 8,
        speed = 0.3 + rng.nextDouble() * 0.7,
        color = [
          const Color(0xFFFFD840),
          const Color(0xFF7F77DD),
          const Color(0xFF5DCAA5),
          const Color(0xFFE24B4A),
          Colors.white,
        ][rng.nextInt(5)];
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = p.y - progress * p.speed * 1.5;
      if (dy < -0.1 || dy > 1.1) continue;
      final paint = Paint()
        ..color = p.color.withOpacity((1 - progress) * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, dy * size.height),
        p.size * (1 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
