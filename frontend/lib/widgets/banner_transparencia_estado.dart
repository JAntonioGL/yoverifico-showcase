import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BannerTransparenciaEstado extends StatelessWidget {
  final String flowContext; // 'citas' | 'adeudos' | 'multas'

  const BannerTransparenciaEstado({
    super.key,
    required this.flowContext,
  });

  String _textoBanner() {
    switch (flowContext.toLowerCase()) {
      case 'adeudos':
        return 'Te llevaremos al portal oficial para consultar o pagar tus adeudos y podrás copiar tu placa para agilizar tu proceso. También puedes abrirlo en el navegador de tu celular.';
      case 'multas':
        return 'Te llevaremos al sitio oficial para consultar o pagar tus multas y podrás copiar tu placa para agilizar tu proceso. También puedes abrirlo en el navegador de tu celular.';
      default:
        return 'Te llevaremos al sitio oficial para agendar tu cita y podrás copiar tu placa para hacer el proceso más rápido. También puedes abrirlo en el navegador de tu celular.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              _textoBanner(),
              style: const TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () => _showMasInfo(context),
            style: TextButton.styleFrom(padding: const EdgeInsets.all(4)),
            child: const Text(
              'Más info',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showMasInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return _MasInfoContent(flowContext: flowContext);
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Contenido del modal "Más info" (usa tus URLs oficiales)
// -----------------------------------------------------------------------------
class _MasInfoContent extends StatelessWidget {
  final String flowContext;

  const _MasInfoContent({required this.flowContext});

  Map<String, String> _urlsPorContexto() {
    switch (flowContext.toLowerCase()) {
      case 'adeudos':
        return {
          'Ciudad de México':
              'https://data.finanzas.cdmx.gob.mx/consulta_adeudos',
          'Estado de México':
              'https://sfpya.edomexico.gob.mx/controlv/faces/tramiteselectronicos/cv/portalPublico/ConsultaVigenciaPlaca.xhtml?P=2',
        };
      case 'multas':
        return {
          'Ciudad de México':
              'https://data.finanzas.cdmx.gob.mx/formato_lc/ambiente/50',
          'Estado de México':
              'https://sfpya.edomexico.gob.mx/recaudacion/index.jsp?opcion=61',
        };
      default:
        return {
          'Ciudad de México': 'https://citasverificentros.cdmx.gob.mx/',
          'Estado de México':
              'https://citaverificacion.edomex.gob.mx/RegistroCitas/citas/frmIniciaRegistroCita.jsp',
          // 'Hidalgo': 'https://verificacionvehicular.hidalgo.gob.mx/#/citas',
          'Morelos': 'https://www.airepuromorelos.com.mx/sanidad.php',
          'Puebla': 'https://citasenlinea.puebla.gob.mx/',
          'Querétaro':
              'http://189.195.154.174:8089/ConstanciaVerificacion/RegistroCitas.jsp',
          'Tlaxcala':
              'https://citasverificacion.com.mx/verificacion-vehicular-tlaxcala/#agendar-cita',
        };
    }
  }

  Future<void> _abrirEnlace(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urlsPorContexto();
    final fc = flowContext.toLowerCase();

    String intro;
    if (fc == 'adeudos') {
      intro =
          'Esta pantalla te guiará y agilizará el trámite con enlace directo, copiado automático de placa y opción de seleccionar tu estado y vehículo.\n\nO si lo deseas, puedes acceder directamente aquí:';
    } else if (fc == 'multas') {
      intro =
          'Esta pantalla te guiará y hará más rápido el proceso con enlace directo, copiado automático de placa y opción de seleccionar tu estado y vehículo.\n\nO si lo deseas, puedes acceder directamente aquí:';
    } else {
      intro =
          'Esta pantalla te guiará paso a paso y te ayudará a hacer el proceso más rápido con enlace directo, copiado automático de placa y la posibilidad de seleccionar tu estado y vehículo.\n\nO si lo deseas, puedes acceder directamente aquí:';
    }

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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              intro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enlaces oficiales directos:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: urls.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final nombre = urls.keys.elementAt(i);
                  final enlace = urls[nombre]!;
                  return ListTile(
                    dense: true,
                    title: Text(
                      nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        Text(enlace, style: const TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _abrirEnlace(enlace),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }

  String _titulo(String fc) {
    switch (fc.toLowerCase()) {
      case 'adeudos':
        return 'Adeudos — Más info';
      case 'multas':
        return 'Multas — Más info';
      default:
        return 'Citas — Más info';
    }
  }
}
