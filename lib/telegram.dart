import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
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

class TelegramSpamPage extends StatefulWidget {
  final String sessionKey;

  const TelegramSpamPage({super.key, required this.sessionKey});

  @override
  State<TelegramSpamPage> createState() => _TelegramSpamPageState();
}

class _TelegramSpamPageState extends State<TelegramSpamPage>
    with SingleTickerProviderStateMixin {
  // ==================== WARNA ====================
  final Color _primaryColor = const Color(0xFF88AAEE);
  final Color _cardColor = const Color(0xFF141414);
  final Color _bgColor = const Color(0xFF0D0D0D);
  final Color _textColor = Colors.white;
  final Color _textSecondary = const Color(0xFFADB5BD);
  final Color _borderColor = Colors.white.withOpacity(0.15);

  // ==================== CONTROLLERS ====================
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _authController = TextEditingController(); 
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _reportTextController = TextEditingController(
    text: "This account is violating Telegram's terms of service through spam and scam activities.",
  );
  final TextEditingController _reportLinkController = TextEditingController();
  final TextEditingController _reportCountController = TextEditingController(text: "50");

  final Map<String, TextEditingController> _sessionPasswordControllers = {};

  // ==================== STATE ====================
  List<TelegramSession> _sessions = [];
  bool _isLoading = false;
  bool _isLoggingIn = false;
  bool _isRefreshing = false;
  bool _isReporting = false;

  String _currentLoginPhone = "";
  String _currentLoginId = "";
  String _loginErrorMessage = "";
  String _currentLoginStep = "wait_code";
  bool _canResendOtp = true;
  int _resendOtpCooldown = 30;

  int _reportProgress = 0;
  int _reportTotal = 0;
  String _reportStatus = "";
  String _currentReportId = "";
  Timer? _statusCheckTimer;
  Timer? _resendOtpTimer;
  Timer? _loginStatusTimer;

  late TabController _tabController;
  int _currentTabIndex = 0;

  final TextStyle _monoStyle = const TextStyle(fontFamily: 'monospace');

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.animation != null) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadSessions();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _resendOtpTimer?.cancel();
    _loginStatusTimer?.cancel();
    _tabController.dispose();
    _phoneController.dispose();
    _authController.dispose();
    _targetController.dispose();
    _reportTextController.dispose();
    _reportLinkController.dispose();
    _reportCountController.dispose();
    for (var controller in _sessionPasswordControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ==================== API CALLS (PAKAI baseUrl) ====================
  Future<void> _loadSessions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // ===== PAKAI baseUrl =====
      final response = await http.get(
        Uri.parse('$baseUrl/api/tools/telegram/sessions?key=${widget.sessionKey}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _sessions = (data['sessions'] as List)
                .map((session) => TelegramSession.fromJson(session))
                .toList();
            _isLoading = false;
          });
          for (var session in _sessions) {
            _sessionPasswordControllers.putIfAbsent(
                session.phone, () => TextEditingController());
          }
        } else {
          if (mounted) _showSnackBar(data['message'] ?? 'Failed to load sessions', isError: true);
          setState(() => _isLoading = false);
        }
      } else {
        if (mounted) _showSnackBar('Server error: ${response.statusCode}', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error loading sessions: ${e.toString()}', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiateLogin({bool isResend = false}) async {
    if (!isResend && _phoneController.text.trim().isEmpty) {
      setState(() => _loginErrorMessage = "Please enter a phone number.");
      return;
    }
    setState(() {
      _isLoggingIn = true;
      _loginErrorMessage = "";
    });

    try {
      final phone = _currentLoginPhone.isEmpty ? _phoneController.text.trim() : _currentLoginPhone;
      // ===== PAKAI baseUrl =====
      final response = await http.get(
        Uri.parse('$baseUrl/api/tools/telegram/login?key=${widget.sessionKey}&phone=$phone'),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentLoginPhone = phone;
            _currentLoginId = data['loginId'];
            _currentLoginStep = data['step'] ?? 'wait_code';
            _isLoggingIn = false;
          });
          _authController.clear();
          if (isResend) {
            if (mounted) _showSnackBar('OTP code resent');
          } else {
            if (mounted) _showSnackBar('OTP code sent to your phone');
            Navigator.of(context).pop();
            _showAuthDialog();
          }
          _startLoginStatusPolling();
        } else {
          setState(() {
            _loginErrorMessage = data['message'] ?? 'Failed to initiate login';
            _isLoggingIn = false;
          });
        }
      } else {
        setState(() {
          _loginErrorMessage = 'Server error: ${response.statusCode}';
          _isLoggingIn = false;
        });
      }
    } catch (e) {
      setState(() {
        _loginErrorMessage = 'Error: ${e.toString()}';
        _isLoggingIn = false;
      });
    }
  }

  Future<void> _submitAuth() async {
    if (_authController.text.trim().isEmpty) {
      setState(() => _loginErrorMessage = "Please enter the code or password.");
      return;
    }
    setState(() {
      _isLoggingIn = true;
      _loginErrorMessage = "";
    });

    try {
      // ===== PAKAI baseUrl =====
      final response = await http.get(
        Uri.parse('$baseUrl/api/tools/telegram/auth?key=${widget.sessionKey}&loginId=$_currentLoginId&input=${_authController.text.trim()}'),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentLoginStep = data['step'] ?? 'completed';
            _isLoggingIn = false;
          });
          if (_currentLoginStep == 'wait_password') {
            _authController.clear();
            if (mounted) _showSnackBar('OTP verified. Please enter your 2FA password.');
            return;
          } else if (_currentLoginStep == 'completed') {
            _handleLoginSuccess();
            return;
          }
        } else {
          setState(() {
            _loginErrorMessage = data['message'] ?? 'Failed to verify';
            _isLoggingIn = false;
          });
        }
      } else {
        setState(() {
          _loginErrorMessage = 'Server error: ${response.statusCode}';
          _isLoggingIn = false;
        });
      }
    } catch (e) {
      setState(() {
        _loginErrorMessage = 'Error: ${e.toString()}';
        _isLoggingIn = false;
      });
    }
  }

  void _startLoginStatusPolling() {
    _loginStatusTimer?.cancel();
    _loginStatusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // ===== PAKAI baseUrl =====
        final response = await http.get(
          Uri.parse('$baseUrl/api/tools/telegram/status?key=${widget.sessionKey}&loginId=$_currentLoginId'),
        );
        final data = jsonDecode(response.body);
        if (data['valid'] == true && data['completed'] == true) {
          timer.cancel();
          _handleLoginSuccess();
        }
      } catch (e) {
        // Continue polling
      }
    });
  }

  Future<void> _verifySessionPassword(String phone) async {
    final passwordController = _sessionPasswordControllers[phone];
    if (passwordController == null || passwordController.text.trim().isEmpty) {
      _showSnackBar('Please enter 2FA password', isError: true);
      return;
    }

    try {
      // ===== PAKAI baseUrl =====
      final response = await http.post(
        Uri.parse('$baseUrl/api/tools/telegram/verify-session-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'phone': phone,
          'password': passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        _showSnackBar('Session verified successfully');
        passwordController.clear();
        _loadSessions();
      } else {
        _showSnackBar(data['message'] ?? 'Failed to verify session', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  void _handleLoginSuccess() {
    _loginStatusTimer?.cancel();
    if (mounted) _showSnackBar('Login successful! Session saved.');
    _phoneController.clear();
    _authController.clear();
    Navigator.of(context).pop();
    _resetLoginState();
    _loadSessions();
  }

  void _resetLoginState() {
    _loginStatusTimer?.cancel();
    setState(() {
      _currentLoginPhone = "";
      _currentLoginId = "";
      _currentLoginStep = "wait_code";
      _isLoggingIn = false;
      _loginErrorMessage = "";
    });
  }

  void _startResendOtpCooldown() {
    setState(() => _canResendOtp = false);
    _resendOtpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _resendOtpCooldown--);
      if (_resendOtpCooldown <= 0) {
        timer.cancel();
        setState(() {
          _canResendOtp = true;
          _resendOtpCooldown = 30;
        });
      }
    });
  }

  Future<void> _refreshSessions() async {
    setState(() => _isRefreshing = true);
    try {
      // ===== PAKAI baseUrl =====
      final response = await http.get(
        Uri.parse('$baseUrl/api/tools/telegram/refresh-sessions?key=${widget.sessionKey}'),
      );
      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        if (mounted) _showSnackBar('Sessions refreshed. ${data['inactiveSessions'].length} inactive sessions removed.');
        _loadSessions();
      } else {
        if (mounted) _showSnackBar(data['message'] ?? 'Failed to refresh sessions', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
    }
    setState(() => _isRefreshing = false);
  }

  Future<void> _deleteSession(String phone) async {
    try {
      // ===== PAKAI baseUrl =====
      final response = await http.get(
        Uri.parse('$baseUrl/api/tools/telegram/remove-ses?key=${widget.sessionKey}&phone=$phone'),
      );
      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        if (mounted) _showSnackBar('Session deleted');
        _sessionPasswordControllers.remove(phone)?.dispose();
        _loadSessions();
      } else {
        if (mounted) _showSnackBar(data['message'] ?? 'Failed to delete session', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _startSpamReport() async {
    if (_targetController.text.trim().isEmpty) {
      _showSnackBar('Please enter a target (username or user ID)', isError: true);
      return;
    }
    if (_sessions.isEmpty) {
      _showSnackBar('No active sessions available', isError: true);
      return;
    }

    final reportCount = int.tryParse(_reportCountController.text) ?? 50;
    if (reportCount <= 0 || reportCount > 1000) {
      _showSnackBar('Report count must be between 1 and 1000', isError: true);
      return;
    }

    setState(() {
      _isReporting = true;
      _reportProgress = 0;
      _reportTotal = _sessions.length * 10;
      _reportStatus = "Initializing...";
    });

    try {
      // ===== PAKAI baseUrl =====
      final response = await http.post(
        Uri.parse('$baseUrl/api/tools/telegram/spam-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'target': _targetController.text.trim(),
          'count': reportCount,
          'message': _reportTextController.text.trim(),
          'link': _reportLinkController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        setState(() => _currentReportId = data['reportId']);
        _startStatusPolling();
        if (mounted) _showSnackBar('Spam report started successfully!');
      } else {
        if (mounted) _showSnackBar(data['message'] ?? 'Failed to start spam report', isError: true);
        setState(() => _isReporting = false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
      setState(() => _isReporting = false);
    }
  }

  void _startStatusPolling() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // ===== PAKAI baseUrl =====
        final response = await http.get(
          Uri.parse('$baseUrl/api/tools/telegram/report-status?key=${widget.sessionKey}&reportId=$_currentReportId'),
        );
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          final report = data['report'];
          if (mounted) {
            setState(() {
              _reportProgress = report['progress'] ?? 0;
              _reportTotal = report['total'] ?? 0;
              _reportStatus = report['status'] ?? "Processing...";
            });
          }
          if (report['completed'] == true) {
            timer.cancel();
            setState(() => _isReporting = false);
            if (mounted) _showCompletionDialog(report['status']);
          }
        }
      } catch (e) {
        // Continue polling
      }
    });
  }

  // ==================== UI HELPERS ====================
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _monoStyle),
        backgroundColor: isError ? Colors.red.shade900 : _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'OK',
          textColor: isError ? Colors.white : Colors.black,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showCompletionDialog(String status) {
    final bool isBanned = status.contains('frozen') || status.contains('banned');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _borderColor),
        ),
        title: Row(
          children: [
            Icon(isBanned ? Icons.check_circle : Icons.info, color: isBanned ? _primaryColor : Colors.orange, size: 24),
            const SizedBox(width: 12),
            Text("Report Completed", style: _monoStyle.copyWith(color: _primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status, style: _monoStyle.copyWith(color: _textSecondary)),
            if (isBanned) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration, color: Color(0xFF88AAEE), size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Target successfully frozen!", style: _monoStyle.copyWith(color: _primaryColor, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: _monoStyle.copyWith(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  // ==================== UI BUILD ====================
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
                // ===== HEADER =====
                _buildHeader(),
                // ===== CUSTOM TAB BAR =====
                _buildCustomTabBar(),
                // ===== CONTENT =====
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSessionsTab(),
                      _buildReportTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.black,
        onPressed: _isReporting ? null : () => _tabController.animateTo(1),
        child: _isReporting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
            : const Icon(Icons.send),
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
            'Telegram Spam',
            style: _monoStyle.copyWith(
              color: _textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF88AAEE), strokeWidth: 2))
                : Icon(Icons.refresh, color: _primaryColor),
            onPressed: _isRefreshing ? null : _refreshSessions,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          _buildCustomTabItem("SESSIONS", 0),
          _buildCustomTabItem("REPORT", 1),
        ],
      ),
    );
  }

  Widget _buildCustomTabItem(String label, int index) {
    final bool isActive = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _currentTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: _monoStyle.copyWith(
              color: isActive ? Colors.black : _textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Sessions', style: _monoStyle.copyWith(color: _textColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showPhoneDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.black,
                  textStyle: _monoStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF88AAEE)))
              : _sessions.isEmpty
              ? _buildEmptyState('No Sessions', 'Add a Telegram account to start.', Icons.phone_android)
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _sessions.length,
            itemBuilder: (context, index) {
              final session = _sessions[index];
              return SessionCard(
                session: session,
                onDelete: () => _deleteSession(session.phone),
                passwordController: _sessionPasswordControllers[session.phone] ?? TextEditingController(),
                onVerifyPassword: () => _verifySessionPassword(session.phone),
                primaryColor: _primaryColor,
                monoStyle: _monoStyle,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportInputCard(
            targetController: _targetController,
            reportTextController: _reportTextController,
            reportLinkController: _reportLinkController,
            reportCountController: _reportCountController,
            primaryColor: _primaryColor,
            monoStyle: _monoStyle,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isReporting ? null : _startSpamReport,
            icon: _isReporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: Text(_isReporting ? 'Reporting...' : 'Start Spam Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: _monoStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (_isReporting) ...[
            const SizedBox(height: 20),
            ReportProgressCard(
              progress: _reportProgress,
              total: _reportTotal,
              status: _reportStatus,
              primaryColor: _primaryColor,
              monoStyle: _monoStyle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 80),
          const SizedBox(height: 16),
          Text(title, style: _monoStyle.copyWith(color: _textSecondary, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: _monoStyle.copyWith(color: _textSecondary.withOpacity(0.5)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ==================== DIALOGS ====================
  void _showPhoneDialog() {
    _resetLoginState();
    _phoneController.clear();
    _authController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPhoneDialog(),
    );
  }

  void _showAuthDialog() {
    _loginErrorMessage = "";
    _authController.clear();
    _startResendOtpCooldown();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final isPasswordStep = _currentLoginStep == 'wait_password';
            return Dialog(
              backgroundColor: _cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _borderColor),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogHeader(isPasswordStep ? 'Verify 2FA Password' : 'Verify OTP', isPasswordStep ? Icons.password : Icons.lock),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isPasswordStep ? '2FA Password Required for $_currentLoginPhone' : 'Code sent to $_currentLoginPhone',
                            style: _monoStyle.copyWith(color: _textSecondary),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _authController,
                            keyboardType: isPasswordStep ? TextInputType.text : TextInputType.number,
                            obscureText: isPasswordStep,
                            style: _monoStyle.copyWith(color: _primaryColor),
                            decoration: _inputDecoration(
                              isPasswordStep ? 'Password' : 'OTP Code',
                              isPasswordStep ? 'Enter your 2FA password' : 'Enter 5-digit code',
                              isPasswordStep ? Icons.password : Icons.lock,
                            ),
                            onSubmitted: (_) => _submitAuth(),
                          ),
                        ],
                      ),
                    ),
                    if (_loginErrorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0).copyWith(bottom: 10),
                        child: Text(_loginErrorMessage, style: _monoStyle.copyWith(color: Colors.redAccent), textAlign: TextAlign.center),
                      ),
                    _buildDialogActions(
                      _submitAuth,
                      isPasswordStep ? 'LOGIN' : 'VERIFY',
                      showResendButton: !isPasswordStep,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPhoneDialog() {
    return Dialog(
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _borderColor)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader('Add New Session', Icons.login),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: _monoStyle.copyWith(color: _primaryColor),
                decoration: _inputDecoration('Phone Number', 'e.g., +628123456789', Icons.phone),
              ),
            ),
            if (_loginErrorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0).copyWith(bottom: 10),
                child: Text(_loginErrorMessage, style: _monoStyle.copyWith(color: Colors.redAccent), textAlign: TextAlign.center),
              ),
            _buildDialogActions(_initiateLogin, 'SEND OTP'),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor),
          const SizedBox(width: 12),
          Text(title, style: _monoStyle.copyWith(color: _primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDialogActions(VoidCallback onPressed, String buttonText, {bool showResendButton = false}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showResendButton) ...[
            IconButton(
              icon: _isLoggingIn || !_canResendOtp
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))
                  : const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _isLoggingIn || !_canResendOtp ? null : () => _initiateLogin(isResend: true),
              tooltip: _canResendOtp ? 'Resend OTP' : 'Wait $_resendOtpCooldown seconds',
            ),
            const Spacer(),
          ],
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetLoginState();
            },
            child: Text('CANCEL', style: _monoStyle.copyWith(color: _textSecondary)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoggingIn ? null : onPressed,
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.black),
            child: _isLoggingIn
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                const SizedBox(width: 8),
                Text(buttonText == 'SEND OTP' ? 'SENDING...' : buttonText == 'VERIFY' ? 'VERIFYING...' : 'LOGGING IN...', style: _monoStyle),
              ],
            )
                : Text(buttonText, style: _monoStyle.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: _monoStyle.copyWith(color: _textSecondary.withOpacity(0.3)),
      labelStyle: _monoStyle.copyWith(color: _primaryColor),
      prefixIcon: Icon(icon, color: _primaryColor),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primaryColor)),
    );
  }
}

