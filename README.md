# S23 Smart TAS

**Versión:** 0.1.0

**Organización:** Buendia's Studios

**Estado:** Foundation observacional experimental, concebida para experimentación temporal en móviles. La ejecución con Delta **no está verificada** y no se declara compatible. No es un TAS automático, un optimizador de rutas ni un sistema de aprendizaje automático.

S23 Smart TAS es una base modular para estudiar recorridos de plataformas en experiencias propias o autorizadas. Registra geometría observable del `Workspace`, datos de sesión locales y velocidad actual del personaje. No mueve al jugador ni automatiza controles.

## Alcance real de v0.1.0

Implementado:

- Inicialización controlada, estados por módulo y limpieza inversa de componentes.
- Observer de `Players`, `Workspace`, personajes y partes usando APIs normales de Roblox.
- Logger con niveles, historial acotado y suscriptores.
- Sesión estadística en memoria; adaptador de persistencia solo si el proyecto anfitrión lo autoriza e inyecta.
- Auto Scan acotado y de solo lectura, con confirmación visible antes de cada ejecución.
- Etiquetas `detected`, `estimated` y `unknown`; los roles geométricos heurísticos son estimaciones, no hechos sobre la lógica del juego.
- Interfaz adaptable, panel de estadísticas, ajustes funcionales, registro y notificaciones.
- Renderer 3D local no colisionable y minimapa 2D sincronizados con el mismo resultado.
- Pruebas que se pueden ejecutar en Roblox Studio mediante TestService.

No implementado: predicción de saltos, estimación de tiempo de recorrido, búsqueda/optimización de rutas, captura de input, control automático o aprendizaje automático. El tiempo y la ruta se informan como desconocidos/no implementados, no se simulan.

## Arquitectura

```text
main.lua                 Composición y ciclo de vida de la aplicación
config.lua               Límites, tema y validación de configuración
core/
  init.lua               Registro, estado, inicio y limpieza de módulos
  observer.lua           Lecturas observacionales de Roblox
  logger.lua             Historial limitado y eventos de log
interface/
  menu.lua               Acciones, confirmación y panel adaptativo
  adaptive.lua           Distribución para móvil/escritorio
  notifications.lua      Notificaciones temporales
scanner/
  scanner.lua            Recorrido acotado y resumen del Workspace
  map_analyzer.lua       Clasificación explícita/heurística/desconocida
visuals/
  renderer_3d.lua        Adornos locales y marcador de posición observada
  minimap_2d.lua         Proyección local X/Z del mismo escaneo
data/
  session.lua            Estadísticas de sesión y persistencia autorizada
  techniques.lua         Técnicas descriptivas no confirmadas
tests/                   Pruebas para TestService (Studio; no ejecutadas)
bootstrap.client.lua     Arranque opcional para un proyecto mapeado
default.project.json     Mapeo opcional para la futura etapa Rojo/Studio
```

Los elementos solo se etiquetan `detected` cuando existe el atributo observable `SmartTAS_Type` con valor `platform`, `obstacle` o `checkpoint`. Los nombres y dimensiones producen, como máximo, una etiqueta `estimated`. Geometría que no se puede clasificar queda `unknown`. Una etiqueta no verifica colisiones, progreso ni reglas internas del juego. En este contexto, «visible» significa que la pieza no es totalmente transparente; no se calcula oclusión respecto de la cámara.

## Entornos y compatibilidad

El objetivo de producto de v0.1.0 es la experimentación temporal en dispositivos móviles mediante Delta. Sin embargo, no se han realizado pruebas reales en Delta: **no se garantiza ni se declara que esta versión, su interfaz táctil o alguna función se ejecute allí**. No se incluye cargador, `loadstring` ni dependencia de APIs exclusivas de Delta. No ejecutes el proyecto en experiencias ajenas; cualquier experimentación debe limitarse a experiencias propias o autorizadas y respetar sus reglas.

El código de interfaz utiliza controles Roblox (`GuiButton.Activated`) y adapta el panel principal al viewport/táctil. Eso expresa intención de uso móvil, pero no equivale a compatibilidad comprobada en Delta ni en un dispositivo real. El minimapa todavía tiene tamaño y posición fijos.

| Entorno | Qué puede afirmarse en v0.1.0 |
|---|---|
| Delta en móvil | Entorno temporal previsto, pero no probado. No se confirma el arranque, la UI táctil, el escaneo ni las visualizaciones. |
| Cliente Roblox en una experiencia propia/autorizada | El código está diseñado para las APIs estándar `Players`, `Workspace`, `PlayerGui` y `RunService`; requiere que el anfitrión coloque los módulos en la jerarquía esperada. No se ha validado en ejecución. |
| Roblox Studio / TestService | Etapa de migración y validación futura. Las pruebas están escritas para Studio, pero aún no se han ejecutado. |
| Rojo | Empaquetado/sincronización opcional para esa futura etapa; Rojo no es el runtime ni un requisito del módulo `Main.Init`. |

`main.lua` es el punto de composición: requiere módulos hermanos mediante `script.Parent`. `bootstrap.client.lua` es solo un arranque opcional para el árbol de instancias del proyecto Rojo; no es el arranque principal universal y no añade compatibilidad con Delta.

## Migración futura a Roblox Studio

Cuando comience la etapa de migración, se podrá sincronizar el proyecto mediante Rojo y el plugin de Rojo. Desde la raíz del proyecto:

