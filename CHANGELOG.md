# Changelog

## [0.1.0] - Foundation

### Añadido

- Estructura modular base para core, análisis, interfaz, visualizaciones y datos.
- Ciclo de vida controlado de módulos, registro de estado y limpieza en orden inverso.
- Observer de `Players`, personajes, partes y `Workspace` mediante APIs públicas de Roblox.
- Logger por niveles con historial limitado, suscripción y cancelación de suscripciones.
- Sesiones estadísticas en memoria y adaptador de guardado condicionado por autorización.
- Catálogo descriptivo de técnicas, con entradas marcadas explícitamente como no confirmadas.
- Auto Scan de solo lectura, limitado por presupuesto y precedido por confirmación del usuario.
- Clasificación `detected`/`estimated`/`unknown`; resumen con truncamiento y tiempo/ruta desconocidos.
- UI responsive de escritorio/móvil con menú, estado, scan, visualización, estadísticas, ajustes, log y ayuda.
- Renderer 3D local y minimapa 2D que comparten los resultados del escaneo.
- Notificaciones temporales y limpieza de UI/conexiones al destruir la aplicación.
- Mapeo Rojo y pruebas manuales ejecutables desde TestService.
- Documentación de permisos, alcance, limitaciones y hoja de ruta.

### No incluido

- Inyección, APIs de executor, evasión, movimiento automatizado o control de terceros.
- Predicción completa de saltos (planificada para v0.2.0).
- Route Intelligence o afirmaciones de rutas óptimas (planificada desde v0.5.0).
- Estimación de tiempo de recorrido o aprendizaje automático real.
