import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'main.dart'; // for MyHomePage

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _serverUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _storageService = StorageService();

  bool _obscureToken = true;
  String? _urlError;
  String? _tokenError;

  bool _validate() {
    String url = _serverUrlController.text.trim();
    String token = _tokenController.text.trim();
    bool ok = true;

    setState(() {
      if (url.isEmpty) {
        _urlError = 'Server URL is required';
        ok = false;
      } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
        _urlError = 'Must start with http:// or https://';
        ok = false;
      } else {
        _urlError = null;
      }

      if (token.isEmpty) {
        _tokenError = 'Token is required';
        ok = false;
      } else {
        _tokenError = null;
      }
    });

    return ok;
  }

  Future<void> _handleConnect() async {
    if (!_validate()) return;

    String deviceName = _defaultDeviceName();

    await _storageService.saveCredentials(
      _serverUrlController.text.trim(),
      _tokenController.text.trim(),
    );
    await _storageService.saveDeviceName(deviceName);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Shared Inbox')),
    );
  }

  String _defaultDeviceName() {
    // Placeholder for now — we'll wire real Platform detection next.
    return 'My Device';
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4A7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.content_paste, color: Colors.black),
              ),
              const SizedBox(height: 12),
              const Text(
                'ClipSync',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect to your sync server to get started',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 32),

              // Form card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[850]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLabel('SERVER URL'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _serverUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'https://sync.example.com',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(Icons.link, size: 16, color: Colors.grey[500]),
                        errorText: _urlError,
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('TOKEN'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tokenController,
                      obscureText: _obscureToken,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: '••••••••••••••••',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(Icons.key, size: 16, color: Colors.grey[500]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureToken ? Icons.visibility : Icons.visibility_off,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureToken = !_obscureToken;
                            });
                          },
                        ),
                        errorText: _tokenError,
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _handleConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DD4A7),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your credentials are stored locally and never shared.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}