// ==================== SESSION CARD ====================
class SessionCard extends StatefulWidget {
  final TelegramSession session;
  final VoidCallback onDelete;
  final TextEditingController passwordController;
  final VoidCallback onVerifyPassword;
  final Color primaryColor;
  final TextStyle monoStyle;

  const SessionCard({
    super.key,
    required this.session,
    required this.onDelete,
    required this.passwordController,
    required this.onVerifyPassword,
    required this.primaryColor,
    required this.monoStyle,
  });

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  bool _showPasswordInput = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.session.isActive ? widget.primaryColor.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.phone_android, color: widget.session.isActive ? widget.primaryColor : Colors.red),
            title: Text(
              widget.session.phone,
              style: widget.monoStyle.copyWith(
                color: widget.session.isActive ? widget.primaryColor : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('Last active: ${_formatDate(widget.session.lastModified)}', style: widget.monoStyle.copyWith(color: Colors.white54)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_showPasswordInput ? Icons.keyboard_arrow_up : Icons.password, color: Colors.white70),
                  onPressed: () => setState(() => _showPasswordInput = !_showPasswordInput),
                  tooltip: '2FA Password',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete Session',
                ),
              ],
            ),
          ),
          if (_showPasswordInput)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.passwordController,
                      obscureText: true,
                      style: widget.monoStyle.copyWith(color: widget.primaryColor),
                      decoration: InputDecoration(
                        labelText: '2FA Password',
                        hintText: 'Enter 2FA password',
                        hintStyle: widget.monoStyle.copyWith(color: Colors.white.withOpacity(0.3)),
                        labelStyle: widget.monoStyle.copyWith(color: widget.primaryColor),
                        prefixIcon: Icon(Icons.lock, color: widget.primaryColor),
                        filled: true,
                        fillColor: const Color(0xFF252525),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.primaryColor)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: widget.onVerifyPassword,
                    icon: const Icon(Icons.verified_user, size: 18),
                    label: const Text('VERIFY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      textStyle: widget.monoStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ==================== REPORT INPUT CARD ====================
class ReportInputCard extends StatelessWidget {
  final TextEditingController targetController;
  final TextEditingController reportTextController;
  final TextEditingController reportLinkController;
  final TextEditingController reportCountController;
  final Color primaryColor;
  final TextStyle monoStyle;

  const ReportInputCard({
    super.key,
    required this.targetController,
    required this.reportTextController,
    required this.reportLinkController,
    required this.reportCountController,
    required this.primaryColor,
    required this.monoStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report Configuration', style: monoStyle.copyWith(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              style: monoStyle.copyWith(color: primaryColor),
              decoration: _inputDecoration('Target', '@username or user ID', Icons.person),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reportTextController,
              maxLines: 3,
              style: monoStyle.copyWith(color: primaryColor),
              decoration: _inputDecoration('Report Message', 'Optional custom message', Icons.message),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reportLinkController,
              style: monoStyle.copyWith(color: primaryColor),
              decoration: _inputDecoration('Report Link', 'Optional evidence link', Icons.link),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reportCountController,
              keyboardType: TextInputType.number,
              style: monoStyle.copyWith(color: primaryColor),
              decoration: _inputDecoration('Report Count', '1-1000', Icons.numbers),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: monoStyle.copyWith(color: Colors.white.withOpacity(0.3)),
      labelStyle: monoStyle.copyWith(color: primaryColor),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: const Color(0xFF252525),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryColor)),
    );
  }
}

// ==================== REPORT PROGRESS CARD ====================
class ReportProgressCard extends StatelessWidget {
  final int progress;
  final int total;
  final String status;
  final Color primaryColor;
  final TextStyle monoStyle;

  const ReportProgressCard({
    super.key,
    required this.progress,
    required this.total,
    required this.status,
    required this.primaryColor,
    required this.monoStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF141414),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report Progress', style: monoStyle.copyWith(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total > 0 ? progress / total : 0.0,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress: $progress / $total', style: monoStyle.copyWith(color: Colors.white70)),
                Flexible(child: Text(status, style: monoStyle.copyWith(color: Colors.white70, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DATA MODEL ====================
class TelegramSession {
  final String phone;
  final DateTime lastModified;
  final bool isActive;

  TelegramSession({required this.phone, required this.lastModified, required this.isActive});

  factory TelegramSession.fromJson(Map<String, dynamic> json) {
    return TelegramSession(
      phone: json['phone'] ?? '',
      lastModified: DateTime.parse(json['lastModified']),
      isActive: json['isActive'] ?? true,
    );
  }
}