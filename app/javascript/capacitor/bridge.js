const SESSION_KEY = "juji_session_id"
const LAST_PATH_KEY = "juji_last_path"

function capacitorPlugin(name) {
  return globalThis.Capacitor?.Plugins?.[name]
}

async function setPreference(key, value) {
  const preferences = capacitorPlugin("Preferences")
  if (preferences?.set) {
    await preferences.set({ key, value })
  } else {
    localStorage.setItem(key, value)
  }
}

async function getPreference(key) {
  const preferences = capacitorPlugin("Preferences")
  if (preferences?.get) return (await preferences.get({ key })).value
  return localStorage.getItem(key)
}

async function removePreference(key) {
  const preferences = capacitorPlugin("Preferences")
  if (preferences?.remove) {
    await preferences.remove({ key })
  } else {
    localStorage.removeItem(key)
  }
}

export async function initBridge() {
  const splashScreen = capacitorPlugin("SplashScreen")
  const statusBar = capacitorPlugin("StatusBar")
  const app = capacitorPlugin("App")

  // Hide splash screen after a short delay
  setTimeout(() => splashScreen?.hide?.(), 1500)

  // Set status bar style based on theme
  const theme = document.documentElement.dataset.theme || "light"
  await statusBar?.setStyle?.({ style: theme === "dark" ? "DARK" : "LIGHT" })
  await statusBar?.setBackgroundColor?.({ color: getComputedStyle(document.documentElement).getPropertyValue("--paper").trim() || "#FFFFFF" })

  // Handle Android back button
  app?.addListener?.("backButton", ({ canGoBack }) => {
    if (canGoBack) {
      window.history.back()
    } else {
      app.exitApp?.()
    }
  })

  // Save last visited path before app pauses
  app?.addListener?.("pause", async () => {
    await setPreference(LAST_PATH_KEY, window.location.pathname)
  })

  // On app resume, could refresh data or check connectivity
  app?.addListener?.("resume", async () => {
    const lastPath = await getPreference(LAST_PATH_KEY)
    if (lastPath && lastPath !== window.location.pathname) {
      // Optional: navigate back to last known path
    }
  })
}

export async function saveSession(sessionId) {
  await setPreference(SESSION_KEY, sessionId)
}

export async function getSession() {
  return getPreference(SESSION_KEY)
}

export async function clearSession() {
  await removePreference(SESSION_KEY)
  await removePreference(LAST_PATH_KEY)
}

export async function injectSessionCookie() {
  const sessionId = await getSession()
  if (sessionId) {
    document.cookie = `session_id=${sessionId}; path=/; SameSite=Lax`
  }
}

// Check if running inside Capacitor native shell
export function isNative() {
  return globalThis.Capacitor?.isNativePlatform?.() === true
}
