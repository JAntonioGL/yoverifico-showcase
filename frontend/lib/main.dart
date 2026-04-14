// main.dart - Arquitectura de YoVerifico
// Esta es una versión simplificada que describe la orquestación del sistema.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Importaciones de lógica de negocio (Arquitectura Provider)
import 'package:yoverifico_app/providers/usuario_provider.dart';
import 'package:yoverifico_app/providers/vehiculos_registrados_provider.dart';
import 'package:yoverifico_app/providers/contingencia_provider.dart';
import 'package:yoverifico_app/providers/planes_provider_v2.dart';

// Configuración avanzada de Google Sign In v7
// Se implementó el flujo basado en eventos (userDataEvents) para login/registro unificado.
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  // Implementación de Server Client ID para validación segura en backend (Node.js)
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Orquestación de Inyección de Dependencias
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => VehiculosRegistradosProvider()),
        ChangeNotifierProvider(create: (_) => ContingenciaProvider()),
        ChangeNotifierProvider(create: (_) => PlanesProviderV2()),
        // ... Otros providers de lógica de negocio
      ],
      child: const YoVerificoApp(),
    ),
  );
}

class YoVerificoApp extends StatefulWidget {
  const YoVerificoApp({super.key});

  @override
  State<YoVerificoApp> createState() => _YoVerificoAppState();
}

class _YoVerificoAppState extends State<YoVerificoApp> {
  
  @override
  void initState() {
    super.initState();
    _setupGoogleSignInListener();
    _setupPushNotifications();
  }

  /// IMPLEMENTACIÓN CRÍTICA: Google Sign In v7 (Event-Based)
  /// Se utiliza el nuevo modelo de Streams de Google para manejar la persistencia
  /// y autenticación reactiva tanto en Login como en Registro.
  void _setupGoogleSignInListener() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (account != null) {
        // Lógica de intercambio de tokens con el Backend (SSV)
        // Se valida el idToken contra la API Node.js para garantizar integridad.
      }
    });
    _googleSignIn.signInSilently(); // Silent Login para persistencia de sesión
  }

  /// Gestión de Notificaciones Push (Firebase Cloud Messaging)
  void _setupPushNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Motor de reacciones a alertas de contingencia o verificación
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Deep Linking basado en el contenido de la notificación
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YoVerifico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      
      // SISTEMA DE RUTAS DINÁMICAS
      // Se utiliza onGenerateRoute para manejar flujos complejos de navegación
      // y argumentos entre pantallas (Vehículos, Detalles, Historial).
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Implementación de AuthGate y gestión de stack de navegación
        return MaterialPageRoute(builder: (context) => const WelcomeScreen());
      },
    );
  }
}