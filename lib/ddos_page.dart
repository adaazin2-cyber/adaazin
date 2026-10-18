// tools_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'chat_ai_page.dart';
import 'nik_check_page.dart';
import 'phone_lookup.dart';
import 'subdomain_finder_page.dart';
import 'anime.dart';

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

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerAnimation;
  late List<Animation<double>> _itemAnimations;

  // ==================== WARNA LOADER ====================
  final Color _primaryColor = const Color(0xFF88AAEE);
  final Color _cardColor = const Color(0xFF141414);
  final Color _bgColor = const Color(0xFF0D0D0D);
  final Color _textColor = Colors.white;
  final Color _textSecondary = const Color(0xFFADB5BD);
  final Color _borderColor = Colors.white.withOpacity(0.15);

  // ==================== BACKGROUND GRID ====================
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D0D0D),
            const Color(0xFF000000),
            const Color(0xFF3A3A3A).withOpacity(0.2),
          ],
        ),
      ),
      child: CustomPaint(
        painter: GridPainter(),
        size: Size.infinite,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _itemAnimations = List.generate(
      5,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _listController,
          curve: Interval(
            index * 0.1,
            0.5 + (index * 0.1),
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );

    _headerController.forward();
    _listController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAnimatedHeader(),
                const SizedBox(height: 24),
                Expanded(child: _buildToolsList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _headerAnimation.value) * 30),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _cardColor,
                border: Border.all(
                  color: _borderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primaryColor.withOpacity(0.2)),
                        ),
                        child: Icon(Icons.apps, color: _primaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Digital Tools",
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select a tool to begin",
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolsList() {
    final tools = [
      {'icon': Icons.chat, 'label': 'Chat AI', 'description': 'AI-powered conversation assistant'},
      {'icon': Icons.badge, 'label': 'NIK Check', 'description': 'Validate Indonesian identity numbers'},
      {'icon': Icons.phone, 'label': 'Phone Lookup', 'description': 'Find information about phone numbers'},
      {'icon': Icons.language, 'label': 'Subdomain Finder', 'description': 'Discover subdomains of any domain'},
      {'icon': Icons.movie_filter_outlined, 'label': 'Anime', 'description': 'Tempat Nya Para Wibu Marathon Anime'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return _buildAnimatedToolItem(
          icon: tool['icon'] as IconData,
          label: tool['label'] as String,
          description: tool['description'] as String,
          animation: _itemAnimations[index],
          onTap: () => _navigateToTool(tool['label'] as String),
        );
      },
    );
  }

  void _navigateToTool(String toolName) {
    Widget page;
    switch (toolName) {
      case 'Chat AI':
        page = ChatAIPage(sessionKey: widget.sessionKey);
        break;
      case 'NIK Check':
        page = NIKCheckPage(sessionKey: widget.sessionKey);
        break;
      case 'Phone Lookup':
        page = PhoneLookupPage(sessionKey: widget.sessionKey);
        break;
      case 'Anime':
        page = HomeAnimePage();
        break;
      case 'Subdomain Finder':
        page = SubdomainFinderPage(sessionKey: widget.sessionKey);
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildAnimatedToolItem({
    required IconData icon,
    required String label,
    required String description,
    required Animation<double> animation,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset((1 - animation.value) * 50, 0),
          child: Opacity(
            opacity: animation.value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _InteractiveToolItem(
                icon: icon,
                label: label,
                description: description,
                onTap: onTap,
                primaryColor: _primaryColor,
                cardColor: _cardColor,
                textColor: _textColor,
                textSecondary: _textSecondary,
                borderColor: _borderColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InteractiveToolItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color cardColor;
  final Color textColor;
  final Color textSecondary;
  final Color borderColor;

  const _InteractiveToolItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    required this.primaryColor,
    required this.cardColor,
    required this.textColor,
    required this.textSecondary,
    required this.borderColor,
  });

  @override
  State<_InteractiveToolItem> createState() => _InteractiveToolItemState();
}

class _InteractiveToolItemState extends State<_InteractiveToolItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPressed
                      ? widget.primaryColor.withOpacity(0.6)
                      : widget.borderColor,
                  width: 1,
                ),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.primaryColor.withOpacity(0.2)),
                    ),
                    child: Icon(widget.icon, color: widget.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: widget.textSecondary,
                            fontSize: 12,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: widget.primaryColor.withOpacity(0.4),
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}