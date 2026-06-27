import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:torch_light/torch_light.dart';

// 👇 وضع الإعلانات:
// false = إعلاناتك الحقيقية (للربح) ✅ ← ده اللي شغّال دلوقتي
// true  = إعلانات تجريبية (وقت التطوير بس)
const bool kUseTestAds = false;

// Ad Unit IDs
const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
const String _realBannerId = 'ca-app-pub-5650078157837633/9835166563';
String get bannerAdUnitId => kUseTestAds ? _testBannerId : _realBannerId;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  // 🛡️ جهازك مسجّل كجهاز اختبار: إنت تشوف إعلان تجريبي،
  // وأصحابك يشوفوا الإعلان الحقيقي. ده بيحميك من الحظر.
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(testDeviceIds: ['58935E6240FCD39A7EA6261D70057935']),
  );

  runApp(const FlashApp());
}

// ====== الجذر: يتحكم في اللغة والثيم ======
class FlashApp extends StatefulWidget {
  const FlashApp({super.key});

  @override
  State<FlashApp> createState() => _FlashAppState();
}

class _FlashAppState extends State<FlashApp> {
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleLanguage() {
    setState(() {
      _locale = _locale.languageCode == 'ar'
          ? const Locale('en')
          : const Locale('ar');
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFC107);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData.light(
        useMaterial3: true,
      ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: accent)),
      darkTheme: ThemeData.dark(useMaterial3: true),
      locale: _locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FlashScreen(
        isArabic: _locale.languageCode == 'ar',
        isDark: _themeMode == ThemeMode.dark,
        onToggleLanguage: _toggleLanguage,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

// ====== النصوص (عربي / إنجليزي) ======
class AppStrings {
  final bool ar;
  const AppStrings(this.ar);
  String get title => ar ? 'الفلاش' : 'Flashlight';
  String get off => ar ? 'مطفأ' : 'Off';
  String get speed => ar ? 'السرعة' : 'Speed';
}

enum FlashMode { off, on, slow, medium, fast, custom }

class _ModeInfo {
  final String ar;
  final String en;
  final IconData icon;
  const _ModeInfo(this.ar, this.en, this.icon);
  String label(bool isArabic) => isArabic ? ar : en;
}

class FlashScreen extends StatefulWidget {
  final bool isArabic;
  final bool isDark;
  final VoidCallback onToggleLanguage;
  final VoidCallback onToggleTheme;

  const FlashScreen({
    super.key,
    required this.isArabic,
    required this.isDark,
    required this.onToggleLanguage,
    required this.onToggleTheme,
  });

  @override
  State<FlashScreen> createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen> {
  FlashMode _mode = FlashMode.off;
  Timer? _timer;
  bool _isOn = false;
  double _customSpeed = 200;

  // الإعلان
  BannerAd? _bannerAd;
  bool _bannerReady = false;

  final Map<FlashMode, int> _speeds = {
    FlashMode.slow: 700,
    FlashMode.medium: 350,
    FlashMode.fast: 100,
  };

  final Map<FlashMode, _ModeInfo> _modes = const {
    FlashMode.off: _ModeInfo('إطفاء', 'Off', Icons.power_settings_new),
    FlashMode.on: _ModeInfo('تشغيل', 'On', Icons.lightbulb),
    FlashMode.slow: _ModeInfo('بطيء', 'Slow', Icons.speed),
    FlashMode.medium: _ModeInfo('متوسط', 'Medium', Icons.speed),
    FlashMode.fast: _ModeInfo('سريع', 'Fast', Icons.flash_on),
    FlashMode.custom: _ModeInfo('مخصص', 'Custom', Icons.tune),
  };

  bool get _isActive => _mode != FlashMode.off;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('✅ الإعلان اتحمّل بنجاح');
          setState(() => _bannerReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ الإعلان فشل: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _timer?.cancel();
    _turnOff();
    super.dispose();
  }

  Future<void> _enableTorch() async {
    try {
      await TorchLight.enableTorch();
    } catch (_) {}
  }

  Future<void> _disableTorch() async {
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }

  void _turnOff() {
    _timer?.cancel();
    _disableTorch();
    _isOn = false;
  }

  void _setMode(FlashMode mode) {
    _timer?.cancel();
    setState(() => _mode = mode);

    switch (mode) {
      case FlashMode.off:
        _turnOff();
        break;
      case FlashMode.on:
        _enableTorch();
        _isOn = true;
        break;
      case FlashMode.slow:
      case FlashMode.medium:
      case FlashMode.fast:
        _startStrobe(_speeds[mode]!);
        break;
      case FlashMode.custom:
        _startStrobe(_customSpeed.toInt());
        break;
    }
  }

  void _startStrobe(int intervalMs) {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _isOn = !_isOn;
      _isOn ? _enableTorch() : _disableTorch();
    });
  }

  void _togglePower() {
    if (_isActive) {
      _setMode(FlashMode.off);
    } else {
      _setMode(FlashMode.on);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFC107);
    final bool isDark = widget.isDark;
    final bool isAr = widget.isArabic;
    final s = AppStrings(isAr);

    final List<Color> bgColors = isDark
        ? const [Color(0xFF1A1A2E), Color(0xFF0F0F1B)]
        : const [Color(0xFFF5F5FA), Color(0xFFE6E6F0)];
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subColor = isDark ? Colors.white38 : Colors.black45;
    final Color panelColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // الشريط العلوي
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: widget.onToggleTheme,
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: textColor,
                      ),
                    ),
                    Text(
                      s.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onToggleLanguage,
                      child: Text(
                        isAr ? 'EN' : 'ع',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // الزرار الكبير
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _togglePower,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: _isActive
                                  ? [accent, const Color(0xFFFF8F00)]
                                  : (isDark
                                        ? const [
                                            Color(0xFF2A2A3E),
                                            Color(0xFF1E1E2E),
                                          ]
                                        : const [
                                            Color(0xFFFFFFFF),
                                            Color(0xFFDADAE5),
                                          ]),
                            ),
                            boxShadow: [
                              if (_isActive)
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.6),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                )
                              else
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black54
                                      : Colors.black26,
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                            ],
                          ),
                          child: Icon(
                            _isActive
                                ? Icons.flashlight_on
                                : Icons.flashlight_off,
                            size: 84,
                            color: _isActive ? Colors.black87 : subColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _isActive ? _modes[_mode]!.label(isAr) : s.off,
                        style: TextStyle(
                          fontSize: 18,
                          color: _isActive ? accent : subColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // اللوحة السفلية
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _modes.entries
                          .where((e) => e.key != FlashMode.off)
                          .map(
                            (e) =>
                                _modePill(e.key, e.value, accent, isDark, isAr),
                          )
                          .toList(),
                    ),
                    if (_mode == FlashMode.custom) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${s.speed}: ${_customSpeed.toInt()} ms',
                        style: TextStyle(color: subColor),
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: accent,
                          thumbColor: accent,
                          overlayColor: accent.withValues(alpha: 0.2),
                          inactiveTrackColor: isDark
                              ? Colors.white12
                              : Colors.black12,
                        ),
                        child: Slider(
                          min: 50,
                          max: 1000,
                          divisions: 19,
                          value: _customSpeed,
                          label: '${_customSpeed.toInt()} ms',
                          onChanged: (v) {
                            setState(() => _customSpeed = v);
                            _startStrobe(v.toInt());
                          },
                        ),
                      ),
                    ],

                    // 👇 الإعلان (Banner)
                    if (_bannerReady && _bannerAd != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: _bannerAd!.size.height.toDouble(),
                        width: _bannerAd!.size.width.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modePill(
    FlashMode mode,
    _ModeInfo info,
    Color accent,
    bool isDark,
    bool isAr,
  ) {
    final bool selected = _mode == mode;
    final Color pillBg = selected
        ? accent
        : (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05));
    final Color pillText = selected
        ? Colors.black87
        : (isDark ? Colors.white70 : Colors.black87);

    return GestureDetector(
      onTap: () => _setMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? accent
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon, size: 18, color: pillText),
            const SizedBox(width: 6),
            Text(
              info.label(isAr),
              style: TextStyle(color: pillText, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
//555