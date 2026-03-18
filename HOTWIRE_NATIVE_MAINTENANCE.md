# HOTWIRE NATIVE - GUÍA DE MANTENIMIENTO

## Para el Equipo de Development

### 🔷 Entendimiento Básico

**¿Qué es Hotwire Native?**
- Framework que usa WebViews nativas de iOS/Android
- Ejecuta tu app Rails dentro de un contenedor nativo
- Una sola base de código para web, iOS y Android
- Diseñado por Basecamp/37signals

**¿Cómo funciona Juji con Hotwire Native?**
```
Usuario en mobile
    ↓
App nativa iOS/Android (Turbo Native wrapper)
    ↓
WebView (navegador embebido)
    ↓
Tu servidor Rails (localhost o remote)
    ↓
Responde igual que para web, pero con optimizaciones
```

### 🔧 Mantenimiento Día a Día

#### Agregando nuevas features

**Regla Oro:** Agrega features en Rails como normalmente, y funcionarán en mobile si sigues estas prácticas:

1. **Usa Turbo Frames para actualizaciones parciales**
```erb
<%= turbo_frame_tag "content" do %>
  <!-- Tu contenido que se actualiza -->
<% end %>
```

2. **Evita full page reloads**
```ruby
# ✅ BUENO
render turbo_stream: turbo_stream.replace("item", partial: "item")

# ❌ MALO
redirect_to @item (en contexts donde debería ser una actualización)
```

3. **Mantén formularios responsive**
```erb
<!-- ✅ BUENO -->
<input type="text" style="font-size: 16px; padding: 12px;">

<!-- ❌ MALO -->
<input type="text" style="font-size: 12px; padding: 2px;">
```

#### Modificando vistas

**Para web:**
- edit `app/views/layouts/application.html.erb`
- edit `app/views/*/index.html.erb` as normal

**Para mobile:**
- edit `app/views/layouts/application_mobile.html.erb`
- usa `mobile_friendly` partial en formularios
- check `mobile-optimizations.css` antes de custom styles

#### Agregando nuevas rutas

**Recuerda actualizar:**
1. `config/initializers/deep_linking.rb` con el nuevo patrón
2. Si requiere auth: agregarlo a `should_require_auth?`

#### CSS Changes

**Mobile-specific:**
```css
/* En app/assets/stylesheets/mobile-optimizations.css */
@media (max-width: 768px) {
  /* Mobile overrides */
}
```

**Responsive:**
```css
/* Usar clamp() para font sizes */
font-size: clamp(1rem, 3vw, 1.5rem);
```

---

### 🐛 Debugging

#### Verificar que cliente es Native

```ruby
# En controller
if hotwire_native_client?
  Rails.logger.info "Native client detected!"
end
```

#### Verificar headers

```bash
curl -H "User-Agent: TurboNative/1.0" http://localhost:3000/dashboard
# Debe ver: X-Hotwire-Native: true
```

#### Testing en navegador (simular mobile)

```javascript
// En console del browser
document.documentElement.setAttribute('data-platform', 'native')
```

#### Logs útiles

```bash
# Ver requests de native clients
grep "X-Hotwire-Native" log/development.log

# Ver errores de deep linking
grep "Deep Link" log/development.log
```

---

### ⚠️ Problemas Comunes & Soluciones

#### Problema: Formulario hace zoom en iOS

**Causa:** Font size < 16px en inputs  
**Solución:**
```css
input { font-size: 16px !important; }
```

#### Problema: Layout roto en mobile

**Causa:** min-width o max-width inline styles  
**Solución:**
```html
<!-- ❌ MALO -->
<div style="min-width: 400px">

<!-- ✅ BUENO -->
<div style="min-width: auto; max-width: 100%;">
```

#### Problema: Teclado virtual no se cierra

**Causa:** Falta de touch-action en form  
**Solución:**
```css
button { touch-action: manipulation; }
```

#### Problema: Notch cubre contenido

**Causa:** padding-top no considerado  
**Solución:**
```css
body {
  padding-top: max(20px, env(safe-area-inset-top));
}
```

#### Problema: Turbo Stream no actualiza en mobile

**Causa:** Wrong Turbo-Frame header  
**Solución:**
```ruby
# Verificar que estás respondiendo al frame correcto
render turbo_stream: turbo_stream.replace("frame_id", partial: "partial")
```

---

### 📊 Monitoreo

#### Crear alertas para:

1. **Performance degradation**
```bash
# Watch: LCP > 2.5s
# Watch: FID > 100ms
# Watch: CLS > 0.1
```

2. **Error rates**
```bash
# Logs: 5xx errors en native clients
tail -f log/production.log | grep "X-Hotwire-Native"
```

3. **User complaints**
- Formularios no envían
- Navigation "slow"
- Datos no se actualizan

