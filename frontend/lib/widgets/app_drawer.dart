// lib/widgets/app_drawer.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoverifico_app/widgets/dialogo_calificacion.dart';

import 'package:yoverifico_app/providers/usuario_provider.dart';
import 'package:yoverifico_app/screens/acuerdos/acuerdos.dart';
import 'package:yoverifico_app/services/session_service.dart';
import 'package:yoverifico_app/config.dart'; // APP_TRACK (fallback para track)

class AppDrawer extends StatefulWidget {
  final String? currentRouteName;
  final String? drawerFlowContext;

  const AppDrawer({
    super.key,
    required this.currentRouteName,
    this.drawerFlowContext,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // ---- Estado local desde SharedPreferences ----
  String _track = '';
  int _build = 0;
  bool _loaded = false;

  // Claves de caché usadas por VersionService
  static const String _kVersionEnvelope =
      'version:policy:last'; // JSON con payload.track
  static const String _kLocalBuild = 'app:build:current'; // int con buildNumber

  @override
  void initState() {
    super.initState();
    _hydrateFromLocal();
  }

  Future<void> _hydrateFromLocal() async {
    final sp = await SharedPreferences.getInstance();

    // ---- TRACK ----
    String track = APP_TRACK.toLowerCase();
    final rawEnvelope = sp.getString(_kVersionEnvelope);
    if (rawEnvelope != null && rawEnvelope.isNotEmpty) {
      try {
        final env = _safeJson(rawEnvelope);
        final payload = (env['payload'] as Map?) ?? const {};
        final t = (payload['track'] ?? '').toString().trim().toLowerCase();
        if (t.isNotEmpty) track = t;
      } catch (_) {}
    }

    // ---- BUILD ----
    final build = sp.getInt(_kLocalBuild) ?? 0;

    if (mounted) {
      setState(() {
        _track = track;
        _build = build;
        _loaded = true;
      });
    }
  }

  Map<String, dynamic> _safeJson(String raw) {
    if (raw.isEmpty) return <String, dynamic>{};
    final m = jsonDecode(raw);
    return m is Map ? Map<String, dynamic>.from(m) : <String, dynamic>{};
  }

  bool get _buildEs7XXXX => _build.toString().startsWith('7');

  bool get _esTrackRestrictivo {
    // Jerarquía: versionCode > track
    if (_buildEs7XXXX) return true;
    return _track == 'prod';
  }

  // ✅ Nueva regla: bloquear solo a FREE (si no es personalizado) en modo restrictivo.
  bool _puedeVerSoporte({
    required String codigoPlan,
    required bool esPersonalizado,
  }) {
    if (esPersonalizado) return true; // planes personalizados nunca se bloquean
    final esFree = codigoPlan.toUpperCase() == 'FREE';
    if (_esTrackRestrictivo)
      return !esFree; // en prod/7xxxx, solo FREE se bloquea
    return true; // en otros tracks, siempre visible
  }

  Future<void> _logoutConBloqueo(BuildContext context) async {
    try {
      await safeLogoutWithWatchdog(
        context,
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  void _go(BuildContext context, String targetRoute,
      {Map<String, dynamic>? args}) {
    Navigator.pop(context);

    if (widget.currentRouteName == targetRoute) {
      final String? nextFlow = args?['flowContext'] as String?;
      final String? currentFlow = widget.drawerFlowContext;
      if (targetRoute == '/navegador/estado' &&
          nextFlow != null &&
          nextFlow != currentFlow) {
        Navigator.pushReplacementNamed(context, targetRoute, arguments: args);
        return;
      }
      return;
    }

    Navigator.pushNamed(context, targetRoute, arguments: args);
  }

  // 🔹 Color efectivo del texto del ListTile (para teñir el ícono PNG)
  Color _effectiveTileColor(BuildContext context) {
    final textColor = DefaultTextStyle.of(context).style.color;
    return textColor ??
        Theme.of(context).listTileTheme.textColor ??
        Theme.of(context).colorScheme.onSurface;
  }

  // 🔹 Ícono YoVerifico (PNG) teñido al color del texto
  Widget _yvCarIcon(BuildContext context, {double width = 24}) {
    final color = _effectiveTileColor(context);
    return SizedBox(
      width: width,
      child: Image.asset(
        'assets/images/YoVerifico_car.png',
        fit: BoxFit.fitWidth,
        color: color,
        colorBlendMode: BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuarioProv = context.watch<UsuarioProvider>();
    final usuario = usuarioProv.usuario;
    final nombre = (usuario?.nombre ?? '').trim();

    final bool isNavRoute = widget.currentRouteName == '/navegador/estado' ||
        widget.currentRouteName == '/navegador/precheck' ||
        widget.currentRouteName == '/navegador/web';

    // Flag de soporte según jerarquía (usa datos vivos del provider)
    final puedeMostrarSoporte = _loaded
        ? _puedeVerSoporte(
            codigoPlan: usuarioProv.codigoPlan,
            esPersonalizado: usuarioProv.esPersonalizado,
          )
        : false; // evitar parpadeo antes de hidratar track/build

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF4CAF50)),
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo horizontal en blanco
                SizedBox(
                  height: 55,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/logo_yoverifico.png',
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hola ${nombre.isNotEmpty ? nombre : 'usuario'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ------------------ OPCIONES ------------------

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            selected: widget.currentRouteName == '/home',
            onTap: () => _go(context, '/home'),
          ),

          // 🔁 Mis Vehículos con ícono PNG teñido del color del texto
          ListTile(
            leading: _yvCarIcon(context, width: 24),
            title: const Text('Mis Vehículos'),
            selected: widget.currentRouteName == '/vehiculos/mios',
            onTap: () => _go(context, '/vehiculos/mios'),
          ),

          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('Mejorar plan'),
            subtitle: const Text('Beneficios y precios'),
            selected: widget.currentRouteName == '/planes/info',
            onTap: () => _go(context, '/planes/info'),
          ),

          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Verificentros'),
            subtitle: const Text('CDMX'),
            selected: widget.currentRouteName == '/verificentros/precheck',
            onTap: () => _go(context, '/verificentros/precheck'),
          ),

          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Agendar Cita'),
            selected: isNavRoute && widget.drawerFlowContext == 'citas',
            onTap: () => _go(context, '/navegador/estado',
                args: {'flowContext': 'citas'}),
          ),

          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Consultar Adeudos'),
            subtitle: const Text('CDMX y Edo Mex'),
            selected: isNavRoute && widget.drawerFlowContext == 'adeudos',
            onTap: () => _go(context, '/navegador/estado',
                args: {'flowContext': 'adeudos'}),
          ),

          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('Pagar Multa Extemporánea'),
            subtitle: const Text('CDMX y Edo Mex'),
            selected: isNavRoute && widget.drawerFlowContext == 'multas',
            onTap: () => _go(context, '/navegador/estado',
                args: {'flowContext': 'multas'}),
          ),

          if (puedeMostrarSoporte)
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Soporte'),
              subtitle: const Text('Reportar problema o sugerencia'),
              selected: widget.currentRouteName == '/tickets/levantar',
              onTap: () => _go(context, '/tickets/levantar'),
            ),

          const Divider(),

          // --- Acerca de (FAQ y Avisos) ---
          ExpansionTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            subtitle: const Text('FAQ y Avisos'),
            initiallyExpanded: widget.currentRouteName == '/acuerdos' ||
                widget.currentRouteName == '/FAQ/FAQ',
            children: [
              ListTile(
                leading: const Icon(Icons.policy),
                title: const Text('Avisos (Términos y Privacidad)'),
                selected: widget.currentRouteName == '/acuerdos',
                onTap: () => _go(
                  context,
                  '/acuerdos',
                  // Si tu onGenerateRoute acepta enum directamente, puedes pasar el enum.
                  // Aquí mando un string para máxima compatibilidad.
                  args: {'mode': AvisosMode.consulta},
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('FAQ (Preguntas Frecuentes)'),
                selected: widget.currentRouteName == '/FAQ/FAQ',
                onTap: () => _go(context, '/FAQ/FAQ'),
              ),
            ],
          ),

          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Calificar / Compartir app'),
            onTap: () async {
              // Cierra el drawer primero
              Navigator.pop(context);

              // Luego muestra el popup reutilizable
              await mostrarDialogoCalificacion(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () async => _logoutConBloqueo(context),
          ),
        ],
      ),
    );
  }
}
