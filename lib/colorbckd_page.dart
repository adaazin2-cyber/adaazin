// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorBackgroundPage extends StatefulWidget {
  final Function(Color?) onBackgroundChanged;

  const ColorBackgroundPage({
    super.key,
    required this.onBackgroundChanged,
  });

  @override
  State<ColorBackgroundPage> createState() => _ColorBackgroundPageState();
}

class _ColorBackgroundPageState extends State<ColorBackgroundPage> {
  // Variabel untuk menyimpan warna background yang dipilih
  String _selectedBackground = 'hitam';
  bool _isLoading = false;
  
  // Daftar warna background yang tersedia
  final List<Map<String, dynamic>> _backgroundOptions = [
    // ===== WARNA POLOS =====
    {
      'id': 'hitam',
      'name': 'Hitam',
      'color': Colors.black,
      'type': 'solid',
      'category': 'Polos',
    },
    {
      'id': 'hitblu',
      'name': 'HITBLU',
      'color': const Color(0xFF0A0A2E),
      'type': 'solid',
      'category': 'Polos',
    },
    {
      'id': 'putih',
      'name': 'Putih',
      'color': Colors.white,
      'type': 'solid',
      'category': 'Polos',
    },
    {
      'id': 'abu_putih',
      'name': 'Abu Putih',
      'color': const Color(0xFFE8E8E8),
      'type': 'solid',
      'category': 'Polos',
    },
    {
      'id': 'hitam_abu',
      'name': 'Hitam Abu',
      'color': const Color(0xFF2A2A2A),
      'type': 'solid',
      'category': 'Polos',
    },
    // ===== WARNA PATTERN =====
    {
      'id': 'biru_kotak',
      'name': 'Biru Kotak',
      'color': const Color(0xFF0A1628),
      'type': 'pattern',
      'category': 'Pattern',
      'patternColors': [
        Colors.blue.shade300.withOpacity(0.8),
        Colors.white.withOpacity(0.6),
      ],
    },
    {
      'id': 'abu_kotak',
      'name': 'Abu Kotak',
      'color': const Color(0xFF1A1A1A),
      'type': 'pattern',
      'category': 'Pattern',
      'patternColors': [
        Colors.grey.shade400.withOpacity(0.8),
        Colors.grey.shade800.withOpacity(0.6),
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedBackground();
  }

  // Fungsi untuk load background yang tersimpan
  Future<void> _loadSavedBackground() async {
    if (_isLoading) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('selected_background') ?? 'hitam';
      
      if (mounted) {
        setState(() {
          _selectedBackground = saved;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedBackground = 'hitam';
        });
      }
    }
  }

  // Fungsi untuk menyimpan dan menerapkan background
  Future<void> _applyBackground(String id) async {
    // Cegah multiple click
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Simpan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_background', id);
      
      // Cari warna berdasarkan id
      final option = _backgroundOptions.firstWhere(
        (opt) => opt['id'] == id,
        orElse: () => _backgroundOptions.first,
      );
      
      // Ambil warna
      Color bgColor = option['color'] as Color;
      
      // Kirim warna ke parent (hanya jika widget masih mounted)
      if (mounted) {
        widget.onBackgroundChanged(bgColor);
      }
      
      // Update state
      if (mounted) {
        setState(() {
          _selectedBackground = id;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Jika error, tetap gunakan hitam
      if (mounted) {
        widget.onBackgroundChanged(Colors.black);
        setState(() {
          _selectedBackground = 'hitam';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Change Background",
          style: TextStyle(
            color: Colors.white,
            fontFamily: "Orbitron",
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (mounted) {
              Navigator.pop(context);
            }
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              const Color(0xFF1A1A2E).withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: Colors.white.withOpacity(0.8),
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Pilih Background",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Orbitron",
                            ),
                          ),
                          Text(
                            "Pilih gaya background yang kamu suka",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontFamily: "ShareTechMono",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===== LOADING INDICATOR =====
              if (_isLoading)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFFE0E0E0),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Menyimpan...",
                        style: TextStyle(
                          color: Colors.white54,
                          fontFamily: "ShareTechMono",
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _backgroundOptions.length,
                    itemBuilder: (context, index) {
                      final option = _backgroundOptions[index];
                      final bool isSelected = _selectedBackground == option['id'];
                      final bool isPattern = option['type'] == 'pattern';
                      final List<Color>? patternColors = option['patternColors'] as List<Color>?;
                      
                      return GestureDetector(
                        onTap: () => _applyBackground(option['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.1),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.15),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Preview warna
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: option['color'],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: isPattern && patternColors != null
                                    ? CustomPaint(
                                        painter: GridPatternPainter(
                                          color1: patternColors[0],
                                          color2: patternColors[1],
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              // Nama dan status
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option['name'],
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontFamily: "Orbitron",
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option['category'] ?? '',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 11,
                                        fontFamily: "ShareTechMono",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status aktif
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "AKTIF",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "ShareTechMono",
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 10),

              // ===== TOMBOL RESET =====
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _applyBackground('hitam'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: const Text(
                    "Reset ke Default (Hitam)",
                    style: TextStyle(
                      fontFamily: "ShareTechMono",
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== CUSTOM PAINTER - PATTERN MENCOLOK =====
class GridPatternPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  GridPatternPainter({
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint untuk garis - TEBAL & MENCOLOK
    final paint1 = Paint()
      ..color = color1
      ..strokeWidth = 2.5;
    
    // Paint untuk kotak - MENCOLOK
    final paint2 = Paint()
      ..color = color2;
    
    // Jarak antar garis
    final double spacing = size.width / 6;
    
    // Gambar garis vertikal
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint1,
      );
    }
    
    // Gambar garis horizontal
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint1,
      );
    }
    
    // Gambar kotak-kotak di persimpangan - BESAR & MENCOLOK
    final double boxSize = spacing / 2.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: boxSize,
            height: boxSize,
          ),
          paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}