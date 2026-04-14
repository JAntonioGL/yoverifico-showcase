// lib/screens/verificentros/verificentros_map_page.sample.dart

/**
 * VerificentrosMapPage gestiona la visualización geográfica de centros.
 * Implementa algoritmos de proximidad (Haversine) y filtrado por Alcaldía/Municipio.
 */
class VerificentrosMapPage extends StatefulWidget {
  const VerificentrosMapPage({super.key});

  @override
  State<VerificentrosMapPage> createState() => _VerificentrosMapPageState();
}

class _VerificentrosMapPageState extends State<VerificentrosMapPage> {
  // --- Estado y Datos ---
  List<Verificentro> _filtered = [];
  Verificentro? _selected;
  LatLng? _userPos;

  /// Motor de búsqueda: Encuentra el centro más cercano a la posición del usuario.
  Future<void> _findNearestVerificentro() async {
    // 1. Solicita/Verifica permisos de ubicación nativos.
    // 2. Obtiene Lat/Lng actual mediante Geolocator.
    // 3. Aplica la fórmula de Haversine sobre el catálogo filtrado.
    // 4. Centra la cámara con un offset para dejar espacio a la tarjeta detalle.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Capa de Mapa: Marcadores personalizados y gestión de cámara.
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _cdmxCenter,
              zoom: 12,
            ),
            markers:
                _buildMarkers(), // Marcadores dinámicos normal vs seleccionado
            onMapCreated: (c) => _gm = c,
          ),

          // Capa de Filtros: Dropdowns para segmentar por Alcaldía.
          _buildFilters(),

          // Capa de UI Flotante: Acceso rápido a 'Centro Cercano' y 'Mi Ubicación'.
          _buildFloatingControls(),

          // Capa de Detalle: Tarjeta informativa con acciones de llamada y navegación externa.
          if (_selected != null) _buildBottomCard(_selected!),
        ],
      ),
    );
  }

  /// Genera marcadores reactivos al estado de selección.
  Set<Marker> _buildMarkers() {
    return _filtered
        .map(
          (v) => Marker(
            markerId: MarkerId(v.centroId!),
            position: LatLng(v.lat!, v.lng!),
            icon: (_selected == v) ? _pinSelected : _pinNormal,
            onTap: () => setState(() => _selected = v),
          ),
        )
        .toSet();
  }
}
