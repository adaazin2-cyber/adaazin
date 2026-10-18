import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';

// ==================== IMPORT HALAMAN ====================
import 'home_page.dart';
import 'custom_bug.dart';
import 'bug_group.dart';

// ==================== WARNA PREMIUM ====================
class BugMenuColors {
  static const Color primary = Color(0xFF00E5FF); // Cyan Neon
  static const Color secondary = Color(0xFF7C4DFF); // Purple
  static const Color accent = Color(0xFFFF3366); // Pink/Red
  static const Color darkBg = Color(0xFF0A0E27);
  static const Color darkerBg = Color(0xFF000000);
  static const Color cardBg = Color(0xFF141414);
  static const Color text = Colors.white;
  static const Color textSecondary = Color(0xFFADB5BD);
}

class BugMenuPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String role;
  final String expiredDate;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;

  const BugMenuPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listPayload,
  });

  @override
  State<BugMenuPage> createState() => _BugMenuPageState();
}

class _BugMenuPageState extends State<BugMenuPage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  int _selectedIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  // Menu items
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'XEXTRO BUG',
      'subtitle': 'ENTRY-LEVEL',
      'icon': FontAwesomeIcons.bug,
      'color1': BugMenuColors.primary,
      'color2': BugMenuColors.secondary,
      'features': [
        'BUGS MENU GACOR',
        'SENDER PRIVATE',
        '100% WORK',
      ],
      'type': 'home',
    },
    {
      'title': 'CUSTOM BUG',
      'subtitle': 'GACOR EDITION',
      'icon': FontAwesomeIcons.wrench,
      'color1': BugMenuColors.secondary,
      'color2': BugMenuColors.accent,
      'features': [
        'BUG GACOR',
        'BUG BANYAK',
        'BEBAS COSTUM DELAY',
        'BEBAS COSTUM QUALITY',
        'SENDER PRIVATE',
        'SENDER GLOBAL',
      ],
      'type': 'custom',
    },
    {
      'title': 'BUG GROUP',
      'subtitle': 'XORA EDITION',
      'icon': FontAwesomeIcons.users,
      'color1': BugMenuColors.accent,
      'color2': BugMenuColors.primary,
      'features': [
        'LINK GROUP WA',
        'BUG CRASH',
        'SENDER PRIVATE',
        'BUG RUB',
      ],
      'type': 'group',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/menu.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoInitialized = true;
            });
            _videoController.setLooping(true);
            _videoController.play();
            _videoController.setVolume(0);
          }
        }).catchError((error) {
          print('Video initialization error: $error');
          if (mounted) {
            setState(() {
              _videoError = true;
            });
          }
        });
    } catch (e) {
      print('Video controller creation error: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  void _navigateTo(String type) {
    if (type == 'home') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AttackPage(
            username: widget.username,
            password: widget.password,
            sessionKey: widget.sessionKey,
            listBug: widget.listBug,
            role: widget.role,
            expiredDate: widget.expiredDate,
          ),
        ),
      );
    } else if (type == 'custom') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomAttackPage(
            username: widget.username,
            password: widget.password,
            sessionKey: widget.sessionKey,
            listPayload: widget.listPayload,
            role: widget.role,
            expiredDate: widget.expiredDate,
          ),
        ),
      );
    } else if (type == 'group') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupBugPage(
            username: widget.username,
            password: widget.password,
            sessionKey: widget.sessionKey,
            role: widget.role,
            expiredDate: widget.expiredDate,
          ),
        ),
      );
    }
  }

  // ==================== BACKGROUND ====================
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BugMenuColors.darkBg, BugMenuColors.darkerBg],
        ),
      ),
      child: Stack(
        children: [
          // Video Background
          if (_videoInitialized && !_videoError)
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
            Container(color: BugMenuColors.darkerBg),

          // Overlay gelap agar teks terbaca
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // Grid lines
          CustomPaint(
            painter: GridPainter(),
            size: Size.infinite,
          ),

          // Glowing orbs
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BugMenuColors.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BugMenuColors.secondary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BugMenuColors.accent.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BugMenuColors.darkerBg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                // ===== HEADER =====
                _buildHeader(),
                const SizedBox(height: 10),

                // ===== SUBTITLE =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Geser untuk melihat kartu bug terbaru dan pilih XEXTRO BUG untuk kembali ke tampilan home.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontFamily: 'ShareTechMono',
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // ===== CAROUSEL MENU =====
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _menuItems.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      return _buildMenuCard(item, index);
                    },
                  ),
                ),

                // ===== INDICATOR =====
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _menuItems.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _currentPage == index
                            ? BugMenuColors.primary
                            : Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ===== NAVIGATION BUTTONS =====
                _buildNavigationButtons(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BugMenuColors.primary.withOpacity(0.15),
            BugMenuColors.secondary.withOpacity(0.05),
            Colors.black.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BugMenuColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [BugMenuColors.primary, BugMenuColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FontAwesomeIcons.bug,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "XEXTRO BUG NAV",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    "v1.0 • Premium Edition",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BugMenuColors.primary, BugMenuColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.role.toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MENU CARD ====================
  Widget _buildMenuCard(Map<String, dynamic> item, int index) {
    final isActive = _currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            item['color1'] as Color,
            item['color2'] as Color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (item['color1'] as Color).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background icon
          Positioned(
            right: -30,
            bottom: -20,
            child: Icon(
              item['icon'] as IconData,
              size: 120,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['subtitle'] as String,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Features
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: (item['features'] as List<String>).map((feature) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.checkCircle,
                              color: Colors.white.withOpacity(0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              feature,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateTo(item['type'] as String),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      item['type'] == 'home' 
                          ? 'XEXTRO BUG →' 
                          : item['type'] == 'custom' 
                          ? 'BUG GACOR →' 
                          : 'KIRIM BUG GROUP →',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NAVIGATION BUTTONS ====================
  Widget _buildNavigationButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BugMenuColors.primary.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          _buildNavButton(
            icon: FontAwesomeIcons.home,
            label: "Home",
            index: 0,
          ),
          _buildNavButton(
            icon: FontAwesomeIcons.wrench,
            label: "Custom",
            index: 1,
          ),
          _buildNavButton(
            icon: FontAwesomeIcons.users,
            label: "Group",
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentPage == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [BugMenuColors.primary, BugMenuColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : Colors.white.withOpacity(0.5),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

// ==================== GRID PAINTER ====================
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}