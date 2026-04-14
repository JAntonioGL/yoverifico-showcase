# 🛠️ Capa de Utilidades y Motores de Lógica (Utils)

Esta carpeta centraliza los motores de cálculo, algoritmos de inferencia y herramientas de soporte que permiten a **YoVerifico** operar de forma autónoma, resiliente y segura. Aquí reside la inteligencia que traduce normativas legales de tránsito en reglas de software ejecutables.

## 🧠 Motores de Inferencia Destacados

### 1. Motor de Verificación y Estados (`verificacion_utils.dart`)
Es el núcleo lógico encargado de determinar la salud legal de un vehículo en tiempo real mediante un sistema de estados reactivos:
* **Evaluación Multicriterio:** Clasifica el estatus vehicular (Sin registro, Vencido, Por vencer, Vigente) analizando hologramas y fechas críticas.
* **Algoritmo de Alerta Temprana:** Implementa una ventana de criticidad de 7 días antes del vencimiento para disparar notificaciones preventivas automáticas.
* **Normalización Temporal:** Gestión de comparaciones de fechas (`_dateOnly`) para garantizar precisión en los cambios de estatus semestrales.

### 2. Motor de Inferencia "No Circula" (`no_circula_utils.dart`)
Módulo diseñado para maximizar la utilidad de la app incluso ante la falta de datos del usuario, operando bajo un modelo de predicción:
* **Heurística de Hologramas:** Infiere el holograma probable basado en el año de manufactura del vehículo y las normativas ambientales de la Megalópolis.
* **Cálculo de Ventanas Semestrales:** Proyecta la próxima fecha límite de verificación cruzando el calendario oficial (engomados) con el último dígito de la placa capturada.

## 🛡️ Seguridad y Optimización

### 3. Orquestador de reCAPTCHA (`captcha_manager.dart`)
Gestión avanzada de seguridad para flujos sensibles (Auth/Recuperación) sin comprometer la UX:
* **Patrón Completer:** Maneja solicitudes de tokens concurrentes de forma asíncrona, evitando colisiones o bloqueos en el WebView.
* **Estrategia de Cache & Prewarm:** Implementa un sistema de "pre-calentamiento" y validación de frescura de tokens (< 60s) para asegurar que el usuario nunca espere por una validación de seguridad.
* **Resiliencia Operativa:** Manejo de Timeouts y limpieza de estado automática para prevenir fugas de memoria o uso de tokens expirados.

### 4. Utilidades de Catálogo (`catalogo_utils.dart`)
Capa de abstracción para la gestión eficiente de la base de datos de vehículos:
* **Motor de Búsqueda Normalizada:** Implementa lógica de filtrado difuso que ignora acentos, mayúsculas y espacios, permitiendo búsquedas rápidas por marca, línea o placa.
* **Resolución Dinámica de IDs:** Traduce identificadores relacionales del backend en etiquetas legibles para la interfaz de usuario en tiempo real.

## 🛠️ Stack Tecnológico Interno
* **Programación Asíncrona Proactiva:** Uso de `Completer` y `Future` para flujos de seguridad no bloqueantes.
* **Algoritmia Temporal:** Manipulación avanzada de `DateTime` para el cálculo de periodos fiscales y semestres naturales.
* **Abstracción de Datos:** Desacoplamiento total de la lógica de negocio frente a la capa visual, facilitando el mantenimiento y las pruebas unitarias.

---

> **Nota:** La lógica contenida en estas utilidades cumple con las normativas vigentes de la Secretaría del Medio Ambiente (SEDEMA), permitiendo a la aplicación actuar como un asistente legal preventivo para el conductor.