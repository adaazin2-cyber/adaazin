import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final _newUser = TextEditingController();
  final _newPass = TextEditingController();
  final _days = TextEditingController();
  final _editUser = TextEditingController();
  final _editDays = TextEditingController();
  bool loading = false;

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

  // ==================== API LOGIC (PAKAI baseUrl) ====================
  Future<void> _create() async {
    final u = _newUser.text.trim(), p = _newPass.text.trim(), d = _days.text.trim();
    if (u.isEmpty || p.isEmpty || d.isEmpty) return _showNotification("Semua field wajib diisi", isError: true);
    setState(() => loading = true);
    try {
      // ===== PAKAI baseUrl DARI domain_server.dart =====
      final res = await http.get(Uri.parse(
          "$baseUrl/api/user/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d"));
      final data = jsonDecode(res.body);
      if (data['created'] == true) {
        _showNotification("Akun berhasil dibuat!");
        _newUser.clear(); _newPass.clear(); _days.clear();
        Navigator.pop(context); 
      } else {
        _showNotification(data['message'] ?? 'Gagal membuat akun.', isError: true);
      }
    } catch (e) {
      _showNotification("Terjadi kesalahan: ${e.toString()}", isError: true);
    }
    setState(() => loading = false);
  }

  Future<void> _edit() async {
    final u = _editUser.text.trim(), d = _editDays.text.trim();
    if (u.isEmpty || d.isEmpty) return _showNotification("Username dan durasi wajib diisi", isError: true);
    setState(() => loading = true);
    try {
      // ===== PAKAI baseUrl DARI domain_server.dart =====
      final res = await http.get(Uri.parse(
          "$baseUrl/api/user/editUser?key=${widget.keyToken}&username=$u&addDays=$d"));
      final data = jsonDecode(res.body);
      if (data['edited'] == true) {
        _showNotification("Durasi berhasil diperbarui.");
        _editUser.clear(); _editDays.clear();
        Navigator.pop(context); 
      } else {
        _showNotification(data['message'] ?? 'Gagal mengubah durasi.', isError: true);
      }
    } catch (e) {
      _showNotification("Terjadi kesalahan: ${e.toString()}", isError: true);
    }
    setState(() => loading = false);
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade900 : _cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: _primaryColor.withOpacity(0.2)),
        ),
      ),
    );
  }

  // ==================== UI WIDGETS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ===== BACKGROUND GRID =====
          _buildBackground(),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER =====
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: _primaryColor, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "RESELLER PANEL",
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    "Kelola akun pelanggan dengan mudah",
                    style: TextStyle(
                      color: _textSecondary.withOpacity(0.6),
                      fontSize: 12,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ===== CARD 1: BUAT AKUN =====
                  _buildActionCard(
                    title: "BUAT USER BARU",
                    subtitle: "Role: MEMBER",
                    icon: Icons.person_add,
                    onTap: _showCreateAccountDialog,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ===== CARD 2: UBAH DURASI =====
                  _buildActionCard(
                    title: "UBAH DURASI HARI",
                    subtitle: "Perpanjang durasi akun",
                    icon: Icons.edit_calendar,
                    onTap: _showEditDurationDialog,
                  ),
                  
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor, width: 0.5),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.2)),
              ),
              child: Icon(icon, color: _primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _textSecondary.withOpacity(0.6),
                      fontSize: 12,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: _primaryColor.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showCreateAccountDialog() {
    _newUser.clear();
    _newPass.clear();
    _days.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _borderColor, width: 0.5),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryColor.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.person_add, color: _primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "BUAT USER BARU",
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              Text(
                "Role: MEMBER",
                style: TextStyle(
                  color: _textSecondary.withOpacity(0.6),
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Username
              _buildDialogField(
                controller: _newUser,
                label: "KETIK USERNAME",
                hint: "contoh: jokowiddo",
                icon: Icons.person_outline,
              ),
              
              const SizedBox(height: 16),
              
              // Password
              _buildDialogField(
                controller: _newPass,
                label: "KETIK PASSWORD",
                hint: "contoh: 123",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              
              const SizedBox(height: 16),
              
              // Durasi
              _buildDialogField(
                controller: _days,
                label: "DURASI (HARI)",
                hint: "contoh: 30",
                icon: Icons.calendar_today,
                isNumber: true,
              ),
              
              const SizedBox(height: 24),
              
              // Tombol BUAT AKUN
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [_primaryColor, const Color(0xFF5B8DEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: loading ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "BUAT AKUN",
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
              
              const SizedBox(height: 12),
              
              // Tombol Batal
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "BATAL",
                  style: TextStyle(
                    color: _textSecondary.withOpacity(0.6),
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDurationDialog() {
    _editUser.clear();
    _editDays.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _borderColor, width: 0.5),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryColor.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.edit_calendar, color: _primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "UBAH DURASI HARI",
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              Text(
                "Perpanjang durasi akun",
                style: TextStyle(
                  color: _textSecondary.withOpacity(0.6),
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Username
              _buildDialogField(
                controller: _editUser,
                label: "USERNAME USER?",
                hint: "ketik username nya",
                icon: Icons.person_outline,
              ),
              
              const SizedBox(height: 16),
              
              // Durasi
              _buildDialogField(
                controller: _editDays,
                label: "UBAH DURASI USER",
                hint: "batas 30 hari untuk reseller",
                icon: Icons.calendar_today,
                isNumber: true,
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primaryColor.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _primaryColor.withOpacity(0.5),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "UNLIMITED UNTUK SELAIN RESELLER",
                        style: TextStyle(
                          color: _primaryColor.withOpacity(0.5),
                          fontSize: 10,
                          fontFamily: 'ShareTechMono',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tombol UBAH DURASI
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [_primaryColor, const Color(0xFF5B8DEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: loading ? null : _edit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "UBAH DURASI",
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
              
              const SizedBox(height: 12),
              
              // Tombol Batal
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "BATAL",
                  style: TextStyle(
                    color: _textSecondary.withOpacity(0.6),
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              label,
              style: TextStyle(
                color: _textSecondary.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'ShareTechMono',
                letterSpacing: 0.5,
              ),
            ),
          ),
          TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: _textColor, fontSize: 14),
            cursorColor: _primaryColor,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _textSecondary.withOpacity(0.3),
                fontSize: 13,
                fontFamily: 'ShareTechMono',
              ),
              prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.4), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}