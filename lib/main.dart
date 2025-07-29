import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

void main() => runApp(const DuolingoProApp());

class DuolingoProApp extends StatelessWidget {
  const DuolingoProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duolingo PRO',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  String userId = '';
  String pingStatus = '尚未連線';
  Timer? pingTimer;
  final String apiUrl = 'https://api.duolingopro.net';
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => isActive = state == AppLifecycleState.resumed);
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    if (userId.isNotEmpty) _ping();
  }

  Future<void> _saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', id);
    setState(() => userId = id);
    _ping();
  }

  void _startPingLoop() {
    pingTimer?.cancel();
    pingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _ping());
  }

  Future<void> _ping() async {
    if (!isActive || userId.isEmpty) return;

    setState(() => pingStatus = '連線中...');
    setState(() => statusIcon = Icons.change_circle);
    final payload = jsonEncode({
      "version": "3.1 BETA.01",
      "key": _generateRandomKey(),
      "chat_key": "unknown",
    });

    try {
      final res = await http.post(
        Uri.parse('$apiUrl/server'),
        headers: {"Content-Type": "application/json"},
        body: payload,
      );

      if (res.statusCode == 200) {
        setState(() => pingStatus = '已連線');
        setState(() => statusIcon = Icons.check_circle);
        _startPingLoop();
      } else {
        setState(() => pingStatus = '錯誤 ${res.statusCode}');
        setState(() => statusIcon = Icons.cancel);
        Future.delayed(const Duration(seconds: 3), _ping);
      }
    } catch (e) {
      setState(() => pingStatus = '錯誤');
      setState(() => statusIcon = Icons.cancel);
      Future.delayed(const Duration(seconds: 3), _ping);
    }
  }

  String _generateRandomKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      16,
      (index) =>
          chars[(chars.length *
                  (index + DateTime.now().millisecond) %
                  chars.length) %
              chars.length],
    ).join();
  }

  void _showUserIdDialog() async {
    final controller = TextEditingController(text: userId);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('輸入 User ID'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) _saveUserId(result);
  }

  void _showAbout() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/logo.svg',
                  width: 48,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Duilingo Pro',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('版本 1.6.2'),
            const SizedBox(height: 8),
            const Text('SweetPotatoYee'),
          ],
        ),
      ),
    );
  }

  void _showNotificationDialog(Map<String, dynamic> notification) {
    String translate(String text) {
      final translations = {
        "You": "你",
        "redeemed": "兌換了",
        "redeem": "兌換",
        " can": "可以",
        " send": "傳送",
        "request": "請求",
        "every": "每",
        "Please wait before trying again": "請稍後再試",
        "Successfully Received": "成功獲得",
        "Successfully Redeemed": "成功兌換",
        "Successful": "成功",
        "Attempted to Give": "嘗試贈送",
        "Limit Warning": "限制警告",
        "Failed": "失敗",
        "You received": "你獲得了",
        "You can request up to": "你還可以請求",
        "before your limit resets back to": "，限制將在重置回",
        " in": "於",
        "To boost your limits": "要提高限制",
        "<a href='https://duolingopro.net/patreon' target='_blank' style='font-family: Duolingo Pro Rounded; text-decoration: underline; color: #007AFF;'>donate</a>":
            "請贊助",
        "again in": "在",
        " a ": "1",
        "however it may not have worked. Please refresh the page to confirm":
            "但可能未成功，請刷新頁面確認",
        "Streak Freezes": "連勝激凍",
        "Streak Freeze": "連勝激凍",
        "streak freezes": "連勝激凍",
        "streak freeze": "連勝激凍",
        "XP": "經驗值",
        "XP-Boost": "經驗值加成",
        "Heart Refill": "填滿紅心",
        "heart refill": "填滿紅心",
        "Streaks": "連勝",
        "Streak": "連勝",
        "streaks": "連勝",
        "streak": "連勝",
        "of": "的",
        "Gems": "寶石",
        "Gem": "寶石",
        "gems": "寶石",
        "gem": "寶石",
        "minute": "分鐘",
        "minutes": "分鐘",
        "hour": "小時",
        "hours": "小時",
        "second": "秒",
        "seconds": "秒",
        "day": "天",
        "days": "天",
        "and": "",
        ".": "。",
        ",": "，",
      };

      translations.entries.toList()
        ..sort((a, b) => b.key.length.compareTo(a.key.length))
        ..forEach((e) => text = text.replaceAll(e.key, e.value));

      return text;
    }

    final head = translate(notification['head'] ?? '訊息');
    final body = translate(notification['body'] ?? '');
    final icon = notification['icon'] ?? '';

    IconData materialIcon;
    switch (icon) {
      case 'checkmark':
        materialIcon = Icons.check_circle;
        break;
      case 'change':
        materialIcon = Icons.change_circle;
        break;
      case 'cancel':
        materialIcon = Icons.cancel;
        break;
      default:
        materialIcon = Icons.info_outline;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(materialIcon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(head)),
          ],
        ),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  void _showActionDialog(
    String title,
    String gainType, {
    bool requireInput = true,
    bool isGem = false,
  }) async {
    if (!mounted) return;
    final controller = TextEditingController();
    String? result;

if (requireInput) {
  result = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 限制只能輸入數字
        decoration: InputDecoration(
          hintText: '請輸入數字',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('送出'),
        ),
      ],
    ),
  );
} else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: const Text('確認送出請求？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('確認'),
            ),
          ],
        ),
      );
      if (confirmed == true) result = '1';
    }

    if (result != null && result.isNotEmpty) {
      ValueNotifier<int> percentage = ValueNotifier<int>(0);

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('處理中...'),
          content: ValueListenableBuilder<int>(
            valueListenable: percentage,
            builder: (_, value, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: value / 100),
                const SizedBox(height: 8),
                Text('$value%'),
              ],
            ),
          ),
        ),
      );

      final url = isGem ? '$apiUrl/gem' : '$apiUrl/request';
      final body = isGem
          ? {"amount": int.tryParse(result)}
          : {"gain_type": gainType, "amount": int.tryParse(result)};

      if (isGem) {
        try {
          final request = http.Request('POST', Uri.parse(url));
          request.headers.addAll({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $userId',
          });
          request.body = jsonEncode(body);

          final client = http.Client();
          final streamedRes = await client.send(request);

          final stream = streamedRes.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter());

          await for (final line in stream) {
            if (!mounted) break;
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;

            try {
              final data = jsonDecode(trimmed);
              debugPrint('📥 Gem Chunk: $data');

              final status = data['status'];
              if (status == 'completed') {
                if (mounted) Navigator.pop(context);
                _showNotificationDialog(data['notification']);
                break;
              } else if (status == 'failed' || status == 'rejected') {
                if (mounted) Navigator.pop(context);
                _showNotificationDialog(data['notification']);
                break;
              } else if (data['percentage'] != null) {
                percentage.value = data['percentage'];
              }
            } catch (e) {
              debugPrint('⚠️ JSON Decode failed: $e');
            }
          }

          client.close();
        } catch (e) {
          if (mounted) Navigator.pop(context);
          _showNotificationDialog({"head": "發送失敗", "body": e.toString()});
          debugPrint('❌ Error during gem request: $e');
        }
      } else {
        try {
          final res = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $userId',
            },
            body: jsonEncode(body),
          );

          if (!mounted) return;

          final data = jsonDecode(res.body);
          final status = data['status'];

          if (status == true) {
            if (mounted) Navigator.pop(context);
            _showNotificationDialog(data['notification']);
          } else {
            if (mounted) Navigator.pop(context);
            _showNotificationDialog(data['notification']);
          }
        } catch (e) {
          if (mounted) Navigator.pop(context);
          _showNotificationDialog({"head": "發送失敗", "body": e.toString()});
          debugPrint('❌ Error during request: $e');
        }
      }
    }
  }

  IconData statusIcon = Icons.cancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duolingo PRO'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/icon.png'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _showUserIdDialog,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAbout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(pingStatus, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () => _showActionDialog('請求經驗值', 'xp'),
                    child: const Text('取得 XP'),
                  ),
                  ElevatedButton(
                    onPressed: () => _showActionDialog('請求寶石', '', isGem: true),
                    child: const Text('取得 Gems'),
                  ),
                  ElevatedButton(
                    onPressed: () => _showActionDialog(
                      '請求 Duolingo Super 3 天試用',
                      'super',
                      requireInput: false,
                    ),
                    child: const Text('取得 Super'),
                  ),
                  ElevatedButton(
                    onPressed: () => _showActionDialog(
                      '取得經驗值加成',
                      'double_xp_boost',
                      requireInput: false,
                    ),
                    child: const Text('取得經驗值加成'),
                  ),
                  ElevatedButton(
                    onPressed: () => _showActionDialog(
                      '取得連勝激凍',
                      'streak_freeze',
                      requireInput: true,
                    ),
                    child: const Text('取得連勝激凍'),
                  ),
                  ElevatedButton(
                    onPressed: () => _showActionDialog(
                      '請求重置紅心',
                      'heart_refill',
                      requireInput: false,
                    ),
                    child: const Text('重置紅心'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
