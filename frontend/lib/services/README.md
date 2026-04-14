# 🚀 Capa de Servicios y Lógica de Negocio (Services)

Esta carpeta constituye el motor operativo de **YoVerifico**. Aquí se gestiona la comunicación con el backend (Node.js), el ciclo de vida de la sesión, el sistema de pagos y la persistencia de datos sensibles.

## 🛡️ Servicios Core y Seguridad

### 1. Gestión de Identidad y Acceso (`auth_service.dart`)
Centraliza la seguridad de la aplicación mediante un sistema de autenticación proactiva:
* **Estrategia JWT Dual:** Implementa el uso de *Access Tokens* en memoria y *Refresh Tokens* cifrados mediante **Flutter Secure Storage** (AES-256).
* **Auto-Refresh Transparente:** Utiliza un patrón de interceptación de errores (401 Unauthorized) para renovar la sesión en segundo plano y reintentar peticiones de forma imperceptible para el usuario.
* **Analítica de Conversión:** Integra eventos de Firebase y Meta (Facebook App Events) para medir el éxito de registros y logueos.

### 2. Orquestador de Sesión (`session_service.dart`)
Funciona como el "director de orquesta" tras el arranque de la aplicación:
* **Hidratación Atómica:** Sincroniza simultáneamente el perfil del usuario, los derechos de suscripción y la flota vehicular en los Providers correspondientes.
* **Cierre de Sesión Seguro (Watchdog):** Implementa un flujo de limpieza profunda que elimina tokens de Firebase, desvincula cuentas de Google y resetea la persistencia local de forma atómica.

## 💰 Monetización y Flujos Transaccionales

### 3. Sistema de Facturación (`billing_service.dart`)
Gestiona el ciclo de vida de las suscripciones mediante **Google Play Billing**:
* **Server-Side Validation (SSV):** Implementa un flujo de validación cruzada donde cada compra es verificada por el backend contra los servidores de Google antes de liberar funciones premium.
* **Resiliencia de Transacción:** Manejo avanzado de errores como `ITEM_ALREADY_OWNED` y finalización manual de transacciones para evitar auto-reembolsos por parte de la Store.

### 4. Gateway de Acciones y Gating (`acciones_backend_service.dart`)
Controla la ejecución de tareas críticas vinculadas al modelo de negocio:
* **Patrón de Prechequeo/Folio:** Implementa un sistema de folios únicos que condiciona la ejecución de acciones (ej. agregar vehículo) al cumplimiento de requisitos previos, como la visualización de anuncios recompensados en planes gratuitos.

## 🚗 Inteligencia Vehicular y Soporte

### 5. Motor de Circulación (`circulacion_service.dart`)
Traduce las normativas de tránsito en lógica binaria ejecutable:
* **Algoritmo Sabatino:** Implementa la lógica de paridad y semana del mes para determinar restricciones de circulación en hologramas tipo 1 y 2.
* **Análisis Predictivo:** Capacidad de generar estados "Hipotéticos" basados en la antigüedad del vehículo cuando no existen datos de verificación oficiales.

### 6. Gestión de Soporte y Multimedia (`ticket_service.dart`)
Sistema de reporteo de errores con procesamiento de imágenes en el cliente:
* **Compresión Adaptativa:** Integra un motor que redimensiona y optimiza capturas de pantalla (quality: 85%) antes de la subida vía **Multipart/form-data** para ahorrar ancho de banda.

## 🔄 Control de Versiones y Resiliencia

### 7. Motor de Cumplimiento (`version_services.dart`)
Garantiza que la flota de usuarios opere bajo versiones compatibles:
* **Policy Enforcement:** Sistema de decisiones (OK, SOFT, HARD) que puede forzar actualizaciones críticas o bloquear el acceso a versiones obsoletas.
* **Caché con TTL:** Optimiza el arranque de la app mediante una política de tiempo de vida (Time To Live) para las políticas de versión, reduciendo la latencia en el *Cold Start*.

---

## 🏗️ Patrones de Diseño Aplicados
* **Singleton Pattern:** Todos los servicios mantienen una única instancia para preservar la consistencia del estado.
* **Resiliencia de Red:** Implementación de reintentos automáticos (*Retry con Fallback*) en servicios críticos como `vehiculo_service.dart`.
* **Desacoplamiento:** Los servicios operan de forma independiente a la UI, comunicándose exclusivamente a través de modelos y Providers.