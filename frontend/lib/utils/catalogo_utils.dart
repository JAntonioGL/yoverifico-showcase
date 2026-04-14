// lib/utils/catalogo_utils.dart
import 'package:yoverifico_app/models/vehiculo_modelos.dart';
import 'package:yoverifico_app/providers/catalogo_provider.dart';
import 'package:yoverifico_app/models/vehiculo_registrado.dart';

/// Retorna el nombre de la línea por id, o 'No encontrada'
String nombreLineaPorId(CatalogoProvider c, int lineaId) {
  for (final l in c.lineas) {
    if (l.id == lineaId) return l.nombre;
  }
  return 'No encontrada';
}

/// Retorna el nombre de la marca por id, o 'No encontrada'
String nombreMarcaPorId(CatalogoProvider c, int marcaId) {
  for (final m in c.marcas) {
    if (m.id == marcaId) return m.nombre;
  }
  return 'No encontrada';
}

/// Retorna el id de la marca asociada a una línea, o null si no existe
int? marcaIdPorLinea(CatalogoProvider c, int lineaId) {
  for (final l in c.lineas) {
    if (l.id == lineaId) return l.marcaId;
  }
  return null;
}

/// Retorna el nombre de la marca usando el id de la línea
String nombreMarcaPorLineaId(CatalogoProvider c, int lineaId) {
  final mid = marcaIdPorLinea(c, lineaId);
  if (mid == null) return 'No encontrada';
  return nombreMarcaPorId(c, mid);
}

/// Etiqueta lista para mostrar: "Marca Línea" a partir del id de línea
String etiquetaMarcaLinea(CatalogoProvider c, int lineaId) {
  final marca = nombreMarcaPorLineaId(c, lineaId);
  final linea = nombreLineaPorId(c, lineaId);
  return '$marca $linea';
}

/// Etiqueta lista para mostrar a partir del vehículo registrado
String etiquetaVehiculo(CatalogoProvider c, VehiculoRegistrado v) {
  return etiquetaMarcaLinea(c, v.lineaId);
}

/// Texto de confirmación para eliminar: "ELIMINAR <Marca Línea>"
String textoConfirmacionEliminarVehiculo(
  CatalogoProvider c,
  VehiculoRegistrado v,
) {
  return 'ELIMINAR ${etiquetaVehiculo(c, v)}'.toUpperCase();
}

// Normaliza (minúsculas + sin acentos/espacios extra)
String _norm(String? s) {
  if (s == null) return '';
  var t = s.trim().toLowerCase();
  const repl = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ä': 'a',
    'ë': 'e',
    'ï': 'i',
    'ö': 'o',
    'ü': 'u',
    'à': 'a',
    'è': 'e',
    'ì': 'i',
    'ò': 'o',
    'ù': 'u',
    'â': 'a',
    'ê': 'e',
    'î': 'i',
    'ô': 'o',
    'û': 'u',
    'ñ': 'n'
  };
  repl.forEach((k, v) => t = t.replaceAll(k, v));
  t = t.replaceAll(RegExp(r'\s+'), ' ');
  return t;
}

/// ¿Hace match por placa, NOMBRE, marca o línea? (NO modelo)
bool matchVehiculoPorQuerySinModelo(
  CatalogoProvider c,
  VehiculoRegistrado v,
  String query,
) {
  final q = _norm(query);
  if (q.isEmpty) return true;

  final placa = _norm(v.placa);
  final nombre = _norm(v.nombre); // << incluye nombre

  final linea = c.lineas.firstWhere(
    (l) => l.id == v.lineaId,
    orElse: () => const LineaVehiculo(id: 0, nombre: 'n/d', marcaId: 0),
  );
  final marca = c.marcas.firstWhere(
    (m) => m.id == linea.marcaId,
    orElse: () => const MarcaVehiculo(id: 0, nombre: 'n/d'),
  );

  final marcaNombre = _norm(marca.nombre);
  final lineaNombre = _norm(linea.nombre);

  return placa.contains(q) ||
      nombre.contains(q) ||
      marcaNombre.contains(q) ||
      lineaNombre.contains(q);
}

/// Filtra por placa, NOMBRE, marca o línea (NO modelo)
List<VehiculoRegistrado> filtrarVehiculosPorQuery(
  CatalogoProvider c,
  Iterable<VehiculoRegistrado> vehiculos,
  String query,
) {
  final q = _norm(query);
  if (q.isEmpty) return vehiculos.toList();

  // Resultado por texto directo
  final base = vehiculos.where((v) => matchVehiculoPorQuerySinModelo(c, v, q));

  // Extra: si el texto coincide con una marca, regresa todas sus líneas
  final marcaIds = c.marcas
      .where((m) => _norm(m.nombre).contains(q))
      .map((m) => m.id)
      .toSet();

  if (marcaIds.isEmpty) return base.toList();

  final lineasDeEsasMarcas = c.lineas
      .where((l) => marcaIds.contains(l.marcaId))
      .map((l) => l.id)
      .toSet();

  // Une ambos criterios (texto directo + líneas por marca)
  return vehiculos.where((v) {
    if (matchVehiculoPorQuerySinModelo(c, v, q)) return true;
    return lineasDeEsasMarcas.contains(v.lineaId);
  }).toList();
}
