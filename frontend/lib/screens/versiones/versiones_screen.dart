// lib/screens/versiones/versiones_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/version_services.dart';

class VersionesScreen extends StatefulWidget {
  const VersionesScreen({super.key});

  @override
  State<VersionesScreen> createState() => _VersionesScreenState();
}

class _VersionesScreenState extends State<VersionesScreen> {
  bool _loading = true;
  Map<String, dynamic>? _raw; // { status, receivedAt, payload:{...} }
  Map<String, dynamic> get _payload =>
      (_raw?['payload'] as Map?)?.cast<String, dynamic>() ?? const {};

  String get _decision => (_payload['decision'] ?? '').toString().toLowerCase();

  String? get _updateUrl {
    final u = (_payload['update_url'] ?? _payload['updateUrl'])?.toString();
    return (u != null && u.isNotEmpty) ? u : null;
  }

  String? get _msgSoft {
    final s = (_payload['message_soft'] ?? _payload['messageSoft'])?.toString();
    return (s != null && s.isNotEmpty) ? s : null;
  }

  String? get _msgHard {
    final s = (_payload['message_hard'] ?? _payload['messageHard'])?.toString();
    return (s != null && s.isNotEmpty) ? s : null;
  }

  String get _track => (_payload['track'] ?? '').toString();

  bool get _isHard => _decision == 'hard' || _raw?['status'] == 426;
  bool get _isSoft => _decision == 'soft';
  bool get _isMismatch => _decision == 'mismatch';

  Future<void> _loadCache() async {
    final sp = await SharedPreferences.getInstance();
    final rawStr = sp.getString(VersionService.cacheKey); // usar misma key
    if (rawStr != null && rawStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawStr) as Map<String, dynamic>;
        setState(() {
          _raw = decoded;
          _loading = false;
        });
        return;
      } catch (_) {}
    }
    // No hay cache o está corrupto
    setState(() {
      _raw = null;
      _loading = false;
    });
  }

  Future<void> _openUrl() async {
    final url = _updateUrl;
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay URL de actualización.')),
        );
      }
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir: $url')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isHard
        ? 'Actualización obligatoria'
        : _isSoft
            ? 'Nueva versión disponible'
            : _isMismatch
                ? 'Build no corresponde al canal'
                : 'Estado de la app';

    // Bloquea el botón atrás cuando es hard
    return WillPopScope(
      onWillPop: () async => !_isHard,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          automaticallyImplyLeading: !_isHard,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Sin cache → nada que mostrar
    if (_raw == null) {
      return const _CenteredInfo(
        icon: Icons.check_circle_outline,
        title: 'Todo al día',
        subtitle: 'No hay política de versión en cache.',
      );
    }

    // UI principal con animación
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Animación (ajusta la ruta del asset si es distinta)
          SizedBox(
            height: 180,
            child: Lottie.asset('assets/animations/update.json', repeat: true),
          ),
          const SizedBox(height: 12),

          // Título grande
          Text(
            _isHard
                ? 'Debes actualizar para continuar'
                : _isSoft
                    ? 'Tenemos nuevas funciones para ti'
                    : _isMismatch
                        ? 'Esta build no coincide con el track'
                        : 'Todo al día 🎉',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Mensaje
          Text(
            _isHard
                ? (_msgHard ??
                    'Actualiza la app para seguir usándola sin interrupciones.')
                : _isSoft
                    ? (_msgSoft ??
                        'Actualiza la app y disfruta lo que hemos implementado, siempre pensando en ti.')
                    : _isMismatch
                        ? 'Track actual: ${_track.isEmpty ? 'desconocido' : _track}.'
                        : 'Tu aplicación está en la última versión disponible.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Botón principal
          if (_isHard || _isSoft)
            ElevatedButton.icon(
              onPressed: _openUrl,
              icon: const Icon(Icons.system_update),
              label: const Text('ACTUALIZAR AHORA'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          // Botón secundario sólo si NO es hard
          if (!_isHard) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('AHORA NO'),
            ),
          ],

          // Estado de diagnóstico (útil en QA)
          // const SizedBox(height: 20),
          // _DebugBox(raw: _raw!),
        ],
      ),
    );
  }
}

class _CenteredInfo extends StatelessWidget {
  const _CenteredInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// class _DebugBox extends StatelessWidget {
//   const _DebugBox({required this.raw});
//   final Map<String, dynamic> raw;

//   @override
//   Widget build(BuildContext context) {
//     final status = raw['status'];
//     final at = raw['receivedAt'];
//     final payload = raw['payload'];

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: DefaultTextStyle.merge(
//         style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Text('status: $status'),
//           Text('receivedAt: $at'),
//           const SizedBox(height: 6),
//           const Text('payload:'),
//           const SizedBox(height: 6),
//           Text(const JsonEncoder.withIndent('  ').convert(payload)),
//         ]),
//       ),
//     );
//   }
// }
