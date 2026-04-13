#  Backend - Node.js API Service

Esta carpeta contiene la documentación y especificación técnica del servidor de **YoVerifico**. El backend está diseñado bajo una arquitectura de microservicios, utilizando contenedores para garantizar un despliegue consistente y escalable.

## Diagrama de Flujo de Petición

![Flujo de Petición del Backend de YoVerifico](https://raw.githubusercontent.com/JAntonioGL/yoverifico-showcase/main/assets/arquitectura-backend.png)
*(Sube tu imagen a la carpeta assets o raíz y asegúrate de que el nombre coincida aquí)*

---

##  Arquitectura y Estructura
El servidor está desarrollado con **Node.js** y **Express**, siguiendo un patrón modular que separa las responsabilidades en capas claras:

* **`/routes`**: Definición de puntos de entrada (Endpoints). Segmentado por recursos (Auth, Vehículos, Notificaciones, Planes).
* **`/controllers`**: Orquestación de la lógica de negocio.
* **`/middlewares`**: Capa de seguridad y validación (Auth JWT, RBAC, Rate Limiting).
* **`/services`**: Integraciones externas (Azure Mailer, Firebase Admin SDK).
* **`/config`**: Gestión de variables de entorno y configuraciones de servicios (Ads, DB).

---

## Containerización y DevOps

Para garantizar la estabilidad en producción, el sistema utiliza una estrategia de containerización avanzada:

### Docker Optimization
* **Multi-stage Builds**: El `Dockerfile` utiliza una etapa de `deps` para instalar dependencias de producción y una etapa de `runtime` ligera basada en **Alpine Linux** para minimizar la superficie de ataque y el tamaño de la imagen.
* **Security**: El contenedor se ejecuta bajo un usuario no-root (`app`) para seguir el principio de menor privilegio.

### Process Management
En el entorno de producción, se utiliza **PM2 (Runtime Mode)** configurado en modo clúster.
* **Alta Disponibilidad**: El servidor levanta múltiples workers (instancias) para aprovechar todos los núcleos de la CPU del VPS.
* **Auto-healing**: PM2 reinicia automáticamente cualquier instancia que falle.

---

##  Estrategia de Seguridad y Resiliencia

1.  **Rate Limiting Dinámico**: Implementación de límites de peticiones basados en IP y cuenta de usuario mediante **Redis**. Se aplican reglas estrictas para procesos sensibles como la generación de OTP y el borrado de cuentas.
2.  **Validación de Integridad**: El sistema incluye validaciones de **Server Side Verification (SSV)** para integraciones de publicidad (AdMob) y webhooks, previniendo fraudes.
3.  **Observabilidad**: El servidor incluye un módulo de diagnóstico en el arranque que verifica permisos de carpetas críticas (ej. subida de logs de bugs) y muestra una tabla de configuración activa para facilitar el mantenimiento.

---

##  Despliegue (Orquestación)

El despliegue se gestiona mediante **Docker Compose**, manteniendo entornos aislados:

* **Producción (`docker-compose.prod.yml`)**: Configura el reinicio automático (`unless-stopped`), gestión de logs con rotación automática (máximo 30MB) para prevenir el llenado del disco en el VPS, y redes privadas para la comunicación con Redis.
* **Desarrollo (`docker-compose.dev.yml`)**: Configura volúmenes para *hot-reload* y levanta una instancia local de **PostgreSQL 17** para pruebas de integración.

---

> **Tecnologías Clave:** Node.js, Docker, Redis, PM2, Firebase Admin, Azure Mail Service.