import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dart:async';

import 'l10n/app_localizations.dart';

import 'utils/time_formatter.dart';
import 'services/api_service.dart';
import 'storage_service.dart';
import 'setup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final saved = await StorageService().getLanguage();
    if (saved != null) {
      setState(() {
        _locale = Locale(saved);
      });
    }
  }

  void _changeLocale(Locale? locale) async {
    setState(() {
      _locale = locale;
    });
    await StorageService().saveLanguage(locale?.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClipSync',
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('pl')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 32, 27, 52),
        ),
      ),
      home: FutureBuilder<String?>(
        future: StorageService().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == null) {
            return SetupScreen(onLocaleChange: _changeLocale);
          }
          return MyHomePage(title: 'ClipSync', onLocaleChange: _changeLocale);
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.onLocaleChange,
  });

  final String title;
  final void Function(Locale?) onLocaleChange;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _serverUrl;
  String? _token;
  String? _deviceName;
  bool _isSending = false;
  final _textController = TextEditingController();
  final List<Map<String, String>> _items = [];
  Timer? _refreshTimer;
  ApiService? _apiService;
  DateTime? _lastSynced;
  bool _isLoading = false;

  Future<void> _fetchItems() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _apiService!.fetchItems();
      setState(() {
        _items.clear();
        _items.addAll(
          data.map(
            (item) => {
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.failedToLoad)));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendItem() async {
    final l10n = AppLocalizations.of(context)!;
    final input = _textController.text;
    if (input.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _apiService!.sendItem(input, _deviceName ?? l10n.defaultDeviceName);
      _textController.clear();
      await _fetchItems();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.failedToSend)));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Color _colorForDevice(String deviceName) {
    const colors = {
      'PC': Colors.cyanAccent,
      'Phone': Colors.deepPurpleAccent,
      'Laptop': Colors.greenAccent,
      'Web': Colors.orangeAccent,
    };
    return colors[deviceName] ?? Colors.grey;
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

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {}); // no data changes, just forces a rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 32, 27, 52),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 150),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'rename') {
                  final renameController = TextEditingController(
                    text: _deviceName,
                  );
                  String? renameError; // moved outside the builder
                  showDialog(
                    context: context,
                    builder: (context) => StatefulBuilder(
                      builder: (context, setDialogState) {
                        return AlertDialog(
                          title: Text(l10n.renameDeviceTitle),
                          content: TextField(
                            controller: renameController,
                            decoration: InputDecoration(
                              hintText: l10n.renameDeviceHint,
                              errorText: renameError,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () {
                                final newName = renameController.text.trim();
                                if (newName.isEmpty) {
                                  setDialogState(() {
                                    renameError = l10n.emptyDeviceNameError;
                                  });
                                  return;
                                }
                                setState(() {
                                  _deviceName = newName;
                                });
                                StorageService().saveDeviceName(newName);
                                Navigator.pop(context);
                              },
                              child: Text(l10n.save),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                } else if (value == 'language') {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: Text(l10n.chooseLanguage),
                      children: [
                        SimpleDialogOption(
                          onPressed: () {
                            widget.onLocaleChange(null);
                            Navigator.pop(context);
                          },
                          child: Text(l10n.systemDefault),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            widget.onLocaleChange(const Locale('en'));
                            Navigator.pop(context);
                          },
                          child: const Text('English'),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            widget.onLocaleChange(const Locale('pl'));
                            Navigator.pop(context);
                          },
                          child: const Text('Polski'),
                        ),
                      ],
                    ),
                  );
                } else if (value == 'reset') {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final message = l10n.resetSetupSuccess;

                  await StorageService().clearAll();

                  if (!mounted) return;

                  messenger.showSnackBar(SnackBar(content: Text(message)));
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) =>
                          SetupScreen(onLocaleChange: widget.onLocaleChange),
                    ),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Text(l10n.renameDeviceTitle),
                ),
                PopupMenuItem(
                  value: 'language',
                  child: Text(l10n.chooseLanguage),
                ),
                PopupMenuItem(value: 'reset', child: Text(l10n.resetSetup)),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _deviceName ?? l10n.defaultDeviceName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _fetchItems();
              },
              child: _isLoading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? Center(
                      child: Text(
                        l10n.emptyStateMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border(
                              left: BorderSide(
                                color: _colorForDevice(
                                  item['device_name'] ?? '',
                                ),
                                width: 4.0,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4.0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['device_name'] ?? '',
                                    style: TextStyle(
                                      color: _colorForDevice(
                                        item['device_name'] ?? '',
                                      ),
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  Text(
                                    formatTimestamp(
                                      context,
                                      DateTime.parse(item['created_at']!),
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                item['content'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.sendHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                    ),
                    controller: _textController,
                  ),
                ),
                IconButton(
                  onPressed: _isSending ? null : _sendItem,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }
}
