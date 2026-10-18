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

class AttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const AttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<AttackPage> createState() => _AttackPageState();
}

class _AttackPageState extends State<AttackPage> with TickerProviderStateMixin {
  final targetController = TextEditingController();

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
  String selectedBugId = "";
  bool _isSending = false;
  bool _isSuccess = false;
  int _activeStep = 0;

  // ===== WARNA PREMIUM DARI LOADER_PAGE =====
  final Color _primaryColor = const Color(0xFF00E5FF); // Cyan Neon
  final Color _secondaryColor = const Color(0xFF7C4DFF); // Purple
  final Color _accentColor = const Color(0xFFFF3366); // Pink/Red
  final Color _darkBg = const Color(0xFF0A0E27);
  final Color _darkerBg = const Color(0xFF000000);
  final Color _cardColor = const Color(0xFF141414);
  final Color _textColor = Colors.white;
  final Color _textSecondary = const Color(0xFFADB5BD);
  final Color _borderColor = Colors.white.withOpacity(0.15);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideoController();
    _setDefaultBug();
    _startAnimations();
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

  void _setDefaultBug() {
    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
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

  Future<void> _sendBug() async {
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

    if (target == null || key.isEmpty) {
      _showAlert("❌ Invalid Number", "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }

    try {
      final res = await http.get(Uri.parse("$baseUrl/api/whatsapp/sendBug?key=$key&target=$target&bug=$selectedBugId"));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        _showAlert("⏳ Cooldown", "Tunggu beberapa saat sebelum mengirim lagi.");
      } else if (data["senderOn"] == false) {
        _showAlert("⚠️ Gagal", "Gagal mengirim bug. Sender Kosong, Hubungi Seller.");
      } else if (data["valid"] == false) {
        _showAlert("❌ Key Invalid", "Session key tidak valid. Silakan login ulang.");
      } else if (data["sended"] == false) {
        _showAlert("⚠️ Gagal", "Gagal mengirim bug. Mungkin server sedang maintenance.");
      } else {
        setState(() {
          _activeStep = 2;
          _isSuccess = true;
        });
        _showSuccessPopup(target);
      }
    } catch (_) {
      _showAlert("❌ Error", "Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
        if (!_isSuccess) _activeStep = 0;
      });
    }
  }

  void _showSuccessPopup(String target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessVideoDialog(
        target: target,
        onDismiss: () {
          Navigator.of(context).pop();
          setState(() {
            _isSuccess = false;
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
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _borderColor, width: 1),
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
                        // ===== BUG TYPE (DIPERBESAR) =====
                        _buildPayloadTypeCard(),
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

  // ==================== BUG TYPE (DIPERBESAR) ====================
  Widget _buildPayloadTypeCard() {
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
                  FontAwesomeIcons.whatsapp,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Bug Type",
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
          // Bug type dalam grid horizontal yang lebih besar
          SizedBox(
            height: 120, // Diperbesar dari 80
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.listBug.length,
              itemBuilder: (context, index) {
                final bug = widget.listBug[index];
                final isSelected = selectedBugId == bug['bug_id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedBugId = bug['bug_id'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 160, // Diperbesar dari 140
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [_primaryColor.withOpacity(0.2), _secondaryColor.withOpacity(0.2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _primaryColor : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.virus,
                          color: isSelected ? _primaryColor : Colors.white.withOpacity(0.5),
                          size: 24, // Diperbesar dari 18
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bug['bug_name'],
                          style: TextStyle(
                            color: isSelected ? _textColor : Colors.white.withOpacity(0.7),
                            fontSize: 13, // Diperbesar dari 11
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontFamily: 'Orbitron',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (bug['description'] != null)
                          Text(
                            bug['description'],
                            style: TextStyle(
                              color: isSelected ? _primaryColor : Colors.white.withOpacity(0.4),
                              fontSize: 10,
                              fontFamily: 'ShareTechMono',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.arrowLeft,
                color: Colors.white.withOpacity(0.3),
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(
                "Swipe to see more bug types",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                  fontFamily: 'ShareTechMono',
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                FontAwesomeIcons.arrowRight,
                color: Colors.white.withOpacity(0.3),
                size: 12,
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
                _isSending ? "SENDING..." : "SEND BUG",
                style: const TextStyle(
                  fontSize: 16,
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
              onPressed: _isSending ? null : _sendBug,
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
              "Use this tool responsibly. We are not responsible for any misuse.",
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
        return Colors.red;
      case 'tk':
        return Colors.red;
      case 'pt':
        return Colors.red;
      case 'helper':
        return Colors.red;
      case 'admin':
        return Colors.red;
      case 'vip':
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
    super.dispose();
  }
}

// ==================== SUCCESS VIDEO DIALOG ====================
class SuccessVideoDialog extends StatefulWidget {
  final String target;
  final VoidCallback onDismiss;

  const SuccessVideoDialog({
    super.key,
    required this.target,
    required this.onDismiss,
  });

  @override
  State<SuccessVideoDialog> createState() => _SuccessVideoDialogState();
}

class _SuccessVideoDialogState extends State<SuccessVideoDialog> with TickerProviderStateMixin {
  late VideoPlayerController _successVideoController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _showSuccessInfo = false;
  bool _videoError = false;
  bool _videoInitialized = false;

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

    _initializeSuccessVideo();
  }

  void _initializeSuccessVideo() {
    try {
      _successVideoController = VideoPlayerController.asset('assets/videos/splash.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoInitialized = true;
            });
            _successVideoController.play();

            _successVideoController.addListener(() {
              if (_successVideoController.value.position >= _successVideoController.value.duration) {
                _showSuccessMessage();
              }
            });
          }
        }).catchError((error) {
          print('Success video error: $error');
          if (mounted) {
            setState(() {
              _videoError = true;
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              _showSuccessMessage();
            });
          }
        });
    } catch (e) {
      print('Video controller error: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _showSuccessMessage();
        });
      }
    }
  }

  void _showSuccessMessage() {
    if (mounted) {
      setState(() {
        _showSuccessInfo = true;
      });
      _fadeController.forward();
      _scaleController.forward();
    }
  }

  @override
  void dispose() {
    _successVideoController.dispose();
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
              if (!_showSuccessInfo)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _videoInitialized && !_videoError
                      ? SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _successVideoController.value.size.width,
                              height: _successVideoController.value.size.height,
                              child: VideoPlayer(_successVideoController),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0D0D0D),
                                _primaryColor.withOpacity(0.1),
                                const Color(0xFF0D0D0D),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _glowController,
                                  builder: (context, child) {
                                    return Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [_primaryColor.withOpacity(0.2), _secondaryColor.withOpacity(0.2)],
                                        ),
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(
                                          color: _primaryColor.withOpacity(0.3 * _glowAnimation.value),
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
                                        FontAwesomeIcons.check,
                                        color: _primaryColor,
                                        size: 50,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "SUCCESS",
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

              if (_showSuccessInfo)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF141414),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                                    color: _primaryColor.withOpacity(0.3 * _glowAnimation.value),
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
                                  size: 36,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Attack Successful!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Bug successfully sent to ${widget.target}",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontFamily: 'ShareTechMono',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: widget.onDismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                              shadowColor: _primaryColor.withOpacity(0.3),
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
                        ],
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
}