```powershell
rojo serve default.project.json
```

Conecta el plugin de Rojo a la sesión local. `default.project.json` describe los módulos en `ReplicatedStorage.S23SmartTAS`, el arranque opcional en `StarterPlayerScripts` y las pruebas en `TestService`. También se podrá construir un archivo de lugar para abrirlo en Studio:

```powershell
rojo build default.project.json -o S23SmartTAS.rbxlx
```

Este flujo de empaquetado es para desarrollo futuro en Studio; no demuestra que el paquete funcione en Delta. En el cliente Roblox, el script inicializa una interfaz local; el escaneo no se ejecuta hasta pulsar **Auto Scan** y después **Confirmar escaneo**.

### Inicialización manual en un cliente Roblox

En un `LocalScript` de una experiencia autorizada:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Main = require(ReplicatedStorage.S23SmartTAS.main)
local app = Main.Init()

script.Destroying:Connect(function()
	app:Destroy()
end)
```

No incluyas una segunda inicialización simultánea en el mismo cliente. `app:Destroy()` detiene conexiones, UI, adornos y componentes. La persistencia está desactivada por omisión; una experiencia propia puede proporcionar un adaptador y autorización explícita al inicializador, nunca claves ni credenciales dentro del repositorio.

## Flujo de Auto Scan

1. Pulsa **Auto Scan**.
2. Lee el aviso de alcance y confirma que tienes permiso.
3. Pulsa **Confirmar escaneo** o cancela; sin confirmación no se inspecciona el `Workspace`.
4. Se recorre una cantidad acotada de descendientes. Las partes invisibles se excluyen.
5. Se muestran recuentos, truncamiento y estado de clasificación. El escáner no cambia instancias del juego.
6. Si activas **Panel visual 3D + 2D**, ambas vistas consumen el mismo resultado. Antes del primer escaneo muestran solo la posición observada; después representan los datos clasificados. El renderer destruye sus adornos 3D al desactivarse; el minimapa se oculta y ambos componentes limpian sus recursos al destruir la aplicación.

El botón de configuración alterna el presupuesto del próximo escaneo. Estadísticas y registro muestran datos reales de esta sesión; no hay valores de demostración. Si faltan datos, la interfaz los declara desconocidos.

## Permisos y datos

- Solo experiencias propias o autorizadas.
- Se usan servicios públicos de Roblox en el cliente; no hay acceso a memoria, red privada, remotos de terceros ni datos internos del servidor.
- No hay automatización del jugador, modificación del movimiento, evasión de seguridad ni inyección.
- Las estadísticas son locales y efímeras por defecto. Guardar requiere un adaptador disponible y autorización explícita del anfitrión.
- Los adornos se crean en el cliente y no alteran las piezas observadas.

## Pruebas

Las pruebas están mapeadas a `TestService`. En Roblox Studio abre la consola/Command Bar en un lugar que contenga el proyecto y ejecuta:

```lua
local tests = game:GetService("TestService"):WaitForChild("S23SmartTASTests")
local result = require(tests:WaitForChild("test_runner")).Run()
print(result.passed, result.failed, result.total)
```

La suite está diseñada para comprobar configuración, límites/eventos del logger, persistencia de sesión autorizada, carga de todos los módulos, estados e inicio/limpieza del core, fallos controlados, clasificaciones del escáner, límite de recorrido y layout móvil/escritorio. Si una aserción falla, `Run()` genera un error; no informa éxito. No comprueba ejecución en Delta, controles táctiles físicos, integración visual 3D/2D ni compatibilidad real de mapas.

En el entorno de desarrollo que originó esta versión no hay Roblox Studio, Rojo ni un runtime/analizador LuaU instalado. Por eso las pruebas de TestService y la compilación Rojo no se declaran ejecutadas localmente. GitHub almacena el código; **GitHub no ejecuta Roblox ni sustituye Roblox Studio/TestService**.

## Limitaciones conocidas

- La interpretación por tamaño/nombre es heurística y puede ser incorrecta.
- La visibilidad usa transparencia de las partes, no oclusión de cámara ni raycasts.
- El escaneo puede truncarse en mapas grandes; bajar el presupuesto puede omitir instancias.
- La velocidad actual no es una predicción de llegada ni una medida de tiempo de speedrun.
- La sesión no se conserva entre ejecuciones en la configuración predeterminada.
- La UI, geometría y características de cada experiencia pueden variar; modo experimental.
- La predicción de saltos y las rutas verificadas no existen en esta versión.

## Hoja de ruta

| Versión | Objetivo |
|---|---|
| v0.2.0 | Predicción de saltos experimental con validación y límites de confianza explícitos. |
| v0.3.0 | Métricas temporales de segmentos observados y calibración por experiencia autorizada. |
| v0.4.0 | Herramientas de revisión/visualización de recorridos registrados. |
| v0.5.0 | Interfaces de Route Intelligence; no prometer rutas óptimas sin datos validados. |
| v0.6.0 | Persistencia configurable para experiencias propias con permisos del servidor. |
| v0.7.0 | Ampliación de técnicas respaldadas por sesiones verificables. |
| v0.8.0 | Accesibilidad, rendimiento móvil y compatibilidad de interfaz. |
| v0.9.0 | Estabilización, pruebas en experiencias de referencia autorizadas y documentación. |
| v1.0.0 | Liberación solo después de validación funcional, seguridad y compatibilidad. |
