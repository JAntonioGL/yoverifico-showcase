// lib/screens/verificacion/6_verificacion_final_screen.sample.dart

/**
 * Pantalla Final de Verificación.
 * Actúa como un recibo visual y emocional del trámite completado.
 * Implementa lógica de fidelización (Rating) y resumen de derechos de circulación.
 */
class VerificacionFinalScreen extends StatefulWidget {
  final String placa;

  const VerificacionFinalScreen({super.key, required this.placa});

  @override
  State<VerificacionFinalScreen> createState() =>
      _VerificacionFinalScreenState();
}

class _VerificacionFinalScreenState extends State<VerificacionFinalScreen> {
  @override
  void initState() {
    super.initState();
    // Lógica de Engagement: Dispara el diálogo de calificación tras un éxito.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CalificacionHelper.verificarYMostrarDialogo(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Column(
        children: [
          // Celebración Visual: Animación de éxito (success_check.json)
          Lottie.asset('assets/animations/success_check.json', repeat: false),

          const TituloAnimado(text: '¡Vehículo Actualizado!'),

          // Tarjeta de Identidad: Refuerza visualmente que el proceso terminó
          _buildVehiculoSummaryCard(),

          // Resumen Operativo: Explica qué significa el nuevo estatus para el usuario
          _buildInfoSection(
            title: 'Estatus de Circulación',
            icon: Icons.info_outline,
            children: [
              _buildCirculacionTexto(), // Texto dinámico según el nuevo holograma
            ],
          ),

          const Spacer(),

          // Botón de Cierre: Navegación atómica que limpia el stack del tutorial
          BotonPrincipal(
            texto: 'ENTENDIDO',
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (_) => false),
          ),
        ],
      ),
    );
  }
}
