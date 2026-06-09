import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ai_assistant/providers/theme_provider.dart';
import 'package:ai_assistant/providers/config_provider.dart';
import 'package:ai_assistant/providers/conversation_provider.dart';
import 'package:ai_assistant/providers/vad_provider.dart';
import 'package:ai_assistant/screens/home_screen.dart';
import 'package:ai_assistant/screens/settings_screen.dart';
import 'package:ai_assistant/screens/test_screen.dart';
import 'package:ai_assistant/utils/app_theme.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import 'package:opus_dart/opus_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:ui';
import 'package:ai_assistant/utils/audio_util.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

const bool enableDebugTools = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _setupSystemUI();

  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.resumed.toString()) {
      await _setupSystemUI();
    }
    return null;
  });

  if (Platform.isAndroid || Platform.isIOS) {
    await Future.delayed(const Duration(milliseconds: 50));
    PaintingBinding.instance.imageCache.maximumSize = 1000;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
  }

  await [
    Permission.microphone,
    Permission.storage,
    if (Platform.isAndroid) Permission.bluetoothConnect,
  ].request();

  timeago.setLocaleMessages('zh', timeago.ZhMessages());
  timeago.setDefaultLocale('zh');

  if (Platform.isAndroid) {
    try {
      final modes = await FlutterDisplayMode.supported;
      print('支持的显示模式: ${modes.length}');
      modes.forEach((mode) => print('模式: $mode'));

      final current = await FlutterDisplayMode.active;
      print('当前模式: $current');

      await FlutterDisplayMode.setHighRefreshRate();

      final afterSet = await FlutterDisplayMode.active;
      print('设置后模式: $afterSet');
    } catch (e) {
      print('设置高刷新率失败: $e');
    }
  }

  try {
    initOpus(await opus_flutter.load());
    print('Opus初始化成功: ${getOpusVersion()}');
  } catch (e) {
    print('Opus初始化失败: $e');
  }

  try {
    await AudioUtil.initRecorder();
    await AudioUtil.initPlayer();
    print('音频系统初始化成功');
  } catch (e) {
    print('音频系统初始化失败: $e');
  }

  final configProvider = ConfigProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: configProvider),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => VadProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _setupSystemUI() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  if (Platform.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } else if (Platform.isIOS) {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'AI-LHHT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const HomeScreen(),
      routes: {
        '/test': (context) => const TestScreen(),
      },
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
    );
  }
}
