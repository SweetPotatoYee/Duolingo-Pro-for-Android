import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('zh', 'TW'),
        Locale('zh', 'CN'),
        Locale('es'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const DuolingoProApp(),
    ),
  );
}

class DuolingoProApp extends StatelessWidget {
  const DuolingoProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duolingo PRO',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
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
  String pingStatus = 'connect_no'.tr();
  Timer? pingTimer;
  final String apiUrl = 'https://api.duolingopro.net';
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationLoader.checkAndShowNotices(context, mounted);
    });
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
    if (pingStatus == 'connect_ed'.tr()) {}
    setState(
      () => pingStatus = pingStatus == 'connect_ed'.tr()
          ? 'connect_ed'.tr()
          : 'connect_ing'.tr(),
    );
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
        setState(() => pingStatus = 'connect_ed'.tr());
        setState(() => statusIcon = Icons.check_circle);
        _startPingLoop();
      } else {
        setState(() => pingStatus = 'error'.tr() + res.statusCode.toString());
        setState(() => statusIcon = Icons.cancel);
        Future.delayed(const Duration(seconds: 3), _ping);
      }
    } catch (e) {
      setState(() => pingStatus = 'error'.tr());
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
        title: Text('enter_user_id'.tr()),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) _saveUserId(result);
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => const AboutBottomSheet(),
    );
  }

  void _showNotificationDialog(Map<String, dynamic> notification) {
    final head = notification['head'] ?? 'notification';
    final body = notification['body'] ?? '';

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
            child: Text('close'.tr()),
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text('submit'.tr()),
            ),
          ],
        ),
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text('confirm_r'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('confirm'.tr()),
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
          title: Text('processing'.tr()),
          content: ValueListenableBuilder<int>(
            valueListenable: percentage,
            builder: (_, value, _) => Column(
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
          _showNotificationDialog({
            "head": "failed_s".tr(),
            "body": e.toString(),
          });
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
          _showNotificationDialog({
            "head": "failed_s".tr(),
            "body": e.toString(),
          });
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
            onPressed: () => _showAbout(context),
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
                    onPressed: () => _showActionDialog("xp_button".tr(), 'xp'),
                    child: Text('request_xp'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        _showActionDialog('request_gems'.tr(), '', isGem: true),
                    child: Text('gems_button'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () => _showActionDialog(
                      'request_super'.tr(),
                      'super',
                      requireInput: false,
                    ),
                    child: Text('super_button'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () => _showActionDialog(
                      'request_double_xp'.tr(),
                      'double_xp_boost',
                      requireInput: false,
                    ),
                    child: Text('double_xp_button'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () => _showActionDialog(
                      'request_streak_freeze'.tr(),
                      'streak_freeze',
                      requireInput: true,
                    ),
                    child: Text('streak_freeze_button'.tr()),
                  ),
                  ElevatedButton(
                    onPressed: () => _showActionDialog(
                      'request_heart_refill'.tr(),
                      'heart_refill',
                      requireInput: false,
                    ),
                    child: Text('heart_refill_button'.tr()),
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

class AboutBottomSheet extends StatefulWidget {
  const AboutBottomSheet({super.key});

  @override
  State<AboutBottomSheet> createState() => _AboutBottomSheetState();
}

class _AboutBottomSheetState extends State<AboutBottomSheet> {
  String versionText = '';
  bool hasUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadLocalVersion();
    _checkRemoteUpdate();
  }

  Future<void> _loadLocalVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      versionText = '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _checkRemoteUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final localBuild = int.tryParse(info.buildNumber) ?? 0;

    try {
      final res = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/SweetPotatoYee/Duolingo-Pro-for-Android/refs/heads/main/versionCode',
        ),
      );
      final remoteBuild = int.tryParse(res.body.trim());
      if (!mounted) return;
      setState(() {
        hasUpdate = remoteBuild != null && remoteBuild > localBuild;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/logo.svg',
                width: 48,
                height: 48,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Duolingo Pro',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Powered by DuolingoPro.net',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      'Copyright © 2025 anonymoushackerIV',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${'version'.tr()} $versionText',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${'developer'.tr()}: SweetPotatoYee',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text('license'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Duolingo Pro',
                applicationVersion: versionText,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.system_update_alt_outlined),
            title: Text('update_c'.tr()),
            subtitle: Text(
              hasUpdate ? 'update_1'.tr() : 'update_0'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: hasUpdate
                ? FilledButton.icon(
                    icon: const Icon(Icons.download),
                    label: Text('download'.tr()),
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://github.com/SweetPotatoYee/Duolingo-Pro-for-Android/raw/refs/heads/main/build/release/latest.apk',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class NotificationLoader {
  static const String remoteUrl =
      'https://raw.githubusercontent.com/SweetPotatoYee/Duolingo-Pro-for-Android/main/config/notification.json';

  static String getLangKey(Locale locale) {
    final tag = locale.toLanguageTag();
    if (tag.startsWith('zh-TW') || tag.startsWith('zh-Hant')) return 'zh-TW';
    if (tag.startsWith('zh-CN') || tag.startsWith('zh-Hans')) return 'zh-CN';
    if (tag.startsWith('es')) return 'es';
    return 'en';
  }

  static Future<void> checkAndShowNotices(
    BuildContext context,
    bool mounted,
  ) async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seenIds = prefs.getStringList('seen_notices') ?? [];

    final res = await http.get(Uri.parse(remoteUrl));
    if (res.statusCode != 200) return;

    final List data = jsonDecode(res.body);

    final locale = Localizations.localeOf(context);
    final langKey = getLangKey(locale);

    for (final item in data) {
      final String id = item['id'];
      if (seenIds.contains(id)) continue;

      final content = item['langs'][langKey] ?? item['langs']['en'];
      final head = content['head'] ?? 'Notice';
      final body = content['body'] ?? '';

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(head),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      seenIds.add(id);
      await prefs.setStringList('seen_notices', seenIds);
    }
  }
}
