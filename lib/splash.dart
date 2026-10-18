import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

// Import DashboardPage dari loader_page.dart
import 'loader_page.dart';

class SplashPage extends StatefulWidget {
  // Menerima data user dari rute (arguments)
  final Map<String, dynamic> data;

  const SplashPage({super.key, required this.data});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  
  // Animasi logo membesar
  late AnimationController _logoScaleController;
  late Animation<double> _logoScaleAnimation;
  
  // Animasi cincin cahaya berputar di sekitar logo
  late AnimationController _ringController;
  late Animation<double> _ringRotationAnimation;
  
  // Animasi loading bar & persentase
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
    
    // Sembunyikan status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Mulai animasi dan timer 10 detik
    _startAnimations();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset("assets/videos/intro.mp4")
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.setLooping(true);
        _videoController.setVolume(0); // Mute
        _videoController.play();
      });
  }

  void _initializeAnimations() {
    // Animasi logo: kecil (0.5) ke besar (1.0) dalam 10 detik
    _logoScaleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoScaleController, curve: Curves.easeOutCubic),
    );

    // Animasi cincin berputar 360 derajat terus menerus
    _ringController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(); // Loop tanpa henti

    _ringRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );

    // Animasi loading bar 0 -> 1 dalam 10 detik
    _loadingController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _logoScaleController.forward();
    _loadingController.forward();

    // Timer 10 detik untuk pindah halaman
    _navigationTimer = Timer(const Duration(seconds: 10), () {
      _navigateToDashboard();
    });
  }

  void _navigateToDashboard() {
    _videoController.pause();
    _logoScaleController.stop();
    _ringController.stop();
    _loadingController.stop();
    _navigationTimer?.cancel();

    // Kembalikan UI Mode ke normal
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            username: widget.data['username'] ?? '',
            password: widget.data['password'] ?? '',
            role: widget.data['role'] ?? 'user',
            expiredDate: widget.data['expiredDate'] ?? '-',
            sessionKey: widget.data['key'] ?? '', 
            listBug: List<Map<String, dynamic>>.from(widget.data['listBug'] ?? []),
            listPayload: List<Map<String, dynamic>>.from(widget.data['listPayload'] ?? []),
            listDDoS: List<Map<String, dynamic>>.from(widget.data['listDDoS'] ?? []),
            news: List<Map<String, dynamic>>.from(widget.data['news'] ?? []),
          ),
        ), 
      );
    }
  }

  // Fungsi helper untuk mendapatkan persentase loading
  String _getPercentage(double value) {
    // Tahapan: 1% -> 30% -> 50% -> 80% -> 100%
    if (value < 0.30) return "${(value / 0.30 * 1).toInt()}%";
    if (value < 0.50) return "30%";
    if (value < 0.80) return "50%";
    if (value < 1.0) return "80%";
    return "100%";
  }

  @override
  void dispose() {
    _videoController.dispose();
    _logoScaleController.dispose();
    _ringController.dispose();
    _loadingController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. VIDEO BACKGROUND (Full Screen)
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(color: const Color(0xFF0A0A0F)),

          // 2. OVERLAY GELAP (Agar teks terbaca)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // 3. BACKGROUND GRID (efek garis halus seperti di foto)
          _buildBackgroundGrid(),

          // 4. KONTEN UTAMA (Logo, Text, Loading)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ANIMASI LOGO + CINCIN CAHAYA
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cincin cahaya berputar di belakang logo
                    AnimatedBuilder(
                      animation: _ringRotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _ringRotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE0E0E0).withOpacity(0.05),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Logo dengan animasi scale (kecil -> besar)
                    ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/splash.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // TEXT "XEXTRO"
                const Text(
                  "XEXTRO",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4.0,
                    shadows: [
                      Shadow(
                        blurRadius: 20.0,
                        color: Colors.white24,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // TEXT "Powered by @RULZIZY" dalam chip rounded
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Text(
                    "Powered by @RULZIZY",
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 11,
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 80),

                // LOADING BAR + PERSENTASE
                AnimatedBuilder(
                  animation: _loadingAnimation,
                  builder: (context, child) {
                    final progress = _loadingAnimation.value;
                    final percentage = _getPercentage(progress);
                    
                    return Column(
                      children: [
                        // Dua titik kecil di atas bar (seperti foto)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Progress bar custom
                        Container(
                          width: 250,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Teks persentase + status
                        Text(
                          "$percentage   Initializing...",
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // 5. SKIP BUTTON
          Positioned(
            top: 50,
            right: 25,
            child: GestureDetector(
              onTap: _navigateToDashboard,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "SKIP",
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk membuat background grid halus seperti di foto
  Widget _buildBackgroundGrid() {
    return CustomPaint(
      painter: GridPainter(),
    );
  }
}

// Custom Painter untuk grid background (garis tipis)
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;

    // Garis vertikal
    const double spacing = 40.0;
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Garis horizontal
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}