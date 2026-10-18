import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';

// ==================== IMPORT BASEURL ====================
import '../server/domain_server.dart' show baseUrl;

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

class CustomAttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listPayload;
  final String role;
  final String expiredDate;

  const CustomAttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listPayload,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<CustomAttackPage> createState() => _CustomAttackPageState();
}

class _CustomAttackPageState extends State<CustomAttackPage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final qtyController = TextEditingController(text: "5");
  final delayController = TextEditingController(text: "100");

  // Animation controllers
  late AnimationController _buttonController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Video controllers
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  // State variables
  List<String> selectedBugs = [];
  String _senderType = "global";
  bool _isSending = false;
  Map<String, String> _senderTypeLimits = {};
  int _activeStep = 0;

  // ===== UNTUK MENAMPUNG JUMLAH SENDER =====
  Map<String, dynamic> _connections = {"private": [], "global": []};
  bool _isLoadingSenders = false;

  // ===== WARNA PREMIUM DARI LOADER_PAGE =====
  final Color _primaryColor = const Color(0xFF00E5FF); // Cyan Neon
  final Color _secondaryColor = const Color(0xFF7C4DFF); // Purple
  final Color _accentColor = const Color(0xFFFF3366); // Pink/Red
  final Color _darkBg = const Color(0xFF0A0E27);
  final Color _darkerBg = const Color(0xFF000000);
  final Color _textColor = Colors.white;
  final Color _textSecondary = const Color(0xFFADB5BD);
  final Color _borderColor = Colors.white.withOpacity(0.15);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideoController();
    _setSenderTypeLimits();
    _setDefaultBugs();
    _startAnimations();
    _fetchSendersCount();
  }

  // ===== FETCH JUMLAH SENDER =====
  Future<void> _fetchSendersCount() async {
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/whatsapp/mySender?key=${widget.sessionKey}"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() {
            _connections = data["connections"] ?? {"private": [], "global": []};
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching senders count: $e");
    }
    setState(() => _isLoadingSenders = false);
  }

  int _getGlobalCount() {
    return _connections["global"]?.length ?? 0;
  }

  int _getPrivateCount() {
    return _connections["private"]?.length ?? 0;
  }

  void _initializeAnimations() {
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  void _setSenderTypeLimits() {
    _senderTypeLimits = {
      "global": "Max Qty: 10, Delay: 500ms (Fixed)",
      "private": "Max Qty: 200, Min Delay: 10ms",
    };
  }

  void _setDefaultBugs() {
    if (widget.listPayload.isNotEmpty) {
      selectedBugs.add(widget.listPayload[0]['bug_id']);
    }
  }

  void _initializeVideoController() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/bug.mp4')
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

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0') || cleaned.length < 8) return null;
    return cleaned;
  }

  void _toggleBugSelection(String bugId) {
    setState(() {
      if (selectedBugs.contains(bugId)) {
        selectedBugs.remove(bugId);
      } else {
        selectedBugs.add(bugId);
      }
    });
  }

  Future<void> _sendCustomBug() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _activeStep = 1;
    });

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;
    final qty = int.tryParse(qtyController.text) ?? 1;
    final delay = int.tryParse(delayController.text) ?? 100;

    if (target == null || key.isEmpty) {
      _showAlert("❌ Invalid Number", "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }

    if (selectedBugs.isEmpty) {
      _showAlert("❌ No Payload Selected", "Please select at least one payload to send.");
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }

    try {
      final bugsParam = selectedBugs.join(',');

      final res = await http.get(Uri.parse("$baseUrl/api/whatsapp/customBug?key=$key&target=$target&bug=$bugsParam&qty=$qty&delay=$delay&senderType=$_senderType"));
      final data = jsonDecode(res.body);

      if (data["valid"] == false) {
        _showAlert("❌ Failed", data["message"] ?? "Failed to send custom bug.");
      } else {
        setState(() {
          _activeStep = 2;
        });
        _showSuccessPopup(target, data["details"]);
      }
    } catch (_) {
      _showAlert("❌ Error", "Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
        if (_activeStep != 2) _activeStep = 0;
      });
    }
  }

  void _showSuccessPopup(String target, Map<String, dynamic> details) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomSuccessDialog(
        target: target,
        details: details,
        onDismiss: () {
          Navigator.of(context).pop();
          setState(() {
            _activeStep = 0;
          });
        },
      ),
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _primaryColor.withOpacity(0.3), width: 1),
        ),
        title: Text(title, style: TextStyle(color: _textColor, fontFamily: 'Orbitron', fontSize: 16)),
        content: Text(msg, style: TextStyle(color: _textSecondary, fontFamily: 'ShareTechMono', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // ==================== BACKGROUND DENGAN EFEK GLOW ====================
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

  @override
  Widget build(BuildContext context) {
    // Only allow access to VIP, Owner, Dev, Founder, TK, PT, Admin, Helper
    final allowedRoles = ["dev", "founder", "pt", "vip", "ful upf", "admin"];
    if (!allowedRoles.contains(widget.role.toLowerCase())) {
      return Scaffold(
        backgroundColor: _darkerBg,
        body: Stack(
          children: [
            _buildBackground(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.lock,
                      color: Colors.red,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "ACCESS DENIED",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "This feature is only available for Dev, founder, Ful Upf, and Admin users",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontFamily: 'ShareTechMono',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ===== HEADER CARD =====
                        _buildUserInfoHeader(),
                        const SizedBox(height: 16),
                        // ===== VIDEO PLAYER =====
                        _buildVideoPlayer(),
                        const SizedBox(height: 16),
                        // ===== PROGRESS =====
                        _buildProgressIndicator(),
                        const SizedBox(height: 16),
                        // ===== TARGET INPUT =====
                        _buildTargetInputCard(),
                        const SizedBox(height: 14),
                        // ===== PAYLOAD SELECTION =====
                        _buildPayloadSelectionCard(),
                        const SizedBox(height: 14),
                        // ===== SENDER TYPE (DENGAN ANGKA) =====
                        _buildSenderTypeCard(),
                        const SizedBox(height: 14),
                        // ===== QUANTITY & DELAY =====
                        _buildQuantityDelayCard(),
                        const SizedBox(height: 14),
                        // ===== SYSTEM STATUS =====
                        _buildStatusIndicators(),
                        const SizedBox(height: 20),
                        // ===== SEND BUTTON =====
                        _buildSendButton(),
                        const SizedBox(height: 14),
                        // ===== FOOTER =====
                        _buildFooterInfo(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== USER INFO HEADER ====================
  Widget _buildUserInfoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // KIRI: USERNAME
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "USERNAME",
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.username,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // TENGAH: FOTO + EXPIRED
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Text(
                      "EXPIRED",
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _primaryColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/icon.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: _primaryColor.withOpacity(0.1),
                            child: Icon(Icons.person, color: _primaryColor, size: 30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.expiredDate.split(' ').first,
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),
              // KANAN: ROLE
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "ROLE",
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== VIDEO PLAYER ====================
  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 0.5),
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
        borderRadius: BorderRadius.circular(16),
        child: _videoInitialized && !_videoError
            ? Stack(
                alignment: Alignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_videoController.value.isPlaying) {
                            _videoController.pause();
                          } else {
                            _videoController.play();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Icon(
                          _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                      SizedBox(height: 10),
                      Text(
                        "Loading Video...",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ==================== PROGRESS INDICATOR ====================
  Widget _buildProgressIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderRadius: BorderRadius.circular(16),
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
      child: Row(
        children: [
          _buildStepIndicator(0, "Input", FontAwesomeIcons.edit),
          _buildProgressLine(),
          _buildStepIndicator(1, "Process", FontAwesomeIcons.cogs),
          _buildProgressLine(),
          _buildStepIndicator(2, "Complete", FontAwesomeIcons.checkCircle),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _activeStep >= step;
    final isCurrent = _activeStep == step;

    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: isActive 
                  ? LinearGradient(colors: [_primaryColor, _secondaryColor])
                  : null,
              color: isActive ? null : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? _primaryColor : Colors.white.withOpacity(0.15),
                width: isCurrent ? 2.5 : 1.5,
              ),
              boxShadow: isActive ? [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? _textColor : Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontFamily: 'Orbitron',
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: _activeStep > 0
              ? LinearGradient(colors: [_primaryColor, _secondaryColor])
              : null,
          color: _activeStep > 0 ? null : Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  // ==================== TARGET INPUT ====================
  Widget _buildTargetInputCard() {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FontAwesomeIcons.phone,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Target Number",
                style: TextStyle(
                  color: _textColor,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: targetController,
            style: TextStyle(color: _textColor, fontSize: 16),
            cursorColor: _primaryColor,
            decoration: InputDecoration(
              hintText: "e.g. +62xxxxxxxxx",
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _borderColor, width: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FontAwesomeIcons.globe,
                  color: _textSecondary.withOpacity(0.6),
                  size: 16,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Use international format without 0 or +",
            style: TextStyle(
              color: _textSecondary.withOpacity(0.5),
              fontSize: 11,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PAYLOAD SELECTION ====================
  Widget _buildPayloadSelectionCard() {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FontAwesomeIcons.bug,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Select Payloads",
                style: TextStyle(
                  color: _textColor,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${selectedBugs.length} selected",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontFamily: 'ShareTechMono',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.listPayload.map((bug) {
              final bugId = bug['bug_id'];
              final bugName = bug['bug_name'];
              final isSelected = selectedBugs.contains(bugId);

              return FilterChip(
                label: Text(bugName),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : _textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  fontFamily: 'Orbitron',
                ),
                selected: isSelected,
                onSelected: (_) => _toggleBugSelection(bugId),
                backgroundColor: Colors.white.withOpacity(0.05),
                selectedColor: _primaryColor,
                checkmarkColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? _primaryColor : Colors.white.withOpacity(0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                elevation: isSelected ? 2 : 0,
                shadowColor: _primaryColor.withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                FontAwesomeIcons.infoCircle,
                color: Colors.white.withOpacity(0.4),
                size: 12,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Select multiple payloads for a combined attack",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SENDER TYPE (DENGAN ANGKA) ====================
  Widget _buildSenderTypeCard() {
    final int globalCount = _getGlobalCount();
    final int privateCount = _getPrivateCount();

    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FontAwesomeIcons.server,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Sender Type",
                style: TextStyle(
                  color: _textColor,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // GLOBAL SENDER
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _senderType = "global"),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _senderType == "global"
                          ? LinearGradient(colors: [_primaryColor.withOpacity(0.2), _secondaryColor.withOpacity(0.2)])
                          : null,
                      color: _senderType == "global" ? null : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _senderType == "global"
                            ? _primaryColor
                            : Colors.white.withOpacity(0.1),
                        width: _senderType == "global" ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          FontAwesomeIcons.globe,
                          color: _senderType == "global" ? _primaryColor : Colors.white54,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Global",
                          style: TextStyle(
                            color: _senderType == "global" ? _primaryColor : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        // ===== ANGKA GLOBAL SENDER =====
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isLoadingSenders ? "..." : "$globalCount Sender",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _senderTypeLimits["global"]!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 9,
                            fontFamily: 'ShareTechMono',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // PRIVATE SENDER
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _senderType = "private"),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _senderType == "private"
                          ? LinearGradient(colors: [_primaryColor.withOpacity(0.2), _secondaryColor.withOpacity(0.2)])
                          : null,
                      color: _senderType == "private" ? null : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _senderType == "private"
                            ? _primaryColor
                            : Colors.white.withOpacity(0.1),
                        width: _senderType == "private" ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          FontAwesomeIcons.user,
                          color: _senderType == "private" ? _primaryColor : Colors.white54,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Private",
                          style: TextStyle(
                            color: _senderType == "private" ? _primaryColor : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        // ===== ANGKA PRIVATE SENDER =====
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.grey, Colors.grey.shade700]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isLoadingSenders ? "..." : "$privateCount Sender",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _senderTypeLimits["private"]!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 9,
                            fontFamily: 'ShareTechMono',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_senderType == "global")
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.infoCircle,
                    color: Colors.white.withOpacity(0.4),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Note: Delay is fixed at 500ms for Global sender",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        fontFamily: 'ShareTechMono',
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

  // ==================== QUANTITY & DELAY ====================
  Widget _buildQuantityDelayCard() {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FontAwesomeIcons.slidersH,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Quantity & Delay",
                style: TextStyle(
                  color: _textColor,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: _textColor),
                  cursorColor: _primaryColor,
                  decoration: InputDecoration(
                    labelText: "Quantity",
                    labelStyle: TextStyle(color: _textSecondary.withOpacity(0.7)),
                    hintText: "1-200",
                    hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _borderColor, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: delayController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: _textColor),
                  cursorColor: _primaryColor,
                  enabled: _senderType == "private",
                  decoration: InputDecoration(
                    labelText: "Delay (ms)",
                    labelStyle: TextStyle(
                      color: _senderType == "private"
                          ? _textSecondary.withOpacity(0.7)
                          : _textSecondary.withOpacity(0.3),
                    ),
                    hintText: "10-1000",
                    hintStyle: TextStyle(
                      color: _senderType == "private"
                          ? _textSecondary.withOpacity(0.5)
                          : _textSecondary.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: _senderType == "private"
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white.withOpacity(0.02),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _senderType == "private"
                            ? _borderColor
                            : Colors.white.withOpacity(0.08),
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _senderType == "private"
                            ? _primaryColor
                            : Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SYSTEM STATUS ====================
  Widget _buildStatusIndicators() {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.circular(16),
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
          Text(
            "System Status",
            style: TextStyle(
              color: _textColor,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statusIndicator(
                icon: FontAwesomeIcons.server,
                label: "Server",
                isOnline: true,
              ),
              _statusIndicator(
                icon: FontAwesomeIcons.shieldAlt,
                label: "Security",
                isOnline: true,
              ),
              _statusIndicator(
                icon: FontAwesomeIcons.database,
                label: "Database",
                isOnline: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusIndicator({required IconData icon, required String label, required bool isOnline}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isOnline
                ? LinearGradient(colors: [_primaryColor.withOpacity(0.2), _secondaryColor.withOpacity(0.2)])
                : null,
            color: isOnline ? null : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOnline ? _primaryColor.withOpacity(0.3) : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: isOnline ? _primaryColor : Colors.white.withOpacity(0.3),
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontFamily: 'ShareTechMono',
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            gradient: isOnline
                ? LinearGradient(colors: [_primaryColor, _secondaryColor])
                : null,
            color: isOnline ? null : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // ==================== SEND BUTTON ====================
  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: _isSending
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(FontAwesomeIcons.paperPlane, color: Colors.white, size: 18),
              label: Text(
                _isSending ? "SENDING..." : "SEND CUSTOM PAYLOAD",
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSending ? null : _sendCustomBug,
            ),
          ),
        );
      },
    );
  }

  // ==================== FOOTER ====================
  Widget _buildFooterInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.exclamationTriangle,
            color: Colors.white.withOpacity(0.4),
            size: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Custom attack with multiple payloads. Use responsibly.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor() {
    switch (widget.role.toLowerCase()) {
      case 'founder':
      case 'pt':
      case 'admin':
        return Colors.red;
      case 'dev':
        return Colors.amber;
      case 'reseller':
        return Colors.blue;
      default:
        return _primaryColor;
    }
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _videoController.dispose();
    targetController.dispose();
    qtyController.dispose();
    delayController.dispose();
    super.dispose();
  }
}

// ==================== CUSTOM SUCCESS DIALOG ====================
class CustomSuccessDialog extends StatefulWidget {
  final String target;
  final Map<String, dynamic> details;
  final VoidCallback onDismiss;

  const CustomSuccessDialog({
    super.key,
    required this.target,
    required this.details,
    required this.onDismiss,
  });

  @override
  State<CustomSuccessDialog> createState() => _CustomSuccessDialogState();
}

class _CustomSuccessDialogState extends State<CustomSuccessDialog> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _showDetails = false;

  final Color _primaryColor = const Color(0xFF00E5FF);
  final Color _secondaryColor = const Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showDetails = true;
        });
        _fadeController.forward();
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.45;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.15),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Success icon and title
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryColor.withOpacity(0.2), _secondaryColor.withOpacity(0.2)],
                            ),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: _primaryColor.withOpacity(0.3 + 0.2 * _glowAnimation.value),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.2 * _glowAnimation.value),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            FontAwesomeIcons.checkDouble,
                            color: _primaryColor,
                            size: 40,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "CUSTOM ATTACK SENT!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Attack details
              if (_showDetails)
                Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  bottom: 80,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _primaryColor.withOpacity(0.2), width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Attack Details:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow("Target", widget.target),
                            _buildDetailRow("Sender Type", widget.details["senderType"] ?? "N/A"),
                            _buildDetailRow("Payloads", (widget.details["bugs"] ?? 0).toString()),
                            _buildDetailRow("Quantity", (widget.details["qty"] ?? 1).toString()),
                            _buildDetailRow("Delay", "${widget.details["delay"] ?? 100}ms"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Close button
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "DONE",
                    style: TextStyle(
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _primaryColor,
                fontSize: 12,
                fontFamily: 'ShareTechMono',
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}