// lib/widgets/dialogo_calificacion.dart
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yoverifico_app/config.dart';

Future<void> mostrarDialogoCalificacion(BuildContext context) {
  double rating = 0; // valor local para las estrellas

  return showDialog(
    context: context,
    barrierDismissible: true, // se puede cerrar tocando fuera o con back
    builder: (ctx) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Título
                  const Text(
                    '¿Te gusta YoVerifico?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Texto principal
                  const Text(
                    'No olvides compartir la app con tus amigos y familiares '
                    'para que también eviten multas. ¡No regalen su dinero!.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Selector de estrellas (sin texto extra)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = rating >= i + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            rating = i + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 36,
                            color: filled ? Colors.amber : Colors.grey.shade400,
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 26),

                  // Fila de botones: Calificar (izq) y Compartir (der)
                  Row(
                    children: [
                      // Botón CALIFICAR (izquierda)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Cerramos primero el diálogo para que la transición sea limpia
                            Navigator.of(ctx).pop();

                            final uri = Uri.parse(urlCalificacionYoVerifico);

                            try {
                              final inAppReview = InAppReview.instance;

                              // 1) Intentar reseña in-app (si Google la quiere mostrar)
                              if (await inAppReview.isAvailable()) {
                                await inAppReview.requestReview();
                              }

                              // 2) Independientemente de lo anterior, abrimos la ficha en Play Store
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            } catch (_) {
                              // 3) Si algo falla, al menos intentar abrir la ficha web
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Calificar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Botón COMPARTIR (derecha, con ícono)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Share.share(mensajeCompartirYoVerifico);
                            Navigator.of(ctx).pop();
                          },
                          icon: const Icon(
                            Icons.share_rounded,
                            size: 20,
                          ),
                          label: const Text(
                            'Compartir',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.green.shade600,
                            ),
                            foregroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
