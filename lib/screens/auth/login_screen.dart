import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/device_provider.dart';
import '../../models/user_role.dart';
import '../main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _clientSecretController = TextEditingController();

  bool _isSending = false;
  bool _isVerifying = false;
  bool _otpSent = false;
  bool _isApiLoggingIn = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() => _isSending = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      String rawPhone = _phoneController.text.trim();
      String formattedPhone = rawPhone.startsWith('+') ? rawPhone : '+$rawPhone';
      await auth.requestOtp(formattedPhone);
      if (!mounted) return;
      setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _verifyOtp() async {
    setState(() => _isVerifying = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      String rawPhone = _phoneController.text.trim();
      String formattedPhone = rawPhone.startsWith('+') ? rawPhone : '+$rawPhone';
      await auth.verifyOtp(formattedPhone, _otpController.text.trim());
      if (!mounted) return;
      if (auth.isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying OTP: $e')),
        );
      }
    }
    if (mounted) setState(() => _isVerifying = false);
  }

  Future<void> _apiLogin() async {
    setState(() => _isApiLoggingIn = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    
    final error = await auth.loginWithApi(
      _clientIdController.text.trim(),
      _clientSecretController.text.trim(),
      UserRole.resident,
      propertyProvider: propertyProvider,
      deviceProvider: deviceProvider,
      customerEmail: 'admin@smarthomez.com',
    );

    if (!mounted) return;
    
    if (error == null && auth.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Login failed')),
      );
    }
    if (mounted) setState(() => _isApiLoggingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Phone OTP', icon: Icon(Icons.phone_android)),
              Tab(text: 'Client API', icon: Icon(Icons.api)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPhoneTab(),
            _buildApiTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('phone_input'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),
          if (_otpSent) ...[
            TextField(
              key: const Key('otp_input'),
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'OTP',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            key: const Key('action_button'),
            onPressed: _isSending || _isVerifying ? null : (_otpSent ? _verifyOtp : _sendOtp),
            child: Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
          ),
          if (_isSending || _isVerifying)
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildApiTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('client_id_input'),
              controller: _clientIdController,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('client_secret_input'),
              controller: _clientSecretController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Secret Code',
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('api_login_button'),
              onPressed: _isApiLoggingIn ? null : _apiLogin,
              child: const Text('Login with Client API'),
            ),
            if (_isApiLoggingIn)
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
