// lib/helpers/flujo_anuncio_helper.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config.dart'; // Asegúrate de que contiene AdIds
import '../services/acciones_backend_service.dart';

/// Clase que maneja el flujo de anuncios y reintentos para acciones del backend.
class FlujoAnuncioHelper {
  // Solo estáticas para no requerir instancia
  static RewardedAd? _rewardedAd;
  static OverlayEntry? _overlay;

  // Accede a la ID de la configuración
  static String get _ssvAdUnitId => AdIds.rewarded;

  /// Muestra un diálogo de progreso no dismissible con un mensaje.
  static void _mostrarOverlay(BuildContext context, ValueNotifier<String> msg) {
    if (_overlay != null) return;

    // Usamos rootNavigator: true para asegurar que el overlay no se cierra con pop()
    _overlay = OverlayEntry(
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // No permite cerrar con botón atrás
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ValueListenableBuilder<String>(
              valueListenable: msg,
              builder: (_, text, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(text, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Nota: Usar el Overlay.of(context) en lugar de un showDialog normal
    // Si usas showDialog, reemplaza esto con:
    // showDialog(context: context, barrierDismissible: false, builder: (_) => ...);
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Si usaste showDialog, esta línea es diferente o no necesaria.
    // Asumiendo que quieres el Overlay manual:
    Overlay.of(context, rootOverlay: true).insert(_overlay!);
  }

  /// Oculta el Overlay de progreso.
  static void _ocultarOverlay(BuildContext context) {
    if (_overlay != null) {
      _overlay?.remove();
      _overlay = null;
    }
    // Si usaste showDialog, lo cierras con Navigator.pop(context)
  }

  /// Carga el anuncio recompensado con el folio de verificación Server-Side.
  static Future<RewardedAd?> _cargarRewarded(
      BuildContext context, String folio) async {
    final completer = Completer<RewardedAd?>();

    // Limpia cualquier anuncio anterior
    _rewardedAd?.dispose();
    _rewardedAd = null;

    RewardedAd.load(
      adUnitId: _ssvAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.setServerSideOptions(
              ServerSideVerificationOptions(customData: folio));
          _rewardedAd = ad;
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          completer.complete(null);
          // Muestra mensaje de error de carga de anuncio (opcional)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo cargar el anuncio: $error')),
          );
        },
      ),
    );

    try {
      return await completer.future.timeout(const Duration(seconds: 12));
    } catch (_) {
      return null;
    }
  }

  /// Lanza la ejecución de la acción con reintentos para validar la recompensa.
  static Future<ResultadoEjecucion> _ejecutarConReintentos({
    required BuildContext context,
    required String pathAccion,
    required Map<String, dynamic> body,
    required String folio,
  }) async {
    final msg = ValueNotifier<String>('Validando recompensa…');
    // Si usas un StatefulWidget, esta línea debería ser un showDialog o un Overlay
    // En este ejemplo, asumo que las pantallas usan showDialog con un ValueNotifier.
    // Si quieres el Overlay, debes pasarlo desde el StatefulWidget padre o refactorizar
    // para usar un StateNotifier o Provider. Dejo la implementación con ValueNotifier
    // y showDialog para simplicidad, simulando tu lógica original.

    // Si estás usando un Stateful Widget (como ConfirmarVehiculo), puedes usar
    // un método de la clase padre para mostrar el overlay, o, simplificando:
    // Aquí usamos un showDialog simple ya que el overlay es complejo sin setState.
    // Adapta esto a tu lógica de _mostrarOverlay en la clase original.

    // Nota: Para que el _mostrarOverlay/ValueNotifier funcione en un helper estático,
    // es más fácil usar un showDialog o hacer que el helper reciba el método de la UI.
    // Siguiendo tu código original, se usaba un showDialog. Usaremos un simple diálogo
    // de progreso aquí por ser un helper externo.

    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ValueListenableBuilder<String>(
              valueListenable: msg,
              builder: (_, text, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(text, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);

    const esperas = [
      Duration(seconds: 0), // Intento inmediato
      Duration(seconds: 3), // Reintento 1
      Duration(seconds: 5), // Reintento 2
      Duration(seconds: 7), // Reintento 3
    ];

    ResultadoEjecucion? resultadoFinal;

    for (var i = 0; i < esperas.length; i++) {
      if (i > 0) {
        msg.value = 'Reintentando (${i}/${esperas.length - 1})…';
        await Future.delayed(esperas[i]);
      } else {
        msg.value = 'Enviando solicitud…';
      }

      try {
        final r = await AccionesBackendService.ejecutarAccion(pathAccion, body,
            folio: folio);

        // Criterio de "éxito" o "falla definitiva" (no es pendiente)
        final pendiente =
            r.status == 409 && r.data['error'] == 'pase_pendiente';

        if (!pendiente) {
          resultadoFinal = r;
          break; // Salir si hay éxito o un error que no es 'pendiente'
        }
      } catch (e) {
        // Maneja errores de red/parseo como un error no 'pendiente'
        resultadoFinal =
            ResultadoEjecucion(status: 500, data: {'error': e.toString()});
        break;
      }
    }

    // Limpia el overlay antes de devolver el resultado
    overlayEntry.remove();

    // Si no hubo éxito después de todos los reintentos, devuelve el último error
    return resultadoFinal ??
        ResultadoEjecucion(
            status: 408,
            data: {'error': 'Tiempo de espera agotado, no se validó el pase.'});
  }

  /// --------------------------------------------------------
  /// FUNCIÓN PÚBLICA PRINCIPAL
  /// Orquesta el prechequeo, el anuncio, los reintentos y la ejecución.
  /// --------------------------------------------------------
  static Future<ResultadoEjecucion> ejecutarAccionConAnuncio({
    required BuildContext context,
    required String pathAccionPrechequeo,
    required String pathAccionEjecutar,
    required Map<String, dynamic> body,
  }) async {
    // 1. Prechequeo
    final pre =
        await AccionesBackendService.prechequeoAccion(pathAccionPrechequeo);
    final folio = pre.folio;

    // 2. Si requiere anuncio
    if (pre.requiereAnuncio && folio != null) {
      final ad = _rewardedAd ?? await _cargarRewarded(context, folio);

      if (ad == null) {
        // Si el anuncio no cargó, intenta ejecutar directo (política de backend)
        return AccionesBackendService.ejecutarAccion(pathAccionEjecutar, body,
            folio: folio);
      }

      // 3. Mostrar anuncio y esperar el cierre
      final dismissed = Completer<void>();
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _rewardedAd = null;
          if (!dismissed.isCompleted) dismissed.complete();
        },
        onAdFailedToShowFullScreenContent: (a, error) {
          a.dispose();
          _rewardedAd = null;
          if (!dismissed.isCompleted) dismissed.complete();
          // Muestra error de AdMob
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo mostrar el anuncio: $error')),
          );
        },
      );

      // Muestra el anuncio. El SSV se validará en el backend después del cierre.
      await ad.show(onUserEarnedReward: (_, __) {});
      await dismissed.future;

      // 4. Reintentar ejecución (para validar SSV)
      return _ejecutarConReintentos(
        context: context,
        pathAccion: pathAccionEjecutar,
        body: body,
        folio: folio,
      );
    }

    // 5. No requiere anuncio (ejecución directa)
    return AccionesBackendService.ejecutarAccion(pathAccionEjecutar, body,
        folio: null);
  }
}
