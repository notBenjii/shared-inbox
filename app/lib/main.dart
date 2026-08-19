import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';
import 'setup_screen.dart';

import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Inbox',
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
            return const SetupScreen();
          }
          return const MyHomePage(title: 'Shared Inbox');
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

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

  Future<void> _fetchItems() async {
    final response = await http.get(
      Uri.parse('$_serverUrl/items'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
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
      });
    } else {
      // TODO: Handle error
      print('Failed to load items');
    }
  }

  Future<void> _sendItem() async {
    final input = _textController.text;
    if (input.isEmpty) {
      return;
    }
    _textController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/items'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': input, 'device_name': _deviceName}),
      );
      if (response.statusCode == 201) {
        await _fetchItems();
      } else {
        print('Failed to send item');
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  String _formatTimestamp(String isoString) {
    final itemDate = DateTime.parse(isoString);
    final now = DateTime.now().toUtc();

    // Normalize both to midnight, so we're comparing calendar days, not elapsed hours
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(itemDate.year, itemDate.month, itemDate.day);
    final dayDifference = today.difference(itemDay).inDays;

    if (dayDifference == 0) {
      // Same calendar day — use minute/hour logic
      final elapsed = now.difference(itemDate);
      if (elapsed.inMinutes < 1) {
        return 'just now';
      } else if (elapsed.inMinutes < 60) {
        return '${elapsed.inMinutes}m ago';
      } else {
        return '${elapsed.inHours}h ago';
      }
    } else if (dayDifference == 1) {
      return 'Yesterday';
    } else {
      return '${itemDate.day}/${itemDate.month}/${itemDate.year}';
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
    final serverUrl = await StorageService().getServerUrl();
    final token = await StorageService().getToken();
    final deviceName = await StorageService().getDeviceName();

    setState(() {
      _serverUrl = serverUrl;
      _token = token;
      _deviceName = deviceName ?? 'Device Name';
    });

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
                  'Last synced: 10 minutes ago',
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
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Rename device'),
                      content: TextField(
                        controller: renameController,
                        decoration: const InputDecoration(
                          hintText: 'New device name',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _deviceName = renameController.text;
                            });
                            StorageService().saveDeviceName(
                              renameController.text,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                } else if (value == 'reset') {
                  await StorageService().clearAll();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetupScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename device'),
                ),
                const PopupMenuItem(value: 'reset', child: Text('Reset setup')),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _deviceName ?? 'Device Name',
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
              child: ListView.builder(
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
                          color: _colorForDevice(item['device_name'] ?? ''),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              _formatTimestamp(item['created_at'] ?? ''),
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
                      hintText: 'Paste or type something...',
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
