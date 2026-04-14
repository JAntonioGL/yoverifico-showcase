// lib/widgets/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_drawer.dart';
import '../providers/notificaciones_provider.dart';
import '../screens/notificaciones/notificaciones_screen.dart';
import '../config.dart' show AdIds;

// ⭐️ Contextos de flujo (compartidos)
const String kFlowCitas = 'citas';
const String kFlowAdeudos = 'adeudos';
const String kFlowMultas = 'multas';
const String kFlowOtro = 'otro';

class MainLayout extends StatefulWidget {
  final Widget child;

  /// Título “manual” (fallback). Se usa si no especificas [flowContext].
  final String title;

  /// ⭐️ Si lo pasas, MainLayout calcula el título automáticamente:
  /// citas → "Agendar cita" | adeudos → "Consultar adeudo"
  /// multas → "Pagar multa extemporánea" | otro → "Navegador"
  final String? flowContext;

  /// Para resaltar el item correcto en el Drawer
  final String? currentRouteName;

  const MainLayout({
    super.key,
    required this.child,
    required this.title,
    this.flowContext,
    this.currentRouteName,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  bool _prefsLoaded = false;
  bool _conAnuncios = true;
  String _codigoPlan = 'FREE';

  @override
  void initState() {
    super.initState();
    _leerPrefsYDecidir();
  }

  Future<void> _leerPrefsYDecidir() async {
    final sp = await SharedPreferences.getInstance();
    final conAds = sp.getBool('con_anuncios') ?? true;
    final plan = sp.getString('codigo_plan') ?? 'FREE';

    if (!mounted) return;
    setState(() {
      _conAnuncios = conAds;
      _codigoPlan = plan;
      _prefsLoaded = true;
    });

    if (_conAnuncios) {
      _loadBanner();
    } else {
      _disposeBanner();
    }
  }

  void _loadBanner() {
    if (_bannerAd != null) return;
    _bannerAd = BannerAd(
      adUnitId: AdIds.banner,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isAdLoaded = false;
          });
        },
      ),
    )..load();
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isAdLoaded = false;
  }

  @override
  void dispose() {
    _disposeBanner();
    super.dispose();
  }

  // ⭐️ Resolver título según flowContext (con fallback al title)
  String _resolveTitle() {
    switch (widget.flowContext) {
      case kFlowCitas:
        return 'Agendar cita';
      case kFlowAdeudos:
        return 'Consultar adeudos';
      case kFlowMultas:
        return 'Multa extemporánea';
      case kFlowOtro:
        return 'Navegador';
      default:
        return widget.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNotificationsScreen = widget.child is NotificacionesScreen;
    final bool shouldShowBanner = _prefsLoaded && _conAnuncios;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 4, // sombra bajo el AppBar
        shadowColor: Colors.black.withOpacity(0.35),
        surfaceTintColor: Colors.transparent, // Material 3: evita “tinte” gris

        // Título blanco con sombra
        title: Text(
          _resolveTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                  offset: Offset(0, 1), blurRadius: 3, color: Colors.black54),
            ],
          ),
        ),

        // Íconos (hamburguesa y acciones) en blanco
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),

        // (Opcional) si usas barra de estado oscura/ligera
        systemOverlayStyle: SystemUiOverlayStyle.light,

        actions: [
          Consumer<NotificacionesProvider>(
            builder: (context, notificacionesProvider, child) {
              final count = notificacionesProvider.notificacionesNoLeidas;
              return badges.Badge(
                badgeContent: Text(
                  count.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                showBadge: count > 0,
                position: badges.BadgePosition.topEnd(top: 0, end: 3),
                child: IconButton(
                  icon: const Icon(Icons.notifications), // saldrá en blanco
                  onPressed: widget.child is NotificacionesScreen
                      ? null
                      : () => Navigator.pushNamed(context, '/notificaciones'),
                ),
              );
            },
          ),
        ],
      ),
      // ⭐️ Pasamos también el flowContext al Drawer
      drawer: AppDrawer(
        currentRouteName: widget.currentRouteName,
        drawerFlowContext: widget.flowContext, // <- NUEVO
      ),
      body: widget.child,
      bottomNavigationBar: shouldShowBanner && _isAdLoaded && _bannerAd != null
          ? SafeArea(
              top: false,
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : null,
    );
  }
}
