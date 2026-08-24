import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'dart:convert';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class DevicePopupMenu extends StatelessWidget {
  const DevicePopupMenu({
    super.key,
    required this.deviceName,
    required this.onRename,
    required this.onLocaleChange,
    required this.onReset,
    required this.apiService,
  });

  final String deviceName;
  final ValueChanged<String> onRename;
  final ValueChanged<Locale?> onLocaleChange;
  final VoidCallback onReset;
  final ApiService? apiService;

  Future<void> _showRenameDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: deviceName);
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.renameDeviceTitle,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.renameDeviceHint,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                errorText: error,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  final newName = controller.text.trim();
                  if (newName.isEmpty) {
                    setDialogState(() => error = l10n.emptyDeviceNameError);
                    return;
                  }
                  onRename(newName);
                  Navigator.pop(context);
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.chooseLanguage,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () {
              onLocaleChange(null);
              Navigator.pop(context);
            },
            child: Text(
              l10n.systemDefault,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              onLocaleChange(const Locale('en'));
              Navigator.pop(context);
            },
            child: const Text(
              'English',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              onLocaleChange(const Locale('pl'));
              Navigator.pop(context);
            },
            child: const Text(
              'Polski',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showQrDialog(
    BuildContext context,
    ApiService apiService,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final code = await apiService.createPairingCode();
      final qrData = jsonEncode({
        'serverUrl': apiService.serverUrl,
        'code': code,
      });
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n.pairYourDevice,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.surface,
          content: SizedBox(
            width: 250,
            height: 250,
            child: QrImageView(data: qrData, backgroundColor: Colors.white),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            l10n.failedToGenerateQrCode,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) {
        if (value == 'rename') {
          _showRenameDialog(context);
        } else if (value == 'qr' && apiService != null) {
          _showQrDialog(context, apiService!);
        } else if (value == 'language') {
          _showLanguageDialog(context);
        } else if (value == 'reset') {
          onReset();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'rename', child: Text(l10n.renameDeviceTitle)),
        PopupMenuItem(value: 'language', child: Text(l10n.chooseLanguage)),
        if (apiService != null)
          PopupMenuItem(value: 'qr', child: Text(l10n.showQrCode)),
        PopupMenuItem(
          value: 'reset',
          child: Text(
            l10n.resetSetup,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            deviceName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Icon(
            Icons.expand_more_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
