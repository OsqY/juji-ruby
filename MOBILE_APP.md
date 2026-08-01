# Juji Mobile App — Guía de desarrollo

> Empaquetado con Capacitor. Mismo backend Rails, experiencia nativa.

---

## Requisitos

- **Node.js** 18+ y npm
- **Android Studio** (para compilar APK Android)
- **macOS + Xcode** (solo para compilar iOS en el futuro)
- **JDK** 17+ (incluido con Android Studio)
- **Rails server** corriendo en red local accesible desde el dispositivo

---

## Estructura del proyecto

```
juji-ruby/
├── app/                  # Backend Rails
├── android/              # Proyecto Android generado por Capacitor
├── capacitor.config.ts   # Configuración de Capacitor
├── package.json          # Dependencias Node
└── public/               # Assets estáticos (usados por Capacitor en producción)
```

---

## Instalación rápida

```bash
# 1. Instalar dependencias (ya hecho en este repo)
npm install

# 2. Sincronar cambios de web → Android
npx cap sync android

# 3. Abrir en Android Studio
npx cap open android
```

En Android Studio:
- Seleccionar emulador o dispositivo físico
- Click en **Run** (▶)

---

## Configuración de desarrollo

### Conectar a Rails local

Por defecto, `capacitor.config.ts` apunta a `http://10.0.2.2:3000` (emulador Android).

Para **dispositivo físico**, reemplaza con la IP local de tu máquina:

```typescript
// capacitor.config.ts
server: {
  url: 'http://192.168.1.X:3000',  // Tu IP local
  cleartext: true,
},
```

Luego resincroniza:
```bash
npx cap copy android
```

### Detectar Capacitor desde Rails

El servidor Rails ya detecta el user-agent `Capacitor` y sirve el layout mobile (`application_mobile.html.erb`) automáticamente.

Si necesitas lógica específica en un controller:

```ruby
if hotwire_native_client?
  # Corre dentro del WebView nativo (Capacitor, turbo-ios, etc.)
end
```

---

## Permisos nativos configurados

El `AndroidManifest.xml` ya incluye:

- `INTERNET`
- `CAMERA`
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `POST_NOTIFICATIONS`

En runtime, Capacitor solicitará los permisos cuando un plugin los necesite.

---

## Plugins recomendados para instalar

```bash
# Notificaciones push (Firebase)
npm install @capacitor/push-notifications
npx cap sync android

# Cámara / Galería
npm install @capacitor/camera
npx cap sync android

# Geolocalización
npm install @capacitor/geolocation
npx cap sync android

# Haptics (vibración)
npm install @capacitor/haptics
npx cap sync android

# Share nativo
npm install @capacitor/share
npx cap sync android

# Preferencias (almacenamiento local)
npm install @capacitor/preferences
npx cap sync android

# Estado de red (online/offline)
npm install @capacitor/network
npx cap sync android
```

---

## Deep Linking

La app responde a:
- `https://juji.app/*`
- `juji://*`

Configurado en `AndroidManifest.xml` con `intent-filter`.

Desde Rails, el concern `DeepLinkSupport` ya maneja rutas de invitación y pizarras públicas.

---

## Push Notifications — Backend

### Endpoints disponibles

```
POST   /push_notifications/register   { fcm_token: "..." }
DELETE /push_notifications/unregister
```

### Flujo

1. App (Capacitor) obtiene token FCM vía `@capacitor/push-notifications`
2. App envía token al backend vía `POST /push_notifications/register`
3. Backend guarda `fcm_token` en el modelo `User`
4. Cuando ocurre un evento (alerta, mensaje, solicitud de amistad), el backend usa `PushNotificationService.send_to_user(user, title:, body:)`
5. En producción, `PushNotificationService` debe integrarse con la API de Firebase Cloud Messaging usando la server key del proyecto Firebase.

### Configuración Firebase (pendiente)

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Agregar app Android (`com.juji.app`)
3. Descargar `google-services.json` y colocarlo en `android/app/`
4. Agregar plugin `com.google.gms.google-services` en `android/app/build.gradle`
5. Copiar server key de Firebase y configurarla en Rails (credentials o ENV)

La app no intenta registrar push por defecto. Activa `JUJI_PUSH_NOTIFICATIONS=true`
solo después de configurar `google-services.json` para `com.juji.app` y validar
FCM en un dispositivo; así una compilación sin Firebase no puede cerrar la app.

---

## Compilar APK de release

```bash
# 1. Asegurar que assets estén actualizados
npx cap sync android

# 2. Generar keystore (solo la primera vez)
cd android
keytool -genkey -v -keystore juji-release.keystore -alias juji -keyalg RSA -keysize 2048 -validity 10000

# 3. Configurar signing en app/build.gradle (ver docs de Capacitor)

# 4. Build release APK
./gradlew assembleRelease

# APK resultante:
# android/app/build/outputs/apk/release/app-release.apk
```

---

## Roadmap móvil

| Fase | Estado | Descripción |
|------|--------|-------------|
| 1 | ✅ | Fundación Capacitor + proyecto Android |
| 2 | ⏳ | Splash screen, icono, autenticación persistente |
| 3 | ⏳ | Push notifications, cámara, GPS, haptics |
| 4 | ⏳ | Offline indicator, cache, deep links, performance |
| 5 | ⏳ | iOS + publicación Play Store / App Store |

---

## Documentación relacionada

- `HOTWIRE_NATIVE_CHANGELOG.md` — Historia de la integración server-side
- `HOTWIRE_NATIVE_CHECKLIST.md` — Checklist técnico
- `HOTWIRE_NATIVE_DEPLOYMENT.md` — Guía de deployment
- `HOTWIRE_NATIVE_MAINTENANCE.md` — Mantenimiento
