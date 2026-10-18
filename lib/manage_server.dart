// manage_server_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
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

class ManageServerPage extends StatefulWidget {
  final String sessionKey;

  const ManageServerPage({super.key, required this.sessionKey});

  @override
  State<ManageServerPage> createState() => _ManageServerPageState();
}

class _ManageServerPageState extends State<ManageServerPage> {
  // --- Theme Colors (Glowing Silver) ---
  static const Color primaryColor = Color(0xFF88AAEE);
  static const Color secondaryColor = Color(0xFF141414);
  static const Color accentColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFF0D0D0D);

  bool _isLoading = true;
  List<Map<String, dynamic>> _servers = [];

  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchServers();
  }

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

  Future<void> _fetchServers() async {
    setState(() => _isLoading = true);
    try {
      // ===== PAKAI baseUrl DARI domain_server.dart =====
      final response = await http.get(Uri.parse("$baseUrl/api/vps/myServer?key=${widget.sessionKey}"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['servers'] != null) {
          setState(() {
            _servers = List<Map<String, dynamic>>.from(data['servers']);
          });
        }
      } else {
        _showMessage("Failed to load servers.", isError: true);
      }
    } catch (e) {
      _showMessage("Error fetching servers: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addServer() async {
    final host = _hostController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (host.isEmpty || username.isEmpty || password.isEmpty) {
      _showMessage("All fields are required.", isError: true);
      return;
    }

    try {
      // ===== PAKAI baseUrl DARI domain_server.dart =====
      final response = await http.post(
        Uri.parse("$baseUrl/api/vps/addServer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "host": host,
          "username": username,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showMessage("Server added successfully!");
        _hostController.clear();
        _usernameController.clear();
        _passwordController.clear();
        Navigator.pop(context);
        _fetchServers();
      } else {
        _showMessage(data['error'] ?? "Failed to add server.", isError: true);
      }
    } catch (e) {
      _showMessage("Error adding server: $e", isError: true);
    }
  }

  Future<void> _deleteServer(String host) async {
    try {
      // ===== PAKAI baseUrl DARI domain_server.dart =====
      final response = await http.post(
        Uri.parse("$baseUrl/api/vps/delServer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "host": host,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showMessage("Server deleted successfully!");
        _fetchServers();
      } else {
        _showMessage(data['error'] ?? "Failed to delete server.", isError: true);
      }
    } catch (e) {
      _showMessage("Error deleting server: $e", isError: true);
    }
  }

  void _showAddServerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        title: const Text(
          "Add New Server", 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            letterSpacing: 1,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _hostController,
              style: const TextStyle(color: primaryColor),
              cursorColor: primaryColor,
              decoration: _inputDecoration("Host IP"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: primaryColor),
              cursorColor: primaryColor,
              decoration: _inputDecoration("SSH Username"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: primaryColor),
              cursorColor: primaryColor,
              obscureText: true,
              decoration: _inputDecoration("SSH Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: primaryColor.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: _addServer,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.black,
              elevation: 5,
              shadowColor: primaryColor.withOpacity(0.5),
            ),
            child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade900 : secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isError ? Colors.red : primaryColor.withOpacity(0.5)),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: primaryColor.withOpacity(0.3)),
      filled: true,
      fillColor: Colors.black.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // ===== BACKGROUND GRID =====
          _buildBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // ===== CUSTOM APPBAR =====
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: primaryColor),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Manage Servers",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: primaryColor),
                        onPressed: _fetchServers,
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: primaryColor))
                      : _servers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.dns_outlined, size: 64, color: primaryColor.withOpacity(0.3)),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No servers found",
                                    style: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 18, fontFamily: 'Orbitron'),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Add your first VPS to get started",
                                    style: TextStyle(color: primaryColor.withOpacity(0.5), fontSize: 14, fontFamily: 'ShareTechMono'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _servers.length,
                              itemBuilder: (context, index) {
                                final server = _servers[index];
                                return Card(
                                  color: secondaryColor,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: primaryColor.withOpacity(0.1)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.computer, color: primaryColor),
                                    ),
                                    title: Text(
                                      server['host'] ?? 'Unknown Host',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
                                    ),
                                    subtitle: Text(
                                      "User: ${server['username'] ?? 'N/A'}",
                                      style: TextStyle(color: primaryColor.withOpacity(0.6), fontFamily: 'ShareTechMono'),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: secondaryColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              side: BorderSide(color: primaryColor.withOpacity(0.3)),
                                            ),
                                            title: const Text("Confirm Delete", style: TextStyle(color: Colors.white, fontFamily: 'Orbitron')),
                                            content: Text(
                                              "Are you sure you want to delete server ${server['host']}?",
                                              style: const TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono'),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text("Cancel", style: TextStyle(color: primaryColor.withOpacity(0.7))),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteServer(server['host']);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red.shade900,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text("Delete"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddServerDialog,
        backgroundColor: primaryColor,
        elevation: 10,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}