---

### 🚀 Deployment Workflow

```bash
# 1. Test en desarrollo
rails test:integration

# 2. Build & commit
git add .
git commit -m "Feature: X for mobile support"

# 3. Deploy a staging
git push origin feature-branch
heroku deploy:staging

# 4. QA en mobile
# - Test en iOS simulator
# - Test en Android emulator
# - Test en devices reales

# 5. Deploy a producción
git push origin main
heroku deploy:production

# 6. Monitor logs
heroku logs --tail --dyno web
```

--- 

### 📱 Testing en Dispositivos Reales

**iOS:**
```bash
# Abrir en Safari
open http://localhost:3000

# Comparar con app nativa
# Feature > Open in new tab (request User-Agent change)
```

**Android:**
```bash
# Conectar device
adb devices

# Abrir en navegador
adb shell am start -a android.intent.action.VIEW -d "http://localhost:3000"
```

---

### 🔐 Seguridad

#### Checklist:

- [ ] CORS configurado para dominios específicos en prod
- [ ] No logging de passwords/tokens
- [ ] Rate limiting en auth endpoints
- [ ] CSP headers verificados
- [ ] HTTPS enforced (certificate pinning si es posible)
- [ ] No localStorage de datos sensibles

#### Verificar:

```bash
# CORS headers
curl -H "Origin: https://your-app.com" http://localhost:3000

# Security headers
curl -I http://localhost:3000
# Verificar: X-Content-Type-Options, X-Frame-Options, CSP
```

---

### 📈 Escalabilidad

**Cuando crezcas:**

1. **Database optimization**
   - Agregar índices para queries frecuentes
   - Usar `includes()` y `joins()` para N+1 queries

2. **Caching**
   - implementar fragment caching
   - considerr HTTP caching headers

3. **API rate limiting**
   - Usar gem `rack-throttle` si es necesario

4. **Mobile-specific optimizations**
   - Lazy loading de imágenes
   - Pagination en listas largas
   - Background jobs para operaciones lentas

---

### 💡 Mejores Prácticas

#### 1. Tests SIEMPRE

```ruby
test "feature works on mobile" do
  get path, headers: { 'User-Agent' => 'TurboNative/1.0' }
  assert_response :success
end
```

#### 2. Responsive primero

Diseña para 320px de ancho, luego expande.

#### 3. Progressive enhancement

Formularios deben funcionar sin JavaScript:
```erb
<%= form_with(model: @item) do |f| %>
  <!-- Sin data-controller sigue siendo usable -->
<% end %>
```

#### 4. Accessibility

- Labels en formularios (< label for="id">)
- Alt text en imágenes
- Touch targets >= 48px
- Contrast ratio >= 4.5:1

#### 5. Performance

```bash
# Revisar antes de merging
rake hotwire_native:performance_check

# Bundle sizes:
# - CSS < 200KB
# - JS < 100KB
```

---

### 📚 Recursos

1. **Turbo Native Docs:** https://turbo.hotwired.dev/handbook/native-navigation
2. **Stimulus Reference:** https://stimulus.hotwired.dev/reference/targets
3. **Rails & Mobile:** https://guides.rubyonrails.org/mobile.html
4. **Web Standard:** https://web.dev/

---

### 📞 Support & Questions

**Para Hotwire Native:**
- GitHub Discussions: https://github.com/hotwired/turbo-ios
- Basecamp forum: https://www.basecamp.com

**Para tu app:**
- Ver logs: `rails server`
- Debug mobile: Chrome DevTools → Remote debugging
- Monkey patch testing: `test/integration/hotwire_native_test.rb`

---

### 🎓 Learning Path para el Team

**Week 1:**
- Leer HOTWIRE_NATIVE_CHANGELOG.md
- Run `rake hotwire_native:performance_check`
- Test en desarrollo

**Week 2:**
- Compile app nativa (iOS/Android)
- Test en simulators
- Identificar bugs

**Week 3:**
- Fix bugs identificados
- Optimize performance
- Deploy a staging

**Week 4:**
- Final QA
- Deploy to production
- Monitor en vivo

---

## Checklist de Onboarding para Nuevos Devs

- [ ] Clonar repo
- [ ] `bundle install`
- [ ] Leer este documento
- [ ] Revisar HOTWIRE_NATIVE_CHANGELOG.md
- [ ] Run: `rails test:integration`
- [ ] Run: `rails server` y abrir http://localhost:3000
- [ ] Open em DevTools (F12) → Device toggle (iPhone)
- [ ] Revisar `app/views/layouts/application_mobile.html.erb`
- [ ] Revisar `app/controllers/application_controller.rb` concerns
- [ ] Ask questions!

---

**Happy coding! 🚀**

*Last updated: March 18, 2026*
