import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/qr_scan_screen.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

import 'dart:io';
import 'dart:convert';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onLocaleChange});

  final void Function(Locale?) onLocaleChange;

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
    final l10n = AppLocalizations.of(context)!;
    String url = _serverUrlController.text.trim();
    String token = _tokenController.text.trim();
    bool ok = true;

    setState(() {
      if (url.isEmpty) {
        _urlError = l10n.noUrlError;
        ok = false;
      } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
        _urlError = l10n.noHttpError;
        ok = false;
      } else {
        _urlError = null;
      }

      if (token.isEmpty) {
        _tokenError = l10n.noTokenError;
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
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          title: 'ClipSync',
          onLocaleChange: widget.onLocaleChange,
        ),
      ),
    );
  }

  String _defaultDeviceName() {
    final l10n = AppLocalizations.of(context)!;
    String platformName = Platform.operatingSystem;
    String capitalized =
        platformName[0].toUpperCase() + platformName.substring(1);
    return l10n.defaultDeviceNamePattern(capitalized);
  }

  Future<void> _handleScanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScanScreen()),
    );

    if (result == null) return; // user backed out without scanning

    try {
      final decoded = jsonDecode(result) as Map<String, dynamic>;
      final serverUrl = decoded['serverUrl'] as String;
      final code = decoded['code'] as String;

      final redeemResult = await redeemPairingCode(serverUrl, code);

      String deviceName = _defaultDeviceName();
      await _storageService.saveCredentials(
        redeemResult['server_url']!,
        redeemResult['token']!,
      );
      await _storageService.saveDeviceName(deviceName);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            title: 'ClipSync',
            onLocaleChange: widget.onLocaleChange,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToRedeemCode),
        ),
      );
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.content_paste, color: Colors.black),
              ),
              const SizedBox(height: 12),
              const Text(
                'ClipSync',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.welcomeMessage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLabel(l10n.serverUrl),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _serverUrlController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'https://sync.example.com',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.link,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        errorText: _urlError,
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel(l10n.token),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tokenController,
                      obscureText: _obscureToken,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••••••••••',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.key,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureToken
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() => _obscureToken = !_obscureToken);
                          },
                        ),
                        errorText: _tokenError,
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.connect,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _handleScanQr,
                      child: Text(
                        l10n.scanQrInstead,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.credentialsInfo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
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
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}
