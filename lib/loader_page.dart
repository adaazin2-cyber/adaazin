// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'dart:io';

// ==================== IMPORT BASEURL ====================
import '../server/domain_server.dart' show baseUrl;

// ==================== IMPORTS HALAMAN ====================
import 'telegram.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'ddos_page.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'custom_bug.dart';
import 'bug_group.dart';
import 'ddos_panel.dart';
import 'sender_page.dart';
import 'spams_page.dart';
import 'public_page.dart';
import 'colorbckd_page.dart';
import 'profile_page.dart';
import 'bug_menu.dart'; // IMPORT BUG MENU

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

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;
  final List<Map<String, dynamic>> listDDoS;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listPayload,
    required this.listDDoS,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listPayload;
  late List<Map<String, dynamic>> listDDoS;
  late List<dynamic> newsList;
  String androidId = "unknown";

  int _selectedIndex = 0;
  Widget _selectedPage = const Placeholder();

  final GlobalKey _bugButtonKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final PageController _pageController = PageController(viewportFraction: 0.92);
  final PageController _actionPageController = PageController(viewportFraction: 0.90);
  int _currentNewsIndex = 0;
  int _currentActionIndex = 0;

  List<Map<String, dynamic>> _activityLogs = [];
  bool _isLoadingActivityLogs = false;
  bool _hasActivityLogsError = false;

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // ===== WARNA PREMIUM DARI LANDING_PAGE2 =====
  final Color _primaryColor = const Color(0xFF00E5FF); // Cyan Neon
  final Color _secondaryColor = const Color(0xFF7C4DFF); // Purple
  final Color _accentColor = const Color(0xFFFF3366); // Pink/Red
  final Color _darkBg = const Color(0xFF0A0E27);
  final Color _darkerBg = const Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listPayload = widget.listPayload;
    listDDoS = widget.listDDoS;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();

    _selectedPage = _buildNewsPage();

    _initAndroidIdAndConnect();
    _fetchActivityLogs();
    _initializeVideo();
  }

  // ==================== BACKGROUND DENGAN EFEK GLOW DARI LANDING_PAGE2 ====================
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkBg, _darkerBg],
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: GridPainter(),
            size: Size.infinite,
          ),
          // Glowing orbs dari landing_page2
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
                    _primaryColor.withOpacity(0.15),
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
                    _secondaryColor.withOpacity(0.12),
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
                    _accentColor.withOpacity(0.08),
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

  Future<void> _loadSavedBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('selected_background') ?? 'hitam';
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _changeBackground(Color? color) {
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeVideo() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/landing.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController?.setLooping(true);
            _videoController?.play();
          }
        }).catchError((error) {
          _tryLoadVideoFromFile();
        });
    } catch (e) {
      _tryLoadVideoFromFile();
    }
  }

  void _tryLoadVideoFromFile() {
    try {
      final file = File('assets/videos/landing.mp4');
      if (file.existsSync()) {
        _videoController = VideoPlayerController.file(file)
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
              _videoController?.setLooping(true);
              _videoController?.play();
            }
          }).catchError((error) {
            _handleVideoError();
          });
      } else {
        _handleVideoError();
      }
    } catch (e) {
      _handleVideoError();
    }
  }

  void _handleVideoError() {
    if (mounted) {
      setState(() {
        _isVideoInitialized = false;
      });
    }
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('$baseUrl'));
    channel.sink.add(jsonEncode({
      "type": "validate",
      "key": sessionKey,
      "androidId": androidId,
    }));

    channel.sink.add(jsonEncode({"type": "stats"}));

    channel.stream.listen((event) {
      final data = jsonDecode(event);

      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          if (data['reason'] == 'androidIdMismatch') {
            _handleInvalidSession("Your account has logged on another device.");
          } else if (data['reason'] == 'keyInvalid') {
            _handleInvalidSession("Key is not valid. Please login again.");
          }
        }
      }
    }, onError: (error) {
      // Handle error
    });
  }

  Future<void> _fetchActivityLogs() async {
    setState(() {
      _isLoadingActivityLogs = true;
      _hasActivityLogsError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user/getActivityLogs?key=$sessionKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true && data['logs'] != null) {
          setState(() {
            _activityLogs = List<Map<String, dynamic>>.from(data['logs']);
            _isLoadingActivityLogs = false;
          });
        } else {
          setState(() {
            _isLoadingActivityLogs = false;
            _hasActivityLogsError = true;
          });
        }
      } else {
        setState(() {
          _isLoadingActivityLogs = false;
          _hasActivityLogsError = true;
        });
      }
    } catch (e) {
      print('Error fetching activity logs: $e');
      setState(() {
        _isLoadingActivityLogs = false;
        _hasActivityLogsError = true;
      });
    }
  }

  void _handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _primaryColor.withOpacity(0.3), width: 1),
        ),
        title: const Text("⚠️ Session Expired", style: TextStyle(color: Colors.white, fontFamily: "Orbitron")),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontFamily: "ShareTechMono")),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text("OK", style: TextStyle(color: Color(0xFFE0E0E0))),
          ),
        ],
      ),
    );
  }

  // ===== PERUBAHAN: TOMBOL BUG LANGSUNG KE BUG_MENU =====
  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _controller.reset();
      _controller.forward();

      if (index == 0) {
        _selectedPage = _buildNewsPage();
      } else if (index == 1) {
        _selectedPage = TelegramSpamPage(sessionKey: sessionKey);
      } else if (index == 2) {
        // ===== BUG MENU (LANGSUNG TAMPILKAN BUG_MENU) =====
        _selectedPage = BugMenuPage(
          username: username,
          password: password,
          sessionKey: sessionKey,
          role: role,
          expiredDate: expiredDate,
          listBug: listBug,
          listPayload: listPayload,
        );
      } else if (index == 3) {
        _selectedPage = AttackPanel(sessionKey: sessionKey, listDDoS: listDDoS);
      } else if (index == 4) {
        _selectedPage = ToolsPage(sessionKey: sessionKey, userRole: role);
      }
    });
  }

  void _selectFromDrawer(String page) {
    Navigator.pop(context);
    setState(() {
      if (page == 'reseller') {
        _selectedPage = SellerPage(keyToken: sessionKey);
      } else if (page == 'admin') {
        _selectedPage = AdminPage(sessionKey: sessionKey);
      } else if (page == 'sender') {
        _selectedPage = SenderPage(sessionKey: sessionKey);
      }
    });
  }

  // ==================== WIDGETS ====================

  Widget _buildServerStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withOpacity(0.15), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.code, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("API", style: TextStyle(color: Color(0xFFADB5BD), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: "ShareTechMono")),
                  Text("GACOR", style: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: "ShareTechMono")),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 35, color: const Color(0x15FFFFFF)),
          Row(
            children: [
              Icon(FontAwesomeIcons.server, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("SERVER", style: TextStyle(color: Color(0xFFADB5BD), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: "ShareTechMono")),
                  Text("AKTIF", style: TextStyle(color: Colors.amber.shade400, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: "ShareTechMono")),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 35, color: const Color(0x15FFFFFF)),
          Row(
            children: [
              Icon(FontAwesomeIcons.database, color: Colors.cyan, size: 16),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("DATA", style: TextStyle(color: Color(0xFFADB5BD), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: "ShareTechMono")),
                  Text("AMAN", style: TextStyle(color: Colors.cyan.shade400, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: "ShareTechMono")),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== CARD PROFIL PREMIUM (STYLE X•TOXIC) ====================
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryColor.withOpacity(0.1),
            _secondaryColor.withOpacity(0.05),
            Colors.black.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Welcome + Role Badge + Icon
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back,",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // App Name
          Row(
            children: [
              Icon(Icons.circle, color: _primaryColor, size: 8),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                ).createShader(bounds),
                child: const Text(
                  "XEXTRO 1.0",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              // Status online
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "ONLINE",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Stats Row: Online Users, Connections, Expiration
          Row(
            children: [
              _buildStatItem(
                icon: Icons.people,
                value: "0",
                label: "Online Users",
              ),
              _buildStatItem(
                icon: Icons.link,
                value: "0",
                label: "Connections",
              ),
              _buildStatItem(
                icon: Icons.timer,
                value: expiredDate.split(' ').first,
                label: "Expiration",
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Bottom Row: UID + Temp + Battery
          Row(
            children: [
              // UID Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  "UID: ${username.substring(0, username.length > 8 ? 8 : username.length).toUpperCase()}.${DateTime.now().toString().substring(2, 8)}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 9,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              // Temperature
              Row(
                children: [
                  Icon(Icons.thermostat, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "28°C",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Battery
              Row(
                children: [
                  Icon(Icons.battery_full, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "100%",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _primaryColor.withOpacity(0.6), size: 14),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 8,
              fontFamily: 'ShareTechMono',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== VIDEO PLAYER ====================
  Widget _buildVideoPlayer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
        border: Border.all(color: _primaryColor.withOpacity(0.15), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isVideoInitialized && _videoController != null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Icon(
                          _videoController!.value.isPlaying 
                              ? Icons.pause 
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFE0E0E0), strokeWidth: 2),
                      const SizedBox(height: 10),
                      Text("Loading Video...", style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: "ShareTechMono")),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ==================== APPBAR PREMIUM ====================
  Widget _buildDynamicAppBar() {
    return SafeArea(
      child: Container(
        height: 70,
        margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _primaryColor.withOpacity(0.15),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Menu Icon kiri
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  // Tengah: Titik Hijau + XEXTRO V1
                  Row(
                    children: [
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF34C759),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [_primaryColor, _secondaryColor],
                        ).createShader(bounds),
                        child: const Text(
                          "XEXTRO V1",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Kanan: Palette + Profile
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.palette, color: Colors.white, size: 22),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ColorBackgroundPage(
                                onBackgroundChanged: _changeBackground,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.person_outline, color: Colors.white, size: 24),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfilePage(
                                username: username,
                                role: role,
                                expiredDate: expiredDate,
                                sessionKey: sessionKey,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsPage() {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () async {
        await _fetchActivityLogs();
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildServerStatusCard(),
            _buildVideoPlayer(),
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildNewsCarousel(),
            _buildQuickActionsHorizontal(),
            _buildRecentActivity(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor() {
    switch (role.toLowerCase()) {
      case 'dev': return Colors.red;
      case 'founder': return Colors.red;
      case 'pt': return Colors.red;
      case 'admin': return Colors.red;
      case 'reseller': return Colors.blue;
      default: return _primaryColor;
    }
  }

  Widget _buildNewsCarousel() {
    if (newsList.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: _primaryColor.withOpacity(0.2)),
        ),
        child: const Center(child: Text("No news available", style: TextStyle(color: Colors.white54))),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: newsList.length,
            onPageChanged: (index) {
              setState(() {
                _currentNewsIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = newsList[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                  border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item['image'] != null && item['image'].toString().isNotEmpty)
                        NewsMedia(url: item['image']),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 15,
                        left: 15,
                        right: 15,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] ?? 'Server Info', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                            const SizedBox(height: 4),
                            Text(item['desc'] ?? 'Description here', style: const TextStyle(color: Colors.white70, fontSize: 12, shadows: [Shadow(color: Colors.black, blurRadius: 4)]), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (newsList.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              newsList.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                height: 6,
                width: _currentNewsIndex == index ? 20 : 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _currentNewsIndex == index ? _primaryColor : Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==================== MODERN QUICK ACTIONS (STYLE DARI NOCURE) ====================
  Widget _buildQuickActionsHorizontal() {
    final bool hasAdminAccess = ["dev", "founder", "pt","admin"].contains(role.toLowerCase());
    final bool hasResellerAccess = ["dev", "founder", "pt","admin"].contains(role.toLowerCase());
    
    // Daftar action mengikuti style nocure.dart
    final List<Map<String, dynamic>> quickActions = [];
    
    if (hasAdminAccess) {
      quickActions.add({
        "title": "Admin Page",
        "subtitle": "Full control panel",
        "icon": Icons.admin_panel_settings,
        "color1": const Color(0xFFE91E63),
        "color2": const Color(0xFFC2185B),
        "onTap": () {
          setState(() {
            _selectedPage = AdminPage(sessionKey: sessionKey);
          });
        },
      });
    }
    
    if (hasResellerAccess) {
      quickActions.add({
        "title": "Seller Page",
        "subtitle": "Manage resellers",
        "icon": Icons.store,
        "color1": const Color(0xFF0088CC),
        "color2": const Color(0xFF005580),
        "onTap": () {
          setState(() {
            _selectedPage = SellerPage(keyToken: sessionKey);
          });
        },
      });
    }
    
    quickActions.add({
      "title": "Public Chat",
      "subtitle": "Community discussion",
      "icon": FontAwesomeIcons.comments,
      "color1": const Color(0xFF4CAF50),
      "color2": const Color(0xFF388E3C),
      "onTap": () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PublicChatPage(username: username)));
      },
    });
    
    quickActions.add({
      "title": "Sender Manager",
      "subtitle": "Pairing & Config",
      "icon": FontAwesomeIcons.whatsapp,
      "color1": const Color(0xFF25D366),
      "color2": const Color(0xFF128C7E),
      "onTap": () {
        setState(() {
          _selectedPage = SenderPage(sessionKey: sessionKey);
        });
      },
    });
    
    quickActions.add({
      "title": "WA Spam",
      "subtitle": "Mass messaging",
      "icon": FontAwesomeIcons.whatsapp,
      "color1": const Color(0xFFFF9800),
      "color2": const Color(0xFFF57C00),
      "onTap": () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReportWaPage(sessionKey: sessionKey, username: username, role: role)));
      },
    });
    
    quickActions.add({
      "title": "Join Channel",
      "subtitle": "Get updates",
      "icon": FontAwesomeIcons.telegramPlane,
      "color1": const Color(0xFF0088CC),
      "color2": const Color(0xFF005580),
      "onTap": () async {
        final uri = Uri.parse("tg://resolve?domain=nullxteam");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(Uri.parse("https://t.me/xslinexcmnty"), mode: LaunchMode.externalApplication);
        }
      },
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bolt, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "QUICK ACCESS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Orbitron",
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: Color(0xFFFFD700), size: 8),
                    SizedBox(width: 6),
                    Text("ACTIVE", style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _actionPageController,
            itemCount: quickActions.length,
            onPageChanged: (index) {
              setState(() {
                _currentActionIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildActionSliderCard(quickActions[index]);
            },
          ),
        ),
        const SizedBox(height: 15),
        if (quickActions.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              quickActions.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentActionIndex == index ? 24 : 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _currentActionIndex == index ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionSliderCard(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: action['onTap'],
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [action['color1'], action['color2']],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: action['color2'].withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                action['icon'],
                size: 100,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(action['icon'], color: Colors.white, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "OPEN →",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    action['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Orbitron",
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action['subtitle'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Activity", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Orbitron")),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 4;
                    _selectedPage = _buildActivityLogsPage();
                  });
                },
                child: Text("View All", style: TextStyle(color: _primaryColor, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_isLoadingActivityLogs)
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1),
              ),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFE0E0E0))),
            )
          else if (_hasActivityLogsError)
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
              ),
              child: const Center(child: Text("Failed to load activity logs", style: TextStyle(color: Colors.white70, fontSize: 14))),
            )
          else if (_activityLogs.isEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1),
              ),
              child: const Center(child: Text("No activity logs available", style: TextStyle(color: Colors.white54, fontSize: 14))),
            )
          else
            ..._activityLogs.take(3).map((log) {
              final timestamp = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
              final formattedTime = _formatDateTime(timestamp);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black.withOpacity(0.3),
                    border: Border.all(color: _getActivityColor(log['activity']).withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getActivityColor(log['activity']).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getActivityIcon(log['activity']), color: _getActivityColor(log['activity']), size: 20),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['activity'] ?? 'Unknown Activity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            if (log['details'] != null && log['details']['target'] != null)
                              Text("Target: ${log['details']['target']}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(formattedTime, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityLogsPage() {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () async {
        await _fetchActivityLogs();
      },
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [_primaryColor.withOpacity(0.2), _secondaryColor.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: _primaryColor, size: 30),
                const SizedBox(width: 15),
                const Text("Activity History", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: "Orbitron")),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingActivityLogs
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE0E0E0)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _activityLogs.length,
              itemBuilder: (context, index) {
                final log = _activityLogs[index];
                final timestamp = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
                final formattedTime = _formatDateTime(timestamp);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black.withOpacity(0.3),
                    border: Border.all(color: _getActivityColor(log['activity']).withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_getActivityIcon(log['activity']), color: _getActivityColor(log['activity']), size: 20),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log['activity'] ?? 'Unknown Activity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(formattedTime, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (log['details'] != null)
                        _buildActivityDetails(log['details']),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityDetails(Map<String, dynamic> details) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${entry.key}:", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                const SizedBox(width: 5),
                Expanded(child: Text(entry.value.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getActivityColor(String? activity) {
    if (activity == null) return Colors.grey;
    if (activity.contains('Bug') || activity.contains('Attack') || activity.contains('Delete') || activity.contains('Failed')) return Colors.red;
    if (activity.contains('Call')) return Colors.orange;
    if (activity.contains('Create') || activity.contains('Add')) return Colors.green;
    if (activity.contains('Edit') || activity.contains('Change')) return Colors.blue;
    if (activity.contains('Cooldown')) return Colors.amber;
    return _primaryColor;
  }

  IconData _getActivityIcon(String? activity) {
    if (activity == null) return Icons.info;
    if (activity.contains('Bug') || activity.contains('Attack')) return Icons.bug_report;
    if (activity.contains('Call')) return Icons.phone;
    if (activity.contains('Create') || activity.contains('Add')) return Icons.person_add;
    if (activity.contains('Delete')) return Icons.delete;
    if (activity.contains('Edit') || activity.contains('Change')) return Icons.edit;
    if (activity.contains('Cooldown')) return Icons.timer;
    if (activity.contains('DDOS')) return Icons.flash_on;
    return Icons.info;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    if (difference.inHours > 0) return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    return 'Just now';
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.2),
        border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.05), blurRadius: 20, spreadRadius: 2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: child,
        ),
      ),
    );
  }

  Widget _glassButton({required Icon icon, required Text label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: icon,
      label: label,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryColor,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _primaryColor.withOpacity(0.3), width: 1),
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor),
          const SizedBox(width: 10),
          Text("$label:", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontFamily: "ShareTechMono")),
        ],
      ),
    );
  }

  // ==================== BOTTOM NAVIGATION ====================
  List<BottomNavigationBarItem> _buildBottomNavBarItems() {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home, size: 24),
        label: "Home",
      ),
      const BottomNavigationBarItem(
        icon: Icon(FontAwesomeIcons.telegram, size: 22),
        label: "Telegram",
      ),
      BottomNavigationBarItem(
        key: _bugButtonKey,
        icon: const Icon(Icons.bug_report, size: 24),
        label: "Bug",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.flash_on, size: 24),
        label: "DDoS",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.build, size: 24),
        label: "Tools",
      ),
    ];
    return items;
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            border: Border(right: BorderSide(color: _primaryColor.withOpacity(0.2), width: 1)),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor.withOpacity(0.1), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(child: Image.asset('assets/images/logo.png', height: 50, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
                          const SizedBox(height: 15),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _primaryColor, width: 2),
                              ),
                              child: const CircleAvatar(
                                radius: 45,
                                backgroundImage: NetworkImage("https://cdn.phototourl.com/free/2026-08-11-7a47da8d-a9eb-4471-a9b6-b44a6ece4fd8.jpg"),
                                backgroundColor: Color(0xFF1E1E1E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFFE0E0E0), size: 18),
                            const SizedBox(width: 8),
                            const Text("USERNAME:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(width: 5),
                            Text(username, style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 12, fontFamily: "ShareTechMono")),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, color: Color(0xFFE0E0E0), size: 18),
                            const SizedBox(width: 8),
                            const Text("ROLE:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(width: 5),
                            Text(role.toUpperCase(), style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 12, fontFamily: "ShareTechMono")),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE0E0E0), thickness: 0.5, indent: 20, endIndent: 20),
                  if (role == "reseller" || role == "admin" || role == "pt" || role == "founder" || role == "dev")
                    ListTile(
                      leading: const Icon(Icons.store, color: Color(0xFFE0E0E0)),
                      title: const Text("Reseller Page", style: TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFFE0E0E0), size: 20),
                      onTap: () => _selectFromDrawer('reseller'),
                    ),
                  if (role == "admin" || role == "pt" || role == "founder" || role == "dev")
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: Color(0xFFE0E0E0)),
                      title: const Text("Admin Page", style: TextStyle(color: Colors.white70)),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFFE0E0E0), size: 20),
                      onTap: () => _selectFromDrawer('admin'),
                    ),
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Color(0xFFE0E0E0)),
                    title: const Text("Sender Page", style: TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFE0E0E0), size: 20),
                    onTap: () => _selectFromDrawer('sender'),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _primaryColor, width: 1),
                          ),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage("https://files.catbox.moe/csc5an.jpg"),
                            backgroundColor: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("@RULZIZY", style: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold, fontSize: 14)),
                              Text("Support dev", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _primaryColor, width: 1),
                          ),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage("https://cdn.phototourl.com/free/2026-08-11-7a47da8d-a9eb-4471-a9b6-b44a6ece4fd8.jpg"),
                            backgroundColor: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("X SLINEX COMMUNITY", style: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold, fontSize: 12)),
                              Text("official", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // BACKGROUND
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 90),
              child: FadeTransition(
                opacity: _animation,
                child: _selectedPage,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildDynamicAppBar(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              backgroundColor: Colors.black.withOpacity(0.5),
              selectedItemColor: _primaryColor,
              unselectedItemColor: Colors.white54,
              currentIndex: _selectedIndex,
              onTap: _onTabSelected,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedFontSize: 11,
              unselectedFontSize: 10,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              items: _buildBottomNavBarItems(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _controller.dispose();
    _pageController.dispose();
    _actionPageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}

/// Widget Media (gambar/video dengan audio)
class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(1.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) {
    return url.endsWith(".mp4") || url.endsWith(".webm") || url.endsWith(".mov") || url.endsWith(".mkv");
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFE0E0E0)));
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.black26),
      );
    }
  }
}