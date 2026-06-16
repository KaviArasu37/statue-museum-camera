import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'reward_screen.dart';

// Mission keyword mapping — ML Kit returns real English labels
// We check if the detected label contains any of these keywords
const _missionKeywords = {
  'flower': [
    'flower','rose','daisy','tulip','sunflower','lily','petal','blossom',
    'plant','garden','jasmine','marigold','bouquet','floral','bloom'
  ],
  'animal': [
    'cat','dog','bird','rabbit','fish','animal','pet','wildlife',
    'butterfly','insect','mammal','puppy','kitten','parrot','squirrel'
  ],
  'toy': [
    'toy','teddy','bear','doll','ball','block','lego','puzzle','game',
    'stuffed','plush','figurine','action figure','model','plaything'
  ],
  'device': [
    'phone','mobile','tablet','laptop','computer','remote','television',
    'tv','speaker','headphone','earphone','cable','electronic','device',
    'keyboard','mouse','charger','wire','gadget','screen','monitor'
  ],
};

// Friendly child-facing label for matched items
const _friendlyLabels = {
  'flower': ['Pretty Flower!', 'Beautiful Bloom!', 'Garden Flower!', 'Lovely Petal!'],
  'animal': ['Cute Animal!', 'Friendly Pet!', 'Amazing Creature!', 'Wild Friend!'],
  'toy': ['Fun Toy!', 'Playful Friend!', 'Cool Toy!', 'Amazing Plaything!'],
  'device': ['Cool Device!', 'Smart Gadget!', 'Tech Thing!', 'Electric Device!'],
};

