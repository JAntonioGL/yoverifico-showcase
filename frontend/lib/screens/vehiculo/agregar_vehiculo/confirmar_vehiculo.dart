// lib/screens/vehiculo/agregar/confirmar_vehiculo.sample.dart

/**
 * ConfirmarVehiculo orquesta la persistencia final de la flota vehicular.
 * Integra validación de datos, visualización de anuncios recompensados (Rewarded Ads),
 * reintentos automáticos de red y analítica de marketing.
 */
class ConfirmarVehiculo extends StatefulWidget {
  const ConfirmarVehiculo({super.key});

  @override
  State<ConfirmarVehiculo> createState() => _ConfirmarVehiculoState();
}

class _ConfirmarVehiculoState extends State<ConfirmarVehiculo> {
  bool _procesando = false;

  /// Orquestador del flujo de guardado.
  Future<void> _onGuardarPressed() async {
    /* 1. Recolección de datos finales desde el VehiculoProvider.
       2. Ejecución mediante FlujoAnuncioHelper:
          a. Prechequeo: El servidor genera un folio de operación.
          b. Rewarded Ad: Se muestra un anuncio al usuario para procesar la acción gratis.
          c. Ejecutar: El backend valida el 'Server Side Verification' del anuncio y guarda el vehículo.
       3. Reintentos automáticos: En caso de lag en la validación del anuncio (3s, 5s, 7s).
       4. Analítica: Envío de evento 'yoverifico_add_vehicle' a Facebook App Events.
       5. Post-Guardado: Refresco de flota local y navegación al Home con estafeta al Tutorial. */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Vehículo')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const TituloAnimado(text: 'Revisa los Datos'),

            // --- Componente de Identidad Visual ---
            // Reúne toda la información del buffer (Marca, Placa, Color, Alias)
            // en una tarjeta estilo 'ID Card' para validación del usuario.
            VehiculoIdCard(
              nombre: vehiculoProvider.nombre,
              marca: marca.nombre,
              linea: linea.nombre,
              placa: vehiculoProvider.placa,
              colorHex: color.hex,
            ),

            // Acción Final: Botón con gestión de estado de carga.
            BotonPrincipal(
              texto: _procesando ? 'PROCESANDO...' : 'GUARDAR VEHÍCULO',
              onPressed: _procesando ? null : _onGuardarPressed,
            ),
          ],
        ),
      ),
    );
  }
}
