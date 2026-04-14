import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionUiHelper {
  static const String _spKey = 'version:policy:last';

  static Future<void> maybeShowUpdateDialog(BuildContext context) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_spKey);
    if (raw == null || raw.isEmpty) return;

    Map<String, dynamic> root;
    try {
      root = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await sp.remove(_spKey);
      return;
    }

    final int status = (root['status'] is int) ? root['status'] as int : 0;
    final Map<String, dynamic> payload = (root['payload'] is Map)
        ? Map<String, dynamic>.from(root['payload'])
        : <String, dynamic>{};

    // --- normalizaciones ---
    String decision = (payload['decision'] ?? '')
        .toString()
        .trim()
        .toLowerCase(); // ok|soft|hard|mismatch|''

    final int? minBuild =
        _asInt(payload['versioncode_min']) ?? _asInt(payload['min']);
    final int? recBuild = _asInt(payload['versioncode_recommended']) ??
        _asInt(payload['recommended']);
    final int? latestBuild =
        _asInt(payload['versioncode_latest']) ?? _asInt(payload['latest']);
    final String? updateUrl =
        (payload['updateUrl'] ?? payload['update_url'])?.toString();

    final String? msgSoft =
        (payload['message_soft'] ?? payload['msg_soft'] ?? payload['message'])
            ?.toString();
    final String? msgHard =
        (payload['message_hard'] ?? payload['msg_hard'] ?? payload['message'])
            ?.toString();

    // build local del APK/IPA
    final pkg = await PackageInfo.fromPlatform();
    final int localBuild = int.tryParse(pkg.buildNumber) ?? 0;

    // --- reglas fallback en cliente ---
    final bool clientHard =
        (minBuild != null && localBuild < minBuild) || status == 426;
    final bool clientSoft = (latestBuild != null && localBuild < latestBuild);

    // si backend no decidió explícito, usamos fallback
    if (decision.isEmpty || decision == 'ok') {
      if (clientHard)
        decision = 'hard';
      else if (clientSoft)
        decision = 'soft';
      else
        decision = 'ok';
    }

    if (decision == 'hard') {
      await _showHardDialog(
        context,
        message: msgHard ?? 'Debes actualizar para continuar.',
        updateUrl: updateUrl,
      );
      return;
    }
    if (decision == 'soft') {
      await _showSoftDialog(
        context,
        message: msgSoft ?? 'Hay una nueva versión disponible.',
        updateUrl: updateUrl,
      );
      return;
    }
    if (decision == 'mismatch') {
      await _showMismatchDialog(context);
      return;
    }
    // ok → nada
  }

  // ---- diálogos ----

  static Future<void> _showHardDialog(
    BuildContext context, {
    required String message,
    required String? updateUrl,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Actualización requerida'),
          content: Text(message),
          actions: [
            TextButton.icon(
              onPressed: () => _openUrlOrSnk(ctx, updateUrl),
              icon: const Icon(Icons.system_update),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showSoftDialog(
    BuildContext context, {
    required String message,
    required String? updateUrl,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva versión disponible'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).maybePop(),
            child: const Text('Ahora no'),
          ),
          TextButton.icon(
            onPressed: () => _openUrlOrSnk(ctx, updateUrl),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
  

  static Future<void> _showMismatchDialog(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Build fuera de canal'),
        content: const Text('Esta build no corresponde al canal configurado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).maybePop(),
            child: const Text('Entendido'),
          )
        ],
      ),
    );
  }

  static Future<void> _openUrlOrSnk(BuildContext context, String? url) async {
    if (!context.mounted) return;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay URL de actualización.')));
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('URL inválida: $url')));
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo abrir: $url')));
    }
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
}
