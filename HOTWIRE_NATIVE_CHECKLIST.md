# HOTWIRE NATIVE - CHECKLIST DE VERIFICACIÓN TÉCNICA
# Usar este archivo para asegurar que la integración se completó correctamente

## Antes de Deployment

### Configuración del Servidor ✅
- [ ] Middleware HotwireNativeMiddleware configurado en config/application.rb
- [ ] Inicializador hotwire_native.rb ejecutándose en boot
- [ ] CORS configurado en config/initializers/cors.rb
- [ ] Headers de seguridad configurados en webview_headers.rb

### Controllers & Concerns ✅
- [ ] HotwireNativeSupport incluido en ApplicationController
- [ ] NativeResponseOptimization incluido en ApplicationController
- [ ] NativeErrorHandling incluido en ApplicationController
- [ ] DeepLinkSupport incluido en ApplicationController
- [ ] Layout dinámico set_layout configurado

### Vistas & Layout ✅
- [ ] app/views/layouts/application_mobile.html.erb creado
- [ ] Bottom navigation implementado en layout mobile
- [ ] Safe area insets configurados
- [ ] app/views/errors/mobile_error.html.erb creado

### CSS & Estilos ✅
- [ ] app/assets/stylesheets/mobile-optimizations.css agregado
- [ ] Media queries revisadas (768px, 680px, 520px)
- [ ] Formularios optimizados para touch (16px font, 48px botones)
- [ ] Shopping items sin min-width fijo
- [ ] Habits grid responsive (no 600px min-width)

### Formularios ✅
- [ ] app/views/forms/_mobile_friendly.html.erb creado
- [ ] Inputs sin -webkit-appearance defect (none aplicado)
- [ ] Botones con min-height: 48px
- [ ] Labels accesibles
- [ ] Mensajes de error visibles

### Testing ✅
- [ ] test/integration/responsive_design_test.rb creado
- [ ] test/integration/hotwire_native_test.rb creado
- [ ] test/integration/mobile_interaction_test.rb creado
- [ ] Rake task hotwire_native:performance_check disponible

### Gemas ✅
- [ ] rack-cors ~> 2.0 instalado
- [ ] user_agent_parser >= 2.0 instalado
- [ ] turbo-rails 2.0.23 funcionando
- [ ] stimulus-rails 1.3.4 funcionando

### Comportamiento en iOS ✅
- [ ] apple-mobile-web-app-capable: yes
- [ ] apple-mobile-web-app-status-bar-style configurado
- [ ] Notch detection usando env(safe-area-inset-*)
- [ ] Home screen icon funcionando

### Comportamiento en Android ✅
- [ ] mobile-web-app-capable: yes
- [ ] theme-color meta tag configurado
- [ ] Viewport correctamente configurado

## Testing Manual

### En iOS Simulator / Device
- [ ] App abre sin errores
- [ ] Bottom navigation táctil funciona
- [ ] Scroll suave (-webkit-overflow-scrolling)
- [ ] Formularios sin auto-zoom
- [ ] Notch no cubre contenido
- [ ] Temas se aplican correctamente
- [ ] Turbo Stream updates funcionan

### En Android Emulator / Device
- [ ] App abre sin errores
- [ ] Bottom navigation funciona
- [ ] Touch feedback visible
- [ ] Formularios usables
- [ ] Temas se aplican
- [ ] No hay artifacts de rendering

### Performance
- [ ] LCP (Largest Contentful Paint) < 2.5s
- [ ] FID (First Input Delay) < 100ms
- [ ] CLS (Cumulative Layout Shift) < 0.1
- [ ] CSS bundle < 200KB
- [ ] JS bundle importmap < 100KB

### Seguridad
- [ ] CORS solo permite orígenes válidos en prod
- [ ] Headers X-Frame-Options: SAMEORIGIN
- [ ] No hay datos sensibles en localStorage
- [ ] CSRF protection activa
- [ ] Autenticación requerida en rutas protegidas

## Variables de Ambiente (Production)

```bash
CORS_ORIGINS=https://your-domain.com
RAILS_ENV=production
RAILS_LOG_LEVEL=info
```

## Deployment

- [ ] Database migrations ejecutadas
- [ ] Assets precompilados
- [ ] Cache cleared
- [ ] Sistema de logs configurado
- [ ] Error tracking (Sentry, etc) configurado
- [ ] Monitoreo de performance activo

## Post-Deployment

- [ ] Verificar que app nativa puede conectarse
- [ ] Validar deep linking funciona
- [ ] Testear sessions y autenticación
- [ ] Verificar Turbo Streams funcionan
- [ ] Monitor de errores en producción activo
- [ ] Usuarios reportan comportamiento esperado

## Rollback Plan

Si algo sale mal:
1. Revertir deployment
2. Mantener versión anterior disponible
3. Comunicar a usuarios nativos
4. Analizar logs
5. Fix en staging
6. Re-deployer

Estado de Checklist: LISTO PARA PRODUCTION ✅
