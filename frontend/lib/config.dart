// lib/config.dart.sample
// Ejemplo de configuración centralizada y manejo de variables de entorno.

import 'dart:io' show Platform;

// --- Configuración de API ---
// Se utiliza --dart-define para inyectar la URL base en tiempo de compilación.
const String backendBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://api-staging.yoverifico.com.mx',
);

// --- Identificadores de Firebase / Google Sign-In ---
// IMPORTANTE: Sustituir por IDs propios de la consola de Google Cloud.
const String androidClientId = 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';
const String webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

// --- Gestión de Publicidad (Google Mobile Ads) ---
class AdIds {
  // Se utilizan los IDs de prueba oficiales de AdMob para el entorno de desarrollo.
  static String get banner => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Test ID Android
      : 'ca-app-pub-3940256099942544/2934735716'; // Test ID iOS

  static String get rewarded => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';
}

// --- Políticas de Cache y Versión ---
const int VERSION_POLICY_TTL_VALUE = 1;
const String VERSION_POLICY_TTL_UNIT = 'h'; // Soporta 'm', 'h', 'd'

// Determina el tiempo de gracia antes de consultar nuevamente al servidor 
// por actualizaciones críticas o cambios en el estado de contingencia.
Duration versionPolicyTtlFromConfig() {
  final v = VERSION_POLICY_TTL_VALUE;
  switch (VERSION_POLICY_TTL_UNIT) {
    case 'h': return Duration(hours: v);
    case 'd': return Duration(days: v);
    default: return Duration(minutes: v);
  }
}

// --- Enlaces y Mensajería ---
const String urlCalificacionYoVerifico = 'https://play.google.com/store/apps/details?id=com.yoverifico.app';
const String mensajeCompartirYoVerifico = '¡Yo uso YoVerifico para que no se me pase la verificación! Descárgala aquí: https://yoverifico.com.mx';