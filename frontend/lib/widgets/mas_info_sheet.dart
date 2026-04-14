// widgets/mas_info_sheet.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlMap = Map<String, String>;

/// Pasa tus mapas reales desde la pantalla:
///  - citas: _CITAS_URLS
///  - adeudos: _ADEUDOS_URLS
///  - multas: _MULTAS_URLS
Future<void> showMasInfoSheet({
  required BuildContext context,
  required String flowContext, // 'citas' | 'adeudos' | 'multas'
  required UrlMap citasUrls,
  required UrlMap adeudosUrls,
  required UrlMap multasUrls,
}) async {
  final fc = flowContext.toLowerCase();

  String textoIntro() {
    if (fc == 'adeudos') {
      return 'Esta pantalla te guiará y agilizará el trámite con enlace directo, copiado automático de placa y opción de seleccionar tu estado y vehículo.\n\nSi lo prefieres, puedes acceder directamente aquí:';
    } else if (fc == 'multas') {
      return 'Esta pantalla te guiará y hará más rápido el proceso con enlace directo, copiado automático de placa y opción de seleccionar tu estado y vehículo.\n\nSi lo prefieres, puedes acceder directamente aquí:';
    }
    // default: citas
    return 'Esta pantalla te guiará paso a paso y te ayudará a hacer el proceso más rápido con enlace directo, copiado automático de placa y la posibilidad de seleccionar tu estado y vehículo.\n\nSi lo prefieres, puedes acceder directamente aquí:';
  }

  final UrlMap selectedMap = () {
    if (fc == 'adeudos') return adeudosUrls;
    if (fc == 'multas') return multasUrls;
    return citasUrls;
  }();

  String nombreEstado(String abrev) {
    switch (abrev) {
      case 'CDMX':
        return 'Ciudad de México';
      case 'MEX':
        return 'Estado de México';
      case 'HGO':
        return 'Hidalgo';
      case 'MOR':
        return 'Morelos';
      case 'PUE':
        return 'Puebla';
      case 'QRO':
        return 'Querétaro';
      case 'TLAX':
        return 'Tlaxcala';
      case 'FOR':
        return 'Foráneo';
      default:
        return abrev;
    }
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              _titulo(flowContext),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                textoIntro(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enlaces oficiales directos',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: selectedMap.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final abrev = selectedMap.keys.elementAt(i);
                    final url = selectedMap[abrev]!;
                    return ListTile(
                      dense: true,
                      title: Text(
                        '${nombreEstado(abrev)}:',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(url, style: const TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _openExternal(url),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

String _titulo(String flowContext) {
  switch (flowContext.toLowerCase()) {
    case 'adeudos':
      return 'Adeudos — Más info';
    case 'multas':
      return 'Multas — Más info';
    default:
      return 'Citas — Más info';
  }
}
