class LineaVehiculo {
  final int id;
  final String nombre;
  final int marcaId; // <-- Campo para el ID de la marca

  const LineaVehiculo(
      {required this.id, required this.nombre, required this.marcaId});

  factory LineaVehiculo.fromJson(Map<String, dynamic> json) {
    return LineaVehiculo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      marcaId: json['marca_id'] as int, // <-- Aquí se mapea el JSON
    );
  }
}

class MarcaVehiculo {
  final int id;
  final String nombre;

  const MarcaVehiculo({required this.id, required this.nombre});

  factory MarcaVehiculo.fromJson(Map<String, dynamic> json) {
    return MarcaVehiculo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
    );
  }
}

class ColorVehiculo {
  final int id;
  final String nombre;
  final String hex;

  const ColorVehiculo({
    required this.id,
    required this.nombre,
    required this.hex,
  });

  factory ColorVehiculo.fromJson(Map<String, dynamic> json) {
    return ColorVehiculo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      hex: json['hex'] as String,
    );
  }
}

class EstadoMexico {
  final int id;
  final String nombre;
  final String abrev;

  const EstadoMexico(
      {required this.id, required this.nombre, required this.abrev});

  factory EstadoMexico.fromJson(Map<String, dynamic> json) {
    return EstadoMexico(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      abrev: json['abrev'] as String,
    );
  }
}

class EngomadoData {
  final String color;
  final String periodo1; // Primer periodo de verificación
  final String periodo2; // Segundo periodo de verificación

  const EngomadoData({
    required this.color,
    required this.periodo1,
    required this.periodo2,
  });
}
// Tus modelos LineaVehiculo y MarcaVehiculo también deberían estar aquí o en un archivo similar.
