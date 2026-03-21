# Roadmap de Producto (90 días)

## Visión
Convertir Juji en un sistema de control personal diario que conecte productividad, finanzas y hábitos con decisiones accionables.

## Objetivos del trimestre
- Aumentar la frecuencia de uso semanal (WAU).
- Mejorar la finalización de flujos clave (reporte diario, registro de movimiento, cierre del día).
- Incrementar la retención con valor visible semana a semana.

## KPI principales
- WAU/MAU.
- % de usuarios que completan reporte diario al menos 4 días por semana.
- % de usuarios que registran al menos 8 movimientos por mes.
- % de usuarios con al menos 1 meta activa y seguimiento semanal.
- Tiempo promedio para completar “cierre del día”.

---

## Fase 1 (Semanas 1-3): Fundación de valor

### Objetivo
Unificar el valor actual en una experiencia clara y medible.

### Iniciativas
1. Dashboard ejecutivo semanal.
2. Alertas inteligentes iniciales.
3. Búsqueda global básica.
4. UX móvil primero en flujos críticos.

### Entregables
- Vista semanal con 6 indicadores:
  - hábitos cumplidos
  - gasto vs presupuesto
  - tareas cerradas
  - bloqueos abiertos
  - reportes enviados
  - balance semanal
- Reglas de alerta MVP:
  - presupuesto superado
  - 3 días sin reporte
  - proyecto sin avances
- Búsqueda en reportes, transacciones, proyectos y compras.
- Mejora de formularios móviles para alta rápida.

### Criterios de éxito
- +20% de sesiones semanales vs línea base.
- >= 60% de usuarios activos interactúan con el dashboard semanal.
- Reducción de >= 20% en tiempo de carga percibido en móvil de formularios críticos.

### Dependencias
- Modelos de datos consistentes entre módulos.
- Instrumentación básica de eventos (analítica).

---

## Fase 2 (Semanas 4-6): Diferenciación del producto

### Objetivo
Conectar módulos para generar insights de mayor valor.

### Iniciativas
1. Relación entre módulos (gastos ↔ proyectos/hábitos).
2. Metas mensuales.
3. Insights automáticos semanales y mensuales.
4. Plantillas de reporte diario por perfil.

### Entregables
- Asociación de transacciones con proyecto/hábito.
- Vista de costo por objetivo.
- Configuración de metas (ahorro, salud, productividad).
- Resumen automático con recomendaciones.
- Plantillas de reporte por tipo de trabajo.

### Criterios de éxito
- >= 35% de movimientos enlazados a un objetivo (proyecto/hábito).
- >= 30% de usuarios activos crean al menos 1 meta.
- >= 40% de visualización de insights semanales en usuarios activos.

### Dependencias
- Nuevas relaciones de base de datos y migraciones.
- Reglas de negocio para cálculo de progreso y recomendaciones.

---

## Fase 3 (Semanas 7-9): Retención y hábito

### Objetivo
Aumentar constancia y adherencia diaria.

### Iniciativas
1. Rachas y logros.
2. Recordatorios configurables.
3. Modo “cierre del día” guiado.

### Entregables
- Sistema de rachas visible en hábitos/reportes.
- Catálogo inicial de logros.
- Configuración de recordatorios por horario y frecuencia.
- Flujo guiado de 3 pasos:
  - reporte
  - movimientos
  - tareas

### Criterios de éxito
- +15% de retención semana 4.
- >= 50% de usuarios activos completa “cierre del día” al menos 3 veces por semana.
- >= 25% de recuperación de usuarios inactivos con recordatorios.

### Dependencias
- Notificaciones in-app estables.
- Persistencia confiable de estado de progreso diario.

---

## Fase 4 (Semanas 10-12): Escalado y colaboración

### Objetivo
Habilitar crecimiento y casos de uso compartidos.

### Iniciativas
1. Multiusuario básico.
2. Exportaciones útiles (PDF/CSV).
3. Roles y permisos simples.

### Entregables
- Invitaciones y espacios compartidos básicos.
- Roles:
  - owner
  - colaborador
  - solo lectura
- Exportación por módulo y rango de fechas.

### Criterios de éxito
- >= 10% de usuarios activos crea al menos un espacio compartido.
- >= 20% de usuarios activos usa exportación al menos 1 vez al mes.
- 0 incidentes críticos de permisos en producción.

### Dependencias
- Sistema de autorización y políticas.
- Auditoría de cambios en recursos compartidos.

---

## Backlog priorizado (Now / Next / Later)

### Now
- Dashboard semanal.
- Alertas MVP.
- Búsqueda global.
- Optimización móvil de formularios.

### Next
- Metas mensuales.
- Insights automáticos.
- Vínculo gastos con proyectos/hábitos.
- Plantillas de reporte.

### Later
- Rachas y logros avanzados.
- Recordatorios inteligentes adaptativos.
- Multiusuario con permisos finos.
- Exportes programados automáticos.

---

## Riesgos y mitigación
- Riesgo: sobrecarga de funcionalidades sin adopción.
  - Mitigación: liberar por fases con feature flags y validación de KPI.
- Riesgo: complejidad de modelos cruzados (finanzas + proyectos + hábitos).
  - Mitigación: introducir asociaciones progresivas y pruebas de regresión.
- Riesgo: fatiga por alertas.
  - Mitigación: priorización y límites de frecuencia por usuario.

## Cadencia de seguimiento
- Revisión semanal de métricas y feedback cualitativo.
- Revisión quincenal de roadmap (ajuste por impacto real).
- Demo interna al final de cada fase con decisión go/no-go de la siguiente.