const _curatorReactions = [
  'Magnificent! 📸',
  'The museum needs this!',
  'Forty years of curating...',
  'I am writing to the Queen!',
  'Simply remarkable! 🎩',
  'Best one yet! 🤌',
  'I cannot cope! 🧃',
  'I need to sit down. 🤯',
];

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Map<String, dynamic> mission;

  const CameraScreen({super.key, required this.cameras, required this.mission});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  ImageLabeler? _labeler;
  bool _isInitialized = false;
  bool _permissionDenied = false;
  bool _isCapturing = false;
  bool _showFlash = false;
  bool _showResult = false;
  bool _wrongItem = false;

  String _detectedLabel = '';
  String _curatorText = '';
  String _rawDetected = '';
  int _collected = 0;
  final List<String> _collectedItems = [];
  final _rng = Random();

  late AnimationController _pulseController;
  late AnimationController _resultController;
  late Animation<double> _pulseAnim;
  late Animation<double> _resultAnim;

  @override
  void initState() {
    super.initState();

    // Init ML Kit labeler
    final options = ImageLabelerOptions(confidenceThreshold: 0.55);
    _labeler = ImageLabeler(options: options);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _resultAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );

    _requestPermissionAndInit();
  }

  Future<void> _requestPermissionAndInit() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await _initCamera();
    } else {
      setState(() {
        _permissionDenied = true;
        _isInitialized = true;
      });
    }
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() => _isInitialized = true);
      return;
    }
    try {
      _controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  // Check if any ML Kit label matches mission keywords
  String? _matchMission(List<ImageLabel> labels, String target) {
    final keywords = _missionKeywords[target] ?? [];
    for (final label in labels) {
      final text = label.label.toLowerCase();
      for (final kw in keywords) {
        if (text.contains(kw)) return label.label;
      }
    }
    return null;
  }

  Future<void> _captureAndIdentify() async {
    if (_isCapturing || _showResult) return;
    setState(() { _isCapturing = true; _wrongItem = false; });

    // Flash
    setState(() => _showFlash = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _showFlash = false);

    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        setState(() => _isCapturing = false);
        return;
      }

      // Take picture
      final XFile photo = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);

      // Run ML Kit
      final labels = await _labeler!.processImage(inputImage);

      if (!mounted) return;

      final target = widget.mission['target'] as String;
      final matched = _matchMission(labels, target);

      // Get top detected label for display
      final topRaw = labels.isNotEmpty ? labels.first.label : 'Unknown';

      if (matched != null) {
        // Correct item found!
        final friendlyList = _friendlyLabels[target] ?? ['Found it!'];
        final friendlyLabel = friendlyList[_rng.nextInt(friendlyList.length)];
        final reaction = _curatorReactions[_rng.nextInt(_curatorReactions.length)];

        setState(() {
          _detectedLabel = friendlyLabel;
          _rawDetected = matched;
          _curatorText = reaction;
          _collected++;
          _collectedItems.add(matched);
          _showResult = true;
          _wrongItem = false;
          _isCapturing = false;
        });

        _resultController.forward(from: 0);

        await Future.delayed(const Duration(milliseconds: 2200));
        if (!mounted) return;

        final total = widget.mission['count'] as int;
        if (_collected >= total) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RewardScreen(
                mission: widget.mission,
                items: _collectedItems,
              ),
            ),
          );
        } else {
          setState(() => _showResult = false);
          _resultController.reverse();
        }
      } else {
        // Wrong item — show what was detected
        setState(() {
          _wrongItem = true;
          _rawDetected = topRaw;
          _isCapturing = false;
          _showResult = true;
        });
        _resultController.forward(from: 0);

        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) {
          setState(() { _showResult = false; _wrongItem = false; });
          _resultController.reverse();
        }
      }
    } catch (e) {
      debugPrint('Identify error: $e');
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _labeler?.close();
    _pulseController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.mission['color'] as int);
    final total = widget.mission['count'] as int;
    final emoji = widget.mission['emoji'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0515),
      body: Stack(
        children: [
          // Camera
          Positioned.fill(child: _buildCameraView(color)),

          // Top gradient
          Positioned(
            top: 0, left: 0, right: 0, height: 180,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xDD0A0515), Colors.transparent],
                ),
              ),
            ),
          ),

          // Bottom gradient
          Positioned(
            bottom: 0, left: 0, right: 0, height: 260,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xEE0A0515), Colors.transparent],
                ),
              ),
            ),
          ),

          // Flash
          if (_showFlash)
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.9)),
            ),

          // Top HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(total, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 11, height: 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _collected ? color : Colors.white.withOpacity(0.2),
                        boxShadow: i < _collected
                            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                            : null,
                      ),
                    )),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text('$_collected / $total',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),

          // Curator hint
          Positioned(
            top: 72, left: 0, right: 0,
            child: Column(children: [
              const Text('🎩', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xCC1E1040),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _collected == 0
                      ? 'Point at ${widget.mission['target']} & tap! $emoji'
                      : '$_collected collected! Keep going! $emoji',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ]),
          ),

          // Viewfinder ring
          if (!_permissionDenied)
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.7), width: 2.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Result card
          if (_showResult)
            Center(
              child: ScaleTransition(
                scale: _resultAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 36),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xF21E1040),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _wrongItem ? Colors.red.withOpacity(0.5) : color.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: _wrongItem
                      ? Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🔍', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 10),
                          const Text('Not a match!',
                              style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('I see: $_rawDetected',
                              style: const TextStyle(color: Colors.white54, fontSize: 13)),
                          const SizedBox(height: 10),
                          Text(
                            'Try pointing at a ${widget.mission['target']}!',
                            style: TextStyle(color: color, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ])
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(emoji, style: const TextStyle(fontSize: 52)),
                          const SizedBox(height: 10),
                          Text(_detectedLabel,
                              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('($_rawDetected)',
                              style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 6),
                          Text('Added to the museum!',
                              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('"$_curatorText"',
                                style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 10),
                          Text('${total - _collected} more to go!',
                              style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
                        ]),
                ),
              ),
            ),

          // Capture button
          Positioned(
            bottom: 50, left: 0, right: 0,
            child: Column(children: [
              Text(widget.mission['title'] as String,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: (_isCapturing || _showResult) ? null : _captureAndIdentify,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 82, height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_isCapturing || _showResult) ? color.withOpacity(0.4) : color,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.45), blurRadius: 24, spreadRadius: 4)],
                  ),
                  child: Center(
                    child: _isCapturing
                        ? const SizedBox(width: 28, height: 28,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : Icon(_showResult ? Icons.check : Icons.camera_alt,
                            color: Colors.white, size: 36),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView(Color color) {
    if (!_isInitialized) {
      return Container(
        color: const Color(0xFF12082A),
        child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Color(0xFF7F77DD)),
          SizedBox(height: 20),
          Text('Starting camera...', style: TextStyle(color: Colors.white54, fontSize: 15)),
        ])),
      );
    }
    if (_permissionDenied) {
      return Container(
        color: const Color(0xFF12082A),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📷', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Camera permission needed',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Please allow camera access\nin your phone settings',
              style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ])),
      );
    }
    if (_controller != null && _controller!.value.isInitialized) {
      return CameraPreview(_controller!);
    }
    return Container(color: const Color(0xFF12082A));
  }
}
