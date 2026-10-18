import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

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

class ReportWaPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const ReportWaPage({
    super.key, 
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<ReportWaPage> createState() => _ReportWaPageState();
}

class _ReportWaPageState extends State<ReportWaPage> {
  // ==================== WARNA ====================
  final Color _primaryColor = const Color(0xFF88AAEE);
  final Color _cardColor = const Color(0xFF141414);
  final Color _bgColor = const Color(0xFF0D0D0D);
  final Color _textColor = Colors.white;
  final Color _textSecondary = const Color(0xFFADB5BD);
  final Color _borderColor = Colors.white.withOpacity(0.15);

  // ==================== CONTROLLERS ====================
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: "5");
  final ScrollController _logScrollController = ScrollController();

  // ==================== STATE ====================
  bool _isAttacking = false;
  bool _isLoadingSenders = false;
  List<dynamic> _privateSenders = [];
  List<dynamic> _globalSenders = [];
  String _selectedSenderType = "global";
  List<String> _logs = [];
  int _successCount = 0;
  int _failCount = 0;

  // ==================== TEKS & GAMBAR SPAM ====================
  final String _spamText = "MAKLO AMPAS MAKLO AMPAS YATIM TOLOL BEGO REDUP AJA LU ANJ MATI AJA ANAK BABI🤪😹😹🤪🖕🖕";
  final String _spamImage = "https://cdn.phototourl.com/free/2026-07-21-1f2b70c7-3163-4291-ad0e-f09c90c7ceec.jpg";

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
    _fetchSenders();
  }

  @override
  void dispose() {
    _targetController.dispose();
    _amountController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  // ==================== FETCH SENDERS ====================
  Future<void> _fetchSenders() async {
    setState(() => _isLoadingSenders = true);
    _addLog("[SYSTEM] Authenticating as ${widget.username}...");
    
    try {
      final uri = Uri.parse("$baseUrl/api/whatsapp/mySender?key=${widget.sessionKey}");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          final connections = data['connections'];
          
          setState(() {
            _privateSenders = connections['private'] ?? [];
            _globalSenders = connections['global'] ?? [];
          });
          
          final total = _privateSenders.length + _globalSenders.length;
          _addLog("[ACCESS GRANTED] $total Agents Loaded.");
          _addLog("  └─ Global: ${_globalSenders.length} Agents");
          _addLog("  └─ Private: ${_privateSenders.length} Agents");
        } else {
          _addLog("[ERROR] Session Expired / Invalid Key.");
        }
      } else {
        _addLog("[ERROR] Server Offline (Status: ${response.statusCode})");
      }
    } catch (e) {
      _addLog("[FATAL] Connection Failed: $e");
    } finally {
      setState(() => _isLoadingSenders = false);
    }
  }

  // ==================== EKSEKUSI SPAM ====================
  Future<void> _executeSpam() async {
    final List<dynamic> selectedSenders = _selectedSenderType == "global" 
        ? _globalSenders 
        : _privateSenders;

    if (selectedSenders.isEmpty) {
      _showSnack("No ${_selectedSenderType.toUpperCase()} senders available!", Colors.red);
      return;
    }

    if (_targetController.text.isEmpty) {
      _showSnack("Target number is required!", Colors.red);
      return;
    }

    int totalAmount = int.tryParse(_amountController.text) ?? 5;
    if (totalAmount < 1) totalAmount = 1;
    if (totalAmount > 50) totalAmount = 50;

    setState(() {
      _isAttacking = true;
      _successCount = 0;
      _failCount = 0;
      _logs.clear();
      _addLog("[SYSTEM] 🚀 STARTING SPAM ATTACK");
      _addLog("[TARGET] ${_targetController.text}");
      _addLog("[AMOUNT] $totalAmount Messages");
      _addLog("[SENDER TYPE] ${_selectedSenderType.toUpperCase()}");
      _addLog("[AGENTS] ${selectedSenders.length} Active");
      _addLog("─" * 30);
    });

    for (int i = 0; i < totalAmount; i++) {
      if (!_isAttacking) break;

      var sender = selectedSenders[i % selectedSenders.length];
      String senderNum = sender['owner'] ?? 'Unknown';

      try {
        // ===== 1. KIRIM TEKS =====
        final textResponse = await http.post(
          Uri.parse("$baseUrl/api/whatsapp/spamText"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "key": widget.sessionKey,
            "target": _targetController.text,
            "sender_number": senderNum,
            "message": _spamText,
          }),
        );

        if (textResponse.statusCode == 200) {
          final textData = jsonDecode(textResponse.body);
          if (textData['success'] == true) {
            _addLog("[${i+1}] 📝 TEXT SENT via $senderNum");
            setState(() => _successCount++);
          } else {
            _addLog("[${i+1}] ❌ TEXT FAILED: ${textData['message'] ?? 'Unknown error'}");
            setState(() => _failCount++);
            continue;
          }
        } else {
          _addLog("[${i+1}] ❌ TEXT FAILED (HTTP ${textResponse.statusCode})");
          setState(() => _failCount++);
          continue;
        }

        await Future.delayed(const Duration(milliseconds: 500));

        // ===== 2. KIRIM GAMBAR =====
        final imageResponse = await http.post(
          Uri.parse("$baseUrl/api/whatsapp/spamImage"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "key": widget.sessionKey,
            "target": _targetController.text,
            "sender_number": senderNum,
            "image_url": _spamImage,
            "caption": "MAKLO AMPAS! 🤪🖕",
          }),
        );

        if (imageResponse.statusCode == 200) {
          final imageData = jsonDecode(imageResponse.body);
          if (imageData['success'] == true) {
            _addLog("[${i+1}] 🖼️ IMAGE SENT via $senderNum");
            setState(() => _successCount++);
          } else {
            _addLog("[${i+1}] ❌ IMAGE FAILED: ${imageData['message'] ?? 'Unknown error'}");
            setState(() => _failCount++);
          }
        } else {
          _addLog("[${i+1}] ❌ IMAGE FAILED (HTTP ${imageResponse.statusCode})");
          setState(() => _failCount++);
        }

        await Future.delayed(const Duration(milliseconds: 300));
        
      } catch (e) {
        _addLog("[${i+1}] 💀 ERROR: $e");
        setState(() => _failCount++);
      }
    }

    setState(() {
      _isAttacking = false;
      _addLog("─" * 30);
      _addLog("[SYSTEM] ✅ SPAM COMPLETED");
      _addLog("  └─ Success: $_successCount");
      _addLog("  └─ Failed: $_failCount");
      _addLog("  └─ Total: ${_successCount + _failCount}");
    });
  }

  void _addLog(String log) {
    if (!mounted) return;
    setState(() {
      _logs.add(log);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ==================== UI BUILDER ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildUserCard(),
                  const SizedBox(height: 12),
                  _buildSenderTypeSelector(),
                  const SizedBox(height: 12),
                  _buildInputRow(),
                  const SizedBox(height: 12),
                  _buildLaunchButton(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildLogs()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 8),
        Text(
          "SPAM PANEL",
          style: TextStyle(
            color: _textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.refresh, color: _primaryColor, size: 22),
          onPressed: _fetchSenders,
        ),
      ],
    );
  }

  Widget _buildUserCard() {
    final totalSenders = _privateSenders.length + _globalSenders.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryColor, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/icon.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: _primaryColor, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.username,
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "ROLE: ${widget.role.toUpperCase()}",
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 10,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, color: Colors.green, size: 8),
                const SizedBox(width: 6),
                Text(
                  "$totalSenders AGENTS",
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderTypeSelector() {
    final int globalCount = _globalSenders.length;
    final int privateCount = _privateSenders.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSenderType = "global"),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedSenderType == "global" 
                      ? _primaryColor.withOpacity(0.15) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedSenderType == "global" 
                        ? _primaryColor 
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.public, color: _primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "GLOBAL",
                          style: TextStyle(
                            color: _selectedSenderType == "global" 
                                ? _primaryColor 
                                : _textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'Orbitron',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$globalCount AGENTS",
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSenderType = "private"),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedSenderType == "private" 
                      ? Colors.grey.withOpacity(0.15) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedSenderType == "private" 
                        ? Colors.grey 
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, color: Colors.grey, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "PRIVATE",
                          style: TextStyle(
                            color: _selectedSenderType == "private" 
                                ? Colors.white 
                                : _textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'Orbitron',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$privateCount AGENTS",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
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
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _targetController,
              style: TextStyle(color: _textColor, fontSize: 14),
              cursorColor: _primaryColor,
              decoration: InputDecoration(
                hintText: "Target (e.g. 628xx)",
                hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 12),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.phone, color: _primaryColor.withOpacity(0.5), size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: _textColor, fontSize: 14),
              cursorColor: _primaryColor,
              decoration: InputDecoration(
                hintText: "Qty",
                hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 12),
                filled: true,
                fillColor: Colors.white.withOpacity(0.03),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.numbers, color: _primaryColor.withOpacity(0.5), size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchButton() {
    return GestureDetector(
      onTap: _isAttacking ? () => setState(() => _isAttacking = false) : _executeSpam,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: _isAttacking 
              ? const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)])
              : const LinearGradient(colors: [Color(0xFF88AAEE), Color(0xFF5B8DEF)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_isAttacking ? Colors.red : const Color(0xFF88AAEE)).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _isAttacking ? "🛑 STOP SPAM" : "🚀 LAUNCH SPAM",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogs() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "> SYSTEM LOGS",
                style: TextStyle(
                  color: _primaryColor,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (_isAttacking)
                const SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.greenAccent,
                  ),
                )
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          Expanded(
            child: ListView.builder(
              controller: _logScrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color textColor;
                if (log.contains("ERROR") || log.contains("FAILED")) {
                  textColor = Colors.redAccent;
                } else if (log.contains("SUCCESS") || log.contains("SENT") || log.contains("✅")) {
                  textColor = Colors.greenAccent;
                } else if (log.contains("🚀") || log.contains("STARTING")) {
                  textColor = _primaryColor;
                } else if (log.contains("─")) {
                  textColor = Colors.white.withOpacity(0.1);
                } else {
                  textColor = _textSecondary;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}