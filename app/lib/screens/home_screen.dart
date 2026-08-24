import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_formatter.dart';
import '../widgets/device_popup_menu.dart';
import '../widgets/inbox_card.dart';
import '../widgets/message_input.dart';
import 'setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.title,
    required this.onLocaleChange,
  });

  final String title;
  final void Function(Locale?) onLocaleChange;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _serverUrl;
  String? _token;
  String? _deviceName;
  bool _isSending = false;
  bool _isLoading = false;
  DateTime? _lastSynced;
  final _textController = TextEditingController();
  final List<Map<String, String>> _items = [];
  Timer? _refreshTimer;
  ApiService? _apiService;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final storageService = StorageService();
    final serverUrl = await storageService.getServerUrl();
    final token = await storageService.getToken();
    final deviceName = await storageService.getDeviceName();

    setState(() {
      _serverUrl = serverUrl;
      _token = token;
      _deviceName = deviceName;
    });

    _apiService = ApiService(serverUrl: _serverUrl!, token: _token!);
    await _fetchItems();
  }

  Future<void> _fetchItems() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService!.fetchItems();
      setState(() {
        _items
          ..clear()
          ..addAll(
            data.map(
              (item) => {
                'id': item['id'].toString(),
                'content': item['content'] as String,
                'device_name': item['device_name'] as String,
                'created_at': item['created_at'] as String,
              },
            ),
          );
        _lastSynced = DateTime.now().toUtc();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            l10n.failedToLoad,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendItem() async {
    final l10n = AppLocalizations.of(context)!;
    final input = _textController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _apiService!.sendItem(input, _deviceName ?? l10n.defaultDeviceName);
      _textController.clear();
      await _fetchItems();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(
            l10n.failedToSend,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _handleRename(String newName) {
    setState(() => _deviceName = newName);
    StorageService().saveDeviceName(newName);
  }

  Future<void> _handleReset() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await StorageService().clearAll();
    if (!mounted) return;

    messenger.showSnackBar(SnackBar(content: Text(l10n.resetSetupSuccess)));
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) =>
            SetupScreen(onLocaleChange: widget.onLocaleChange),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deviceName = _deviceName ?? l10n.defaultDeviceName;
    final deviceColor = AppColors.forDevice(deviceName);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.content_paste_rounded,
                color: Colors.black,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _isLoading
                        ? l10n.syncing
                        : (_lastSynced != null
                              ? l10n.lastSynced(
                                  formatTimestamp(context, _lastSynced!),
                                )
                              : l10n.notSyncedYet),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DevicePopupMenu(
              deviceName: deviceName,
              onRename: _handleRename,
              onLocaleChange: widget.onLocaleChange,
              onReset: _handleReset,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _fetchItems,
                child: _isLoading && _items.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _items.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                l10n.emptyStateMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Dismissible(
                            key: Key(item['id']!),
                            direction: DismissDirection
                                .endToStart, // swipe right-to-left only
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      title: Text(
                                        l10n.deleteConfirmTitle,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      content: Text(
                                        l10n.deleteConfirmMessage,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(
                                            l10n.cancel,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(
                                            l10n.delete,
                                            style: const TextStyle(
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            onDismissed: (direction) {
                              final itemId = item['id']!;
                              final removedItem = item;

                              setState(() {
                                _items.removeWhere((i) => i['id'] == itemId);
                              });

                              _apiService!
                                  .deleteItem(int.parse(itemId))
                                  .catchError((e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.failedToDelete),
                                      ),
                                    );
                                    setState(() {
                                      _items.insert(index, removedItem); // put it back if the delete failed
                                    });
                                  });
                            },
                            child: InboxCard(item: item),
                          );
                        },
                      ),
              ),
            ),
            MessageInput(
              controller: _textController,
              deviceName: deviceName,
              deviceColor: deviceColor,
              isSending: _isSending,
              onSend: _sendItem,
              hintText: l10n.sendHint,
            ),
          ],
        ),
      ),
    );
  }
}
