D:\proyectos\smart_meds_V2>flutter analyze

┌─────────────────────────────────────────────────────────┐
│ A new version of Flutter is available!                  │
│                                                         │
│ To update to the latest version, run "flutter upgrade". │
└─────────────────────────────────────────────────────────┘
Analyzing smart_meds_V2...
No issues found! (ran in 3.7s)

D:\proyectos\smart_meds_V2>flutter test
00:07 +1: All tests passed!

D:\proyectos\smart_meds_V2>


# AGENTS.md - Contexto y Reglas para Agentes de IA

Este archivo define el contexto del proyecto y las reglas estrictas de interacción que los agentes de IA (como Antigravity) deben seguir al trabajar en **Smart Med V2**.

## Objetivo del Proyecto
Crear una aplicación eficiente y práctica para la gestión del botiquín del hogar, permitiendo un manejo claro del inventario personal y facilitando la búsqueda por medicamentos o malestares.

## Resumen del Producto
Smart Med V2 es la evolución desde cero del proyecto original. Incluirá un catálogo global moderado y un inventario privado por usuario, enfoque en la practicidad y resolución de problemas reales del botiquín doméstico. 

## Reglas de Interacción Acordadas

1. **Trabajar por Fases:** El desarrollo se divide en fases estrictas. No se deben adelantar funcionalidades de fases futuras.
2. **Entregar Archivos Completos:** Cero opciones ambiguas, cero pseudocódigo y cero cambios parciales. Los archivos modificados o creados deben entregarse completos y funcionales.
3. **Rutas Reales:** No asumir rutas inexistentes. Trabajar exclusivamente con las rutas proporcionadas.
4. **Respetar la Raíz:** Todo el trabajo se realiza obligatoriamente en el directorio local:
   `D:\proyectos\smart_meds_V2`
5. **Aislamiento de V1:** Smart Med V1 no debe ser modificado, tocado ni alterado. Se mantiene exclusivamente como referencia.
6. **Regla de OCR:** No se utilizará Gemini para la funcionalidad de OCR en V2. El OCR será local en fases futuras.
7. **Regla de Dominio:** No se debe mezclar el catálogo global y el inventario privado en la misma entidad de dominio; deben permanecer estrictamente separados.
8. **Configuración MCP:** `CODINGBUDDY_PROJECT_ROOT` es la única variable de entorno válida de referencia para la raíz del proyecto dentro de `mcp_config.json`. No inventar otras variables para la ruta del proyecto.
9. **Sin Placeholders Falsos:** No introducir placeholders técnicos ficticios en configuraciones del proyecto; toda configuración debe ser real, válida o declararse explícitamente como pendiente futura sin comandos falsos.
10. **Arquitectura Real:** Smart Med V2 usa arquitectura feature-first con capas por feature cuando aplique. No crear archivos vacíos sin propósito.
11. **Fakes Permitidos en Fases Tempranas:** En fases tempranas se permiten fake repositories en memoria cuando sirven para validar arquitectura y flujos sin introducir infraestructura real.
12. **Abstracción de Servicios de Captura:** La feature de Intake debe depender de interfaces de dominio para servicios de captura (Barcode, OCR). Esto permite que el flujo sea robusto y esté preparado para conectar implementaciones reales (cámara, hardware) en fases futuras sin reescribir la lógica de negocio.
13. **Separación de Dominio y Data (DTOs):** Las entidades de dominio deben permanecer puras y libres de lógica de infraestructura (como serialización JSON). Se deben utilizar modelos/DTOs en la capa de data para manejar la persistencia y comunicación externa, con mappers claros hacia/desde el dominio.
14. **Reglas de Coherencia de Inventario:** El inventario debe evitar duplicados combinando cantidades cuando se agrega un medicamento con el mismo ID de catálogo (o nombre normalizado si es desconocido) y la misma fecha de vencimiento.
