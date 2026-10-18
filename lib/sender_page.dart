import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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

class SenderPage extends StatefulWidget {
  final String sessionKey;

  const SenderPage({super.key, required this.sessionKey});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> with TickerProviderStateMixin {
  // ==================== WARNA LOADER ====================
  final Color _primaryColor = const Color(0xFF88AAEE);
  final Color _cardColor = const Color(0xFF141414);
  final Color _bgColor = const Color(0xFF0D0D0D);
  final Color _textColor = Colors.white;
  final Color _textSecondary = const Color(0xFFADB5BD);
  final Color _borderColor = Colors.white.withOpacity(0.15);

  // State variables
  Map<String, dynamic> connections = {"private": [], "global": []};
  bool isLoading = false;
  String _currentFilter = "all";
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

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
    _initializeAnimations();
    _fetchSenders();
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  // ==================== API FUNCTIONS (PAKAI baseUrl) ====================
  Future<void> _fetchSenders() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      // ===== PAKAI baseUrl DARI domain_server.dart =====
      final res = await http.get(
        Uri.parse("$baseUrl/api/whatsapp/mySender?key=${widget.sessionKey}"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() {
            connections = data["connections"] ?? {"private": [], "global": []};
          });
        } else {
          _showErrorSnackBar(data['message'] ?? "Failed to fetch senders");
        }
      } else {
        _showErrorSnackBar("Failed to fetch senders");
      }
    } catch (e) {
      debugPrint("Error fetching senders: $e");
      _showErrorSnackBar("Failed to fetch senders. Please try again.");
    }

    setState(() => isLoading = false);
  }

  Future<void> _addSender(String number, bool isGlobal) async {
    if (number.isEmpty) {
      _showErrorSnackBar("Phone number cannot be empty");
      return;
    }

    try {
      // ===== PAKAI baseUrl DARI domain_server.dart =====
      final url = "$baseUrl/api/whatsapp/getPairing?key=${widget.sessionKey}&number=$number" + 
                   (isGlobal ? "&isGlobal=true" : "");
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['valid'] == true) {
          _showPairingCodeDialog(number, res['pairingCode'], isGlobal);
          _fetchSenders();
        } else {
          _showErrorSnackBar("Failed: ${res['message'] ?? 'Unknown error'}");
        }
      } else {
        _showErrorSnackBar("Failed to get pairing code");
      }
    } catch (e) {
      debugPrint("Error adding sender: $e");
      _showErrorSnackBar("An error occurred. Please try again.");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade900.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: _primaryColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showPairingCodeDialog(String number, String code, bool isGlobal) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.phonelink_lock, color: _primaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Pairing Code",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      "Number: $number",
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isGlobal ? _primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isGlobal ? "GLOBAL SENDER" : "PRIVATE SENDER",
                        style: TextStyle(
                          color: isGlobal ? _primaryColor : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _primaryColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              code,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Enter this code in your WhatsApp app to complete pairing.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        foregroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: _borderColor),
                        ),
                      ),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text("Copy Code"),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        _showSuccessSnackBar("Pairing code copied to clipboard!");
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSenderDialog(bool isGlobal) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isGlobal ? _primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isGlobal ? Icons.public : Icons.lock,
                      color: isGlobal ? _primaryColor : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGlobal ? "Add Global Sender" : "Add Private Sender",
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        isGlobal ? "Dapat digunakan semua orang" : "Hanya untuk pribadi",
                        style: TextStyle(
                          color: _textSecondary.withOpacity(0.6),
                          fontSize: 12,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: _textColor),
                cursorColor: _primaryColor,
                decoration: InputDecoration(
                  hintText: "Enter phone number",
                  hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.phone, color: _primaryColor.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: _textSecondary.withOpacity(0.6)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGlobal ? _primaryColor : Colors.grey,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final number = controller.text.trim();
                      await _addSender(number, isGlobal);
                    },
                    child: Text(
                      "Add Sender",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isGlobal ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== FILTER & LIST ====================
  List<dynamic> _getFilteredSenders() {
    switch (_currentFilter) {
      case "private":
        return connections["private"] ?? [];
      case "global":
        return connections["global"] ?? [];
      default:
        return [
          ...connections["private"] ?? [],
          ...connections["global"] ?? []
        ];
    }
  }

  int _getSenderCount() {
    switch (_currentFilter) {
      case "private":
        return connections["private"]?.length ?? 0;
      case "global":
        return connections["global"]?.length ?? 0;
      default:
        return (connections["private"]?.length ?? 0) + (connections["global"]?.length ?? 0);
    }
  }

  int _getTotalSenderCount() {
    return (connections["private"]?.length ?? 0) + (connections["global"]?.length ?? 0);
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final totalSenders = _getTotalSenderCount();

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ===== BACKGROUND GRID =====
          _buildBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // ===== HEADER =====
                _buildHeader(),
                
                // ===== 2 MENU ADD SENDER =====
                _buildAddSenderMenu(),
                
                const SizedBox(height: 8),
                
                // ===== FILTER CHIPS =====
                _buildFilterChips(),
                
                // ===== SENDER LIST =====
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF88AAEE)))
                      : totalSenders == 0
                          ? _buildEmptyState()
                          : _buildSenderList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: _primaryColor, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          Text(
            "My Senders (${_getSenderCount()})",
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
      ),
    );
  }

  // ==================== 2 MENU ADD SENDER ====================
  Widget _buildAddSenderMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // PRIVATE SENDER
          Expanded(
            child: GestureDetector(
              onTap: () => _showAddSenderDialog(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.lock_outline, color: Colors.grey, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "PRIVATE",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Pribadi",
                      style: TextStyle(
                        color: _textSecondary.withOpacity(0.5),
                        fontSize: 10,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // GLOBAL SENDER
          Expanded(
            child: GestureDetector(
              onTap: () => _showAddSenderDialog(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.public, color: _primaryColor, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "GLOBAL",
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Semua orang",
                      style: TextStyle(
                        color: _primaryColor.withOpacity(0.5),
                        fontSize: 10,
                        fontFamily: 'ShareTechMono',
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

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip("All", "all"),
            const SizedBox(width: 8),
            _buildFilterChip("Private", "private"),
            const SizedBox(width: 8),
            _buildFilterChip("Global", "global"),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _currentFilter == filter;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : _textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter = filter;
        });
      },
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: _primaryColor,
      checkmarkColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? _primaryColor : _borderColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_disabled,
              color: _textSecondary.withOpacity(0.3),
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No senders found",
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Add a sender to get started",
            style: TextStyle(
              color: _textSecondary.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderList() {
    final filteredSenders = _getFilteredSenders();

    if (filteredSenders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              color: _textSecondary.withOpacity(0.3),
              size: 50,
            ),
            const SizedBox(height: 16),
            Text(
              "No senders in '${_currentFilter.toUpperCase()}'",
              style: TextStyle(
                color: _textSecondary.withOpacity(0.5),
                fontSize: 16,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSenders,
      color: _primaryColor,
      backgroundColor: _bgColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSenders.length,
        itemBuilder: (context, index) {
          final sender = filteredSenders[index];
          final isGlobal = sender['dev'] == "global" || sender['role'] == "high admin";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGlobal ? _primaryColor.withOpacity(0.3) : _borderColor,
              ),
              boxShadow: isGlobal ? [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ] : [],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isGlobal ? _primaryColor.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.phone,
                  color: isGlobal ? _primaryColor : Colors.grey,
                ),
              ),
              title: Text(
                sender['sessionName'] ?? 'Unknown',
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Type: ${sender['type'] ?? 'N/A'}",
                      style: TextStyle(color: _textSecondary.withOpacity(0.7), fontSize: 12),
                    ),
                    Text(
                      "Dev: ${isGlobal ? 'Global (VIP)' : sender['dev'] ?? 'N/A'}",
                      style: TextStyle(color: _textSecondary.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isGlobal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        "VIP",
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Active",